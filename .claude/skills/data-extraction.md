---
name: data-extraction
description: >
  Especialista em extração de dados de múltiplas fontes: APIs REST e GraphQL, CRM (Salesforce,
  HubSpot), AWS S3, SharePoint, Excel/CSV, Google Analytics 4, SQL Server, Athena e sistemas
  legados. Cobre autenticação (OAuth2, API Key, Basic), paginação, retry, rate limiting e
  rastreabilidade da extração. Use sempre que o usuário precisar conectar a uma fonte de dados,
  extrair via API, ler arquivos do S3, integrar com Salesforce, automatizar ingestão ou iniciar
  um pipeline de dados. Trigger para: "extrai dados da API", "conecta ao Salesforce", "lê do
  S3", "puxa dados do SharePoint", "integra com [sistema]", "ingestão de dados", "pipeline
  de extração", "automatiza a coleta".
---

# Data Extraction — Extração de Dados de Múltiplas Fontes

## Identidade

Especialista em extração confiável, rastreável e reproduzível de dados de qualquer fonte para
alimentar pipelines ETL e Data Lakes. Princípio: sempre salvar o dado bruto (raw/bronze)
antes de qualquer transformação.

---

## Quando Usar

Use esta skill para o estágio de extração de qualquer pipeline de dados. Para transformação
e limpeza, use `etl-data-lake`. Para infraestrutura AWS, use `aws-data-stack`.

---

## Princípios de Extração

```
1. SALVAR RAW: sempre persistir o dado como chegou antes de qualquer transformação
2. LOGAR: data/hora, fonte, quantidade de registros e tamanho
3. RETRY: máximo 3 tentativas com backoff exponencial
4. VALIDAR SCHEMA: colunas esperadas presentes após extração
5. CREDENCIAIS: sempre em variáveis de ambiente — nunca hardcode
6. RASTREABILIDADE: _etl_source, _etl_extracted_at em todo dado extraído
```

---

## 1. APIs REST — Extração Genérica com Retry

```python
import requests
import pandas as pd
import time
import logging
from typing import Optional

logger = logging.getLogger(__name__)

def extract_api_paginated(
    url: str,
    headers: dict,
    params: dict = None,
    page_param: str = 'page',
    page_size_param: str = 'page_size',
    page_size: int = 100,
    data_key: str = 'data',
    max_retries: int = 3,
    backoff_factor: float = 2.0,
    rate_limit_sleep: float = 0.5
) -> pd.DataFrame:
    """
    Extração paginada de API REST com retry e backoff exponencial.

    Args:
        url: endpoint da API
        headers: cabeçalhos (Authorization, Content-Type, etc.)
        params: parâmetros de query string
        data_key: chave do JSON que contém os registros
        max_retries: tentativas em caso de erro
        backoff_factor: fator de espera entre tentativas (segundos * fator^n)
    """
    params = params or {}
    params[page_size_param] = page_size
    results = []
    page = 1

    while True:
        params[page_param] = page

        for attempt in range(max_retries):
            try:
                resp = requests.get(url, headers=headers, params=params, timeout=30)
                resp.raise_for_status()
                break
            except requests.HTTPError as e:
                if resp.status_code == 429:  # Rate limit
                    wait = backoff_factor ** attempt * 60
                    logger.warning(f"Rate limit atingido. Aguardando {wait:.0f}s...")
                    time.sleep(wait)
                elif attempt == max_retries - 1:
                    raise
                else:
                    time.sleep(backoff_factor ** attempt)

        data = resp.json()
        items = data.get(data_key) if data_key else data
        if isinstance(items, dict):
            items = [items]
        if not items:
            break

        results.extend(items)
        logger.info(f"Página {page}: {len(items)} registros extraídos")

        # Para se a página retornou menos que o page_size (última página)
        if len(items) < page_size:
            break
        page += 1
        time.sleep(rate_limit_sleep)

    df = pd.DataFrame(results)
    logger.info(f"[EXTRACT] Total: {len(df):,} registros de {url}")
    return df


def get_oauth2_token(token_url: str, client_id: str,
                      client_secret: str, scope: str = None) -> str:
    """Obtém token OAuth2 client_credentials."""
    payload = {
        'grant_type': 'client_credentials',
        'client_id': client_id,
        'client_secret': client_secret
    }
    if scope:
        payload['scope'] = scope
    resp = requests.post(token_url, data=payload, timeout=30)
    resp.raise_for_status()
    return resp.json()['access_token']
```

---

## 2. Salesforce — SOQL com simple_salesforce

