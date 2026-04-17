---
name: aws-data-stack
description: >
  Especialista em infraestrutura de dados na AWS. Cobre S3 (Data Lake), Glue (ETL e crawlers),
  Athena (SQL serverless), Lambda (automação event-driven), Step Functions (orquestração) e
  DuckDB sobre S3. Use sempre que o usuário mencionar AWS, S3, Glue, Athena, Lambda, boto3,
  pipeline na nuvem, Data Lake AWS, crawler, catálogo de dados, serverless ETL, particionamento
  S3, ou qualquer tarefa de engenharia de dados no ecossistema AWS. Trigger para: "cria um
  Glue Job", "query no Athena", "crawler do S3", "Lambda trigger", "boto3", "Data Lake AWS",
  "pipeline serverless", "S3 particionado".
---

# AWS Data Stack — S3 | Glue | Athena | Lambda

## Identidade

Engenheiro de Dados especializado no ecossistema AWS para dados. Projeta pipelines serverless,
econômicos e escaláveis, seguindo a arquitetura medallion e as boas práticas de governança
de dados na nuvem.

---

## Arquitetura de Referência

```
Fonte de dados (SQL Server, API, S3 externo)
        │
        ▼
[AWS Lambda / Glue Job] ──── trigger (S3 event ou schedule)
        │
        ▼
S3 Bronze  (raw, particionado por data de carga)
        │
        ▼
[AWS Glue Job — ETL Python]
        │
        ▼
S3 Silver  (limpo, particionado por data de negócio)
        │
        ▼
[AWS Glue Job — Aggregation]
        │
        ▼
S3 Gold    (KPIs, star schema)
        │
        ▼
[AWS Athena] ──── queries SQL serverless
        │
        ▼
[Amazon QuickSight / Power BI via Athena]
```

---

## 1. S3 — Organização e Operações

```python
import boto3
import pandas as pd
from io import BytesIO
from pathlib import Path
from datetime import datetime
import os

def get_s3():
    return boto3.client('s3', region_name=os.getenv('AWS_DEFAULT_REGION', 'us-east-1'))

# ── Leitura ───────────────────────────────────────────────────────────
def read_parquet(bucket: str, key: str) -> pd.DataFrame:
    obj = get_s3().get_object(Bucket=bucket, Key=key)
    return pd.read_parquet(BytesIO(obj['Body'].read()))

def read_csv(bucket: str, key: str, sep: str = ';') -> pd.DataFrame:
    obj = get_s3().get_object(Bucket=bucket, Key=key)
    return pd.read_csv(obj['Body'], sep=sep, encoding='utf-8-sig')

# ── Escrita ────────────────────────────────────────────────────────────
def write_parquet(df: pd.DataFrame, bucket: str, key: str) -> None:
    """Salva DataFrame como Parquet no S3 com compressão snappy."""
    buf = BytesIO()
    df.to_parquet(buf, index=False, compression='snappy')
    get_s3().put_object(Bucket=bucket, Key=key, Body=buf.getvalue())
    print(f"✅ s3://{bucket}/{key} | {len(df):,} linhas")

# ── Particionamento padrão ─────────────────────────────────────────────
def build_s3_key(layer: str, entity: str, date: datetime = None,
                  filename: str = None) -> str:
    """
    Gera chave S3 padronizada com particionamento Hive.
    Ex: bronze/vendas/year=2024/month=01/day=15/vendas_20240115_143022.parquet
    """
    date = date or datetime.now()
    ts   = date.strftime('%Y%m%d_%H%M%S')
    fname = filename or f"{entity}_{ts}.parquet"
    return f"{layer}/{entity}/year={date.year}/month={date.month:02d}/day={date.day:02d}/{fname}"

# ── Listagem ────────────────────────────────────────────────────────────
def list_files(bucket: str, prefix: str, ext: str = '.parquet') -> list:
    s3  = get_s3()
    pag = s3.get_paginator('list_objects_v2')
    return [
        obj['Key']
        for page in pag.paginate(Bucket=bucket, Prefix=prefix)
        for obj in page.get('Contents', [])
        if obj['Key'].endswith(ext)
    ]
```

---

## 2. AWS Glue — ETL Job PySpark

