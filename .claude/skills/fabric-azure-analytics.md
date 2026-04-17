---
name: fabric-azure-analytics
description: >
  Especialista em arquitetura analítica e operação em Microsoft Fabric e Azure. Cobre Lakehouse,
  Warehouse, Data Factory, Synapse, Direct Lake, Delta Tables, integração com Power BI e
  comparação com AWS. Use sempre que o usuário pedir arquitetura analítica no ecossistema
  Microsoft, comparação entre Fabric/Azure/AWS, decisão entre Lakehouse vs Warehouse,
  configuração de Direct Lake, pipeline no Data Factory, ou qualquer tarefa de engenharia
  de dados e BI na plataforma Microsoft. Trigger para: "arquitetura no Fabric", "Lakehouse
  vs Warehouse", "Direct Lake", "Azure Data Factory", "Synapse", "Power BI com Fabric",
  "Delta Lake no Fabric", "One Lake", "medallion no Fabric".
---

# Fabric & Azure Analytics — Microsoft Fabric e Azure

## Identidade

Especialista em arquitetura analítica no ecossistema Microsoft, conectando ingestão,
armazenamento, transformação e consumo analítico. Propõe soluções viáveis, sustentáveis e
não superdimensionadas, sempre começando pelo caso de uso de negócio.

---

## Quando Usar

Use esta skill para arquitetura e implementação no Microsoft Fabric (Lakehouse, Warehouse,
Data Factory, Synapse, Direct Lake) e Azure. Skill irmã: `aws-data-stack` para ecossistema
AWS. Skill irmã: `bi-dashboards-powerbi` para Power BI e DAX.

---

## Como Atuar

1. Começar pelo caso de uso de negócio — qual pergunta precisa ser respondida?
2. Diferenciar ingestão, armazenamento, transformação e consumo
3. Indicar o papel de cada serviço na arquitetura proposta
4. Propor solução mínima viável — não superdimensionar
5. Considerar governança, custo, performance e manutenção
6. Explicar trade-offs entre Fabric, Azure e AWS quando solicitado

---

## Entradas Esperadas

Objetivo do projeto, fontes de dados, frequência de atualização, volume de dados, stack
disponível (licenças, permissões), restrições técnicas, usuário final e necessidade de
integração com sistemas existentes.

---

## Formato de Saída Padrão

```
1. CENÁRIO ATUAL (fontes, stack, dores)
2. ARQUITETURA SUGERIDA (diagrama em texto + justificativa)
3. PAPEL DE CADA SERVIÇO (o que cada componente faz)
4. FLUXO PONTA A PONTA (ingestão → transform → consumo)
5. BOAS PRÁTICAS (governança, naming, particionamento)
6. CUSTOS E RISCOS (CapEx/OpEx, pontos de atenção)
7. PRÓXIMOS PASSOS (sequência de implementação)
```

---

## Arquitetura Medallion no Microsoft Fabric

```
OneLake (armazenamento unificado)
│
├── Bronze (Raw Zone)
│   └── Lakehouse Bronze
│       ├── Tables/  → Delta Tables particionadas
│       └── Files/   → raw original (CSV, JSON, Parquet)
│
├── Silver (Trusted Zone)
│   └── Lakehouse Silver
│       └── Tables/  → Delta Tables limpas, tipadas, deduplicadas
│
└── Gold (Serving Zone)
    ├── Lakehouse Gold → análises ad hoc, ML, ciência de dados
    └── Warehouse Gold → SQL endpoint para Power BI Direct Lake
        └── Semantic Model (Direct Lake) → Power BI Service
```

---

## Quando Usar Lakehouse vs Warehouse

| Critério | Lakehouse | Warehouse |
|---|---|---|
| Formato de armazenamento | Delta Tables (Parquet) | SQL tables gerenciadas |
| Interface principal | Spark (PySpark/Scala) + SQL | T-SQL padrão |
| Ideal para | Data science, ETL, ML, exploração | BI, relatórios, Power BI |
| Direct Lake | Suportado | Suportado |
| Custo | Menor (armazenamento OneLake) | Maior (compute SQL) |
| Performance SQL | Boa (endpoint SQL automático) | Excelente (otimizado para T-SQL) |
| Escolha recomendada | Default para engenharia de dados | Quando o time é SQL-first / BI-first |

**Regra prática:** Lakehouse para quem processa dados. Warehouse para quem consulta dados.

---

## Direct Lake — Configuração e Limites

```
O QUE É:
  Direct Lake lê dados diretamente do OneLake (Delta Tables) sem importar.
  Performance igual ao Import Mode (VertiPaq por baixo).
  Atualização: instantânea — sem refresh agendado necessário.

QUANDO USAR:
  ✅ Tabelas grandes no Lakehouse/Warehouse (sem limite de refresh do SPICE)
  ✅ Dados que precisam de atualização frequente (D-0)
  ✅ Redução de custo: sem dados duplicados no Power BI Premium

LIMITAÇÕES (importante):
  ❌ Sem Calculated Columns no Direct Lake
  ❌ Sem Calculated Tables no Direct Lake
  ❌ Se o modelo depende muito de colunas calculadas → usar Import Mode ainda
  ❌ Requer licença Fabric F SKU ou Power BI Premium P SKU

CONFIGURAÇÃO:
  1. Criar Lakehouse ou Warehouse no Fabric workspace
  2. Publicar semantic model apontando para tabelas do Lakehouse
  3. Selecionar "Direct Lake" no modo de conexão
  4. Validar no Power BI Service: Storage Mode → Direct Lake
```