```python
from simple_salesforce import Salesforce, SalesforceLogin
import pandas as pd
import os

def conectar_salesforce() -> Salesforce:
    """Conexão ao Salesforce via variáveis de ambiente."""
    return Salesforce(
        username=os.getenv('SF_USERNAME'),
        password=os.getenv('SF_PASSWORD'),
        security_token=os.getenv('SF_TOKEN'),
        domain=os.getenv('SF_DOMAIN', 'login')  # 'test' para sandbox
    )

def query_salesforce(soql: str) -> pd.DataFrame:
    """Executa SOQL e retorna DataFrame (suporta query_all para >2000 registros)."""
    sf = conectar_salesforce()
    result = sf.query_all(soql)
    df = pd.DataFrame(result['records'])
    if 'attributes' in df.columns:
        df = df.drop(columns=['attributes'])
    return df

# Exemplo de SOQL úteis:
SOQL_OPPORTUNITIES = """
    SELECT Id, Name, Amount, StageName, CloseDate,
           Account.Name, Owner.Name, OwnerId, AccountId,
           Probability, ForecastCategory, CreatedDate
    FROM Opportunity
    WHERE CloseDate >= 2024-01-01
      AND IsDeleted = false
      AND Amount > 0
    ORDER BY CloseDate DESC
"""

SOQL_ACCOUNTS = """
    SELECT Id, Name, Industry, AnnualRevenue, NumberOfEmployees,
           BillingCity, BillingState, OwnerId
    FROM Account
    WHERE IsDeleted = false
"""
```

---

## 3. AWS S3 — Leitura e Escrita

```python
import boto3
import pandas as pd
from io import BytesIO, StringIO
from pathlib import Path
import os

def get_s3_client():
    """Cria cliente S3 usando variáveis de ambiente (sem hardcode)."""
    return boto3.client(
        's3',
        region_name=os.getenv('AWS_DEFAULT_REGION', 'us-east-1')
        # Credenciais via AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY
        # ou via IAM Role (recomendado em produção)
    )

def read_s3_parquet(bucket: str, key: str) -> pd.DataFrame:
    """Lê arquivo Parquet do S3."""
    s3 = get_s3_client()
    obj = s3.get_object(Bucket=bucket, Key=key)
    return pd.read_parquet(BytesIO(obj['Body'].read()))

def read_s3_csv(bucket: str, key: str, sep: str = ';',
                encoding: str = 'utf-8-sig') -> pd.DataFrame:
    """Lê arquivo CSV do S3 com encoding brasileiro."""
    s3 = get_s3_client()
    obj = s3.get_object(Bucket=bucket, Key=key)
    return pd.read_csv(obj['Body'], sep=sep, encoding=encoding)

def write_s3_parquet(df: pd.DataFrame, bucket: str, key: str) -> None:
    """Escreve DataFrame como Parquet no S3 (snappy compression)."""
    s3 = get_s3_client()
    buffer = BytesIO()
    df.to_parquet(buffer, index=False, compression='snappy')
    s3.put_object(Bucket=bucket, Key=key, Body=buffer.getvalue())
    print(f"✅ Escrito: s3://{bucket}/{key} | {len(df):,} linhas")

def list_s3_files(bucket: str, prefix: str,
                  extension: str = '.parquet') -> list:
    """Lista arquivos no S3 com prefixo e extensão."""
    s3 = get_s3_client()
    paginator = s3.get_paginator('list_objects_v2')
    files = []
    for page in paginator.paginate(Bucket=bucket, Prefix=prefix):
        for obj in page.get('Contents', []):
            if obj['Key'].endswith(extension):
                files.append(obj['Key'])
    return files
```

---

## 4. SharePoint — Leitura de Arquivos

```python
from office365.sharepoint.client_context import ClientContext
from office365.runtime.auth.user_credential import UserCredential
import pandas as pd
from io import BytesIO
import os

def read_sharepoint_excel(site_url: str, file_relative_url: str,
                           sheet_name: int = 0) -> pd.DataFrame:
    """
    Lê arquivo Excel do SharePoint via credenciais de usuário.
    file_relative_url: '/sites/MeuSite/Shared Documents/arquivo.xlsx'
    """
    ctx = ClientContext(site_url).with_credentials(
        UserCredential(os.getenv('SP_USERNAME'), os.getenv('SP_PASSWORD'))
    )
    response = (ctx.web
                   .get_file_by_server_relative_url(file_relative_url)
                   .execute_query())
    return pd.read_excel(BytesIO(response.read()), sheet_name=sheet_name)


def list_sharepoint_files(site_url: str, folder_relative_url: str) -> list:
    """Lista arquivos em uma pasta do SharePoint."""
    ctx = ClientContext(site_url).with_credentials(
        UserCredential(os.getenv('SP_USERNAME'), os.getenv('SP_PASSWORD'))
    )
    folder = ctx.web.get_folder_by_server_relative_url(folder_relative_url)
    files  = folder.files.get().execute_query()
    return [f.properties['ServerRelativeUrl'] for f in files]
```

---

## 5. Google Analytics 4 — API de Dados