```python
# glue_job_vendas_silver.py
import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.sql import functions as F

# ── Inicialização ─────────────────────────────────────────────────────
args = getResolvedOptions(sys.argv, ['JOB_NAME', 'source_bucket', 'target_bucket',
                                      'source_prefix', 'target_prefix'])
sc          = SparkContext()
glueContext = GlueContext(sc)
spark       = glueContext.spark_session
job         = Job(glueContext)
job.init(args['JOB_NAME'], args)

# ── Leitura do Glue Catalog ───────────────────────────────────────────
df = glueContext.create_dynamic_frame.from_catalog(
    database="empresa_bronze",
    table_name="vendas"
).toDF()

# ── Transformações Silver ─────────────────────────────────────────────
df_silver = (df
    .filter(F.col("status").isin(["APROVADO", "PENDENTE"]))
    .withColumn("valor_liquido",
                F.col("valor_bruto") - F.coalesce(F.col("valor_desconto"), F.lit(0)))
    .withColumn("ano",  F.year(F.col("data_venda").cast("date")))
    .withColumn("mes",  F.month(F.col("data_venda").cast("date")))
    .withColumn("_etl_ts",     F.current_timestamp())
    .withColumn("_etl_job",    F.lit(args['JOB_NAME']))
    .dropDuplicates(["id_venda"])
    .filter(F.col("valor_liquido") > 0)
)

# ── Escrita particionada na Silver ────────────────────────────────────
(df_silver.write
    .mode("overwrite")
    .partitionBy("ano", "mes")
    .format("parquet")
    .option("compression", "snappy")
    .save(f"s3://{args['target_bucket']}/{args['target_prefix']}/")
)

job.commit()
```

---

## 3. Glue Crawler — Configuração via boto3

```python
import boto3

glue = boto3.client('glue', region_name='us-east-1')

def criar_crawler(name: str, role_arn: str, database: str,
                   s3_target: str, schedule: str = 'cron(0 6 * * ? *)') -> None:
    """
    Cria crawler do Glue para catalogar tabelas S3.
    schedule: cron expression no horário UTC
    """
    glue.create_crawler(
        Name=name,
        Role=role_arn,
        DatabaseName=database,
        Targets={'S3Targets': [{'Path': s3_target}]},
        Schedule=schedule,
        SchemaChangePolicy={
            'UpdateBehavior': 'UPDATE_IN_DATABASE',
            'DeleteBehavior': 'LOG'
        },
        RecrawlPolicy={'RecrawlBehavior': 'CRAWL_EVERYTHING'},
        Configuration=json.dumps({
            "Version": 1.0,
            "CrawlerOutput": {
                "Partitions": {"AddOrUpdateBehavior": "InheritFromTable"}
            }
        })
    )
    print(f"✅ Crawler '{name}' criado")

def iniciar_crawler(name: str) -> None:
    glue.start_crawler(Name=name)
    print(f"▶️ Crawler '{name}' iniciado")

def aguardar_crawler(name: str, max_wait: int = 600) -> str:
    """Aguarda conclusão do crawler com timeout."""
    import time
    start = time.time()
    while time.time() - start < max_wait:
        state = glue.get_crawler(Name=name)['Crawler']['State']
        if state == 'READY':
            return 'READY'
        time.sleep(15)
    raise TimeoutError(f"Crawler '{name}' não finalizou em {max_wait}s")
```

---

## 4. Athena — DDL e Boas Práticas

```sql
-- ── Criar tabela externa particionada (Parquet) ───────────────────
CREATE EXTERNAL TABLE IF NOT EXISTS empresa_silver.vendas (
    id_venda      STRING        COMMENT 'PK natural da venda',
    id_cliente    STRING,
    id_vendedor   STRING,
    data_venda    DATE,
    valor_bruto   DOUBLE,
    valor_liquido DOUBLE,
    status        STRING,
    canal         STRING,
    _etl_ts       TIMESTAMP     COMMENT 'Timestamp de carga ETL'
)
PARTITIONED BY (ano INT, mes INT)
STORED AS PARQUET
LOCATION 's3://empresa-datalake-prod/silver/vendas/'
TBLPROPERTIES (
    'parquet.compress' = 'SNAPPY',
    'projection.enabled' = 'false'
);

-- ── Reparar partições após nova carga ────────────────────────────
MSCK REPAIR TABLE empresa_silver.vendas;

-- ── Query com filtro de partição PRIMEIRO (obrigatório) ──────────
SELECT
    vendedor,
    SUM(valor_liquido) AS receita,
    COUNT(*) AS pedidos
FROM empresa_silver.vendas
WHERE ano = 2024 AND mes = 1     -- SEMPRE filtrar partição primeiro
  AND status = 'APROVADO'
GROUP BY vendedor
ORDER BY receita DESC
LIMIT 100;

-- ── Otimizações Athena ─────────────────────────────────────────────
-- Use APPROX_COUNT_DISTINCT para cardinalidade alta
APPROX_COUNT_DISTINCT(id_cliente) AS clientes_aprox

-- Prefira Parquet/ORC sobre CSV (10x mais rápido)
-- Use LIMIT em exploração — evite full scan sem filtro de partição
-- EXPLAIN para analisar plano antes de rodar queries pesadas
```