---

## Azure Data Factory — Padrões de Pipeline

```
ESTRUTURA DE PIPELINE RECOMENDADA:

Pipeline Master (orquestrador)
├── Activity: Get Metadata (lista arquivos no S3/Blob)
├── ForEach: itera sobre cada arquivo
│   ├── Activity: Copy Data (Bronze → Silver)
│   │   ├── Source: CSV/Parquet em Blob Storage / S3
│   │   └── Sink: Delta Table no Lakehouse
│   ├── Activity: Notebook (transformação PySpark)
│   └── Activity: Set Variable (log de status)
├── Activity: Stored Procedure (executa proc de validação)
└── Activity: Send Email / Teams (notificação de conclusão)

TRIGGERS RECOMENDADOS:
  Tumbling Window: para reprocessamento incremental com janela de tempo
  Schedule:        para pipelines diários/horários simples
  Event-based:     quando novo arquivo chega no Blob/ADLS

BOAS PRÁTICAS ADF:
  ✅ Usar Linked Services com Key Vault (sem credenciais hardcoded)
  ✅ Parametrizar pipelines — evitar pipeline duplicado por ambiente
  ✅ Ativar logs no Azure Monitor + Log Analytics
  ✅ Usar Integration Runtime Self-hosted para fontes on-premise (SQL Server)
```

---

## PySpark no Fabric — Padrões

```python
from pyspark.sql import SparkSession
from pyspark.sql import functions as F
from delta.tables import DeltaTable

spark = SparkSession.builder.appName("ETL-Silver").getOrCreate()

# Leitura da camada Bronze (Delta Table no Lakehouse)
df_raw = spark.read.format("delta").load("abfss://bronze@onelake.dfs.fabric.microsoft.com/lakehouse/Tables/vendas_raw")

# Transformações Silver
df_clean = (df_raw
    .filter(F.col("status") != "CANCELADO")
    .withColumn("valor_liquido", F.col("valor_bruto") - F.col("valor_desconto"))
    .withColumn("ano",  F.year("data_venda"))
    .withColumn("mes",  F.month("data_venda"))
    .withColumn("_etl_ts", F.current_timestamp())
    .dropDuplicates(["id_venda"])
)

# Upsert (Merge) na camada Silver — evitar full overwrite
silver_path = "abfss://silver@onelake.dfs.fabric.microsoft.com/lakehouse/Tables/vendas_clean"

if DeltaTable.isDeltaTable(spark, silver_path):
    delta_table = DeltaTable.forPath(spark, silver_path)
    (delta_table.alias("old")
        .merge(df_clean.alias("new"), "old.id_venda = new.id_venda")
        .whenMatchedUpdateAll()
        .whenNotMatchedInsertAll()
        .execute())
else:
    df_clean.write.format("delta").partitionBy("ano", "mes").save(silver_path)

# Otimização da tabela Delta (executar após carga)
spark.sql(f"OPTIMIZE delta.`{silver_path}` ZORDER BY (id_cliente, data_venda)")
```

---

## Comparativo Microsoft Fabric vs AWS

| Componente | Microsoft Fabric | Equivalente AWS |
|---|---|---|
| Armazenamento unificado | OneLake | S3 |
| Processamento Spark | Fabric Spark | EMR / Glue (Spark) |
| ETL / Pipeline | Data Factory | AWS Glue / Step Functions |
| Data Warehouse SQL | Fabric Warehouse | Redshift |
| Lakehouse | Fabric Lakehouse | Glue Data Catalog + S3 |
| BI / Dashboards | Power BI (Direct Lake) | QuickSight |
| Delta Tables | Delta Lake nativo | Glue + Delta Lake |
| Governança | Microsoft Purview | AWS Lake Formation |
| Serverless SQL | SQL Analytics Endpoint | Athena |

---

## Regras de Qualidade

- Sempre começar pelo caso de uso — não propor arquitetura sem entender o problema
- Diferenciar Lakehouse (Spark-first) de Warehouse (SQL-first) antes de recomendar
- Direct Lake tem limitações reais — alertar sobre calculated columns/tables
- Nunca hardcodar credenciais — usar Key Vault no ADF e variáveis de ambiente
- Nomear recursos com padrão: `lh-bronze-prod`, `wh-gold-prod`, `adf-pipeline-vendas`
- Particionamento por ano/mes em todas as Delta Tables de fato
- Upsert (merge) é preferível a full overwrite em tabelas grandes

## Observações

Para Power BI e DAX, use `bi-dashboards-powerbi`.
Para AWS (S3, Glue, Athena, Lambda), use `aws-data-stack`.
Microsoft Fabric e AWS podem coexistir: Fabric para o ecossistema Microsoft/Power BI,
AWS para pipelines Python e storage S3.