```python
from google.analytics.data_v1beta import BetaAnalyticsDataClient
from google.analytics.data_v1beta.types import (
    RunReportRequest, DateRange, Metric, Dimension, OrderBy
)
import pandas as pd
import os

def query_ga4(property_id: str, dimensions: list, metrics: list,
              start_date: str, end_date: str = 'today',
              limit: int = 10000) -> pd.DataFrame:
    """
    Extrai dados do Google Analytics 4 via API.
    Requer GOOGLE_APPLICATION_CREDENTIALS apontando para JSON de service account.
    """
    client = BetaAnalyticsDataClient()
    request = RunReportRequest(
        property=f"properties/{property_id}",
        dimensions=[Dimension(name=d) for d in dimensions],
        metrics=[Metric(name=m) for m in metrics],
        date_ranges=[DateRange(start_date=start_date, end_date=end_date)],
        limit=limit
    )
    response = client.run_report(request)

    # Monta DataFrame
    headers = [h.name for h in response.dimension_headers] + \
              [h.name for h in response.metric_headers]
    rows = []
    for row in response.rows:
        rows.append(
            [dv.value for dv in row.dimension_values] +
            [mv.value for mv in row.metric_values]
        )
    return pd.DataFrame(rows, columns=headers)

# Exemplo de uso:
# df_ga4 = query_ga4(
#     property_id='123456789',
#     dimensions=['sessionSource', 'sessionMedium', 'country'],
#     metrics=['sessions', 'conversions', 'totalRevenue'],
#     start_date='2024-01-01'
# )
```

---

## 6. SQL Server / Athena — Extração via Python

```python
import pyodbc
import boto3
import pandas as pd
import time
import os

def read_sql_server(query: str, conn_str: str = None) -> pd.DataFrame:
    """Extrai dados do SQL Server via ODBC."""
    conn_str = conn_str or os.getenv('SQL_SERVER_CONN')
    with pyodbc.connect(conn_str) as conn:
        df = pd.read_sql(query, conn)
    print(f"[SQL Server] {len(df):,} linhas extraídas")
    return df

def query_athena(sql: str, database: str, s3_output: str,
                 region: str = None) -> pd.DataFrame:
    """Executa query no Athena e retorna DataFrame."""
    region  = region or os.getenv('AWS_DEFAULT_REGION', 'us-east-1')
    athena  = boto3.client('athena', region_name=region)
    exec_id = athena.start_query_execution(
        QueryString=sql,
        QueryExecutionContext={'Database': database},
        ResultConfiguration={'OutputLocation': s3_output}
    )['QueryExecutionId']

    # Poll até conclusão
    while True:
        state = athena.get_query_execution(
            QueryExecutionId=exec_id
        )['QueryExecution']['Status']['State']
        if state in ['SUCCEEDED', 'FAILED', 'CANCELLED']:
            break
        time.sleep(2)

    if state != 'SUCCEEDED':
        raise RuntimeError(f"Athena query falhou: {state}")

    result  = athena.get_query_results(QueryExecutionId=exec_id)
    rows    = result['ResultSet']['Rows']
    headers = [c['VarCharValue'] for c in rows[0]['Data']]
    data    = [[col.get('VarCharValue', '') for col in row['Data']]
               for row in rows[1:]]
    return pd.DataFrame(data, columns=headers)
```

---

## 7. Classe Base de Extrator (Padrão)

```python
from datetime import datetime
from abc import ABC, abstractmethod
import logging

class BaseExtractor(ABC):
    """Classe base para todos os extratores do projeto."""

    def __init__(self, source_name: str):
        self.source_name = source_name
        self.run_id      = datetime.now().strftime('%Y%m%d_%H%M%S')
        self.logger      = logging.getLogger(f"extractor.{source_name}")

    @abstractmethod
    def extract(self, **kwargs) -> pd.DataFrame:
        """Executa a extração e retorna DataFrame bruto."""
        ...

    def add_metadata(self, df: pd.DataFrame) -> pd.DataFrame:
        """Adiciona metadados de rastreabilidade obrigatórios."""
        df['_etl_source']       = self.source_name
        df['_etl_run_id']       = self.run_id
        df['_etl_extracted_at'] = datetime.now()
        return df

    def save_bronze(self, df: pd.DataFrame, path: str) -> None:
        """Persiste na camada Bronze antes de qualquer transformação."""
        df.to_parquet(path, index=False, compression='snappy')
        self.logger.info(f"[BRONZE] {len(df):,} linhas salvas em {path}")

    def run(self, **kwargs) -> pd.DataFrame:
        self.logger.info(f"[START] {self.source_name} | run_id={self.run_id}")
        df = self.extract(**kwargs)
        df = self.add_metadata(df)
        self.logger.info(f"[DONE] {len(df):,} linhas extraídas")
        return df
```

## Regras de Qualidade

- Sempre salvar raw/bronze antes de qualquer transformação
- Credenciais via `os.getenv()` — nunca hardcode
- Retry com backoff exponencial em toda chamada HTTP
- Log de início, conclusão e quantidade de registros em toda extração
- Validar colunas esperadas após extração (schema check)
- Nunca modificar dados na etapa de extração — isso é responsabilidade do ETL