---

## 5. Lambda — Trigger Event-Driven

```python
# lambda_trigger_etl.py
import boto3
import json
from datetime import datetime

glue = boto3.client('glue', region_name='us-east-1')

def lambda_handler(event, context):
    """
    Trigger: novo arquivo no S3 → inicia Glue Job.
    Configurar: S3 Event Notification → SQS → Lambda (ou S3 direto → Lambda)
    """
    for record in event.get('Records', []):
        bucket = record['s3']['bucket']['name']
        key    = record['s3']['object']['key']
        print(f"[TRIGGER] Novo arquivo: s3://{bucket}/{key}")

        # Valida extensão
        if not key.endswith(('.csv', '.parquet', '.json')):
            print(f"[SKIP] Extensão não suportada: {key}")
            continue

        # Identifica camada e entidade pelo prefixo
        parts  = key.split('/')
        layer  = parts[0] if len(parts) > 1 else 'bronze'
        entity = parts[1] if len(parts) > 2 else 'desconhecido'

        # Inicia Glue Job correspondente
        job_name = f"etl-{entity}-{layer}-to-silver"
        try:
            response = glue.start_job_run(
                JobName=job_name,
                Arguments={
                    '--source_bucket': bucket,
                    '--source_key':    key,
                    '--execution_date': datetime.now().strftime('%Y-%m-%d'),
                    '--enable-metrics': ''
                }
            )
            print(f"[OK] Glue Job iniciado: {response['JobRunId']}")
        except glue.exceptions.EntityNotFoundException:
            print(f"[WARN] Glue Job não encontrado: {job_name}")

    return {'statusCode': 200, 'body': 'Trigger processado'}
```

---

## 6. DuckDB — SQL Local sobre S3/Parquet

```python
import duckdb

def query_s3_parquet(s3_path: str, sql: str,
                      aws_region: str = 'us-east-1') -> pd.DataFrame:
    """
    SQL direto em arquivos Parquet no S3 via DuckDB.
    Alternativa econômica ao Athena para análises locais.
    """
    con = duckdb.connect()
    con.execute("INSTALL httpfs; LOAD httpfs;")
    con.execute(f"""
        SET s3_region='{aws_region}';
        SET s3_access_key_id='{os.getenv("AWS_ACCESS_KEY_ID")}';
        SET s3_secret_access_key='{os.getenv("AWS_SECRET_ACCESS_KEY")}';
    """)
    return con.execute(sql.replace('{s3}', f"'{s3_path}'")).df()

# Exemplo:
# df = query_s3_parquet(
#     's3://empresa-datalake-prod/silver/vendas/**/*.parquet',
#     "SELECT regional, SUM(valor_liquido) FROM {s3} GROUP BY 1"
# )
```

---

## IAM Policy Mínima para Analista de Dados

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "S3ReadWrite",
      "Effect": "Allow",
      "Action": ["s3:GetObject", "s3:PutObject", "s3:DeleteObject", "s3:ListBucket"],
      "Resource": [
        "arn:aws:s3:::empresa-datalake-prod",
        "arn:aws:s3:::empresa-datalake-prod/*"
      ]
    },
    {
      "Sid": "AthenaQuery",
      "Effect": "Allow",
      "Action": [
        "athena:StartQueryExecution", "athena:GetQueryResults",
        "athena:GetQueryExecution", "athena:StopQueryExecution"
      ],
      "Resource": "*"
    },
    {
      "Sid": "GlueCatalogRead",
      "Effect": "Allow",
      "Action": [
        "glue:GetDatabase", "glue:GetTable", "glue:GetPartitions",
        "glue:GetTables", "glue:GetDatabases"
      ],
      "Resource": "*"
    }
  ]
}
```

## Regras de Qualidade

- **Sempre filtrar partição primeiro** em Athena (year/month) — evita full scan e custo
- **Parquet + Snappy** como formato padrão — nunca CSV em produção
- **IAM Roles** para serviços AWS em prod — nunca credenciais de usuário em código
- **Particionamento por year/month** em tabelas de fato — nunca por day em tabelas grandes
- **S3 Lifecycle** para mover bronze > 90 dias para S3 Glacier Instant Retrieval
- **Prefixar timestamp** nos arquivos bronze: `entidade_YYYYMMDD_HHMMSS.parquet`
- **MSCK REPAIR TABLE** após toda carga para atualizar partições no catálogo Glue
