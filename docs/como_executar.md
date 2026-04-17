# Como Executar — credito_bba

Guia passo a passo para rodar o pipeline completo localmente (SQL Server) ou na AWS (Athena).

---

## Pré-requisitos

- Python 3.11+
- Git
- Para SQL Server: SQL Server Developer Edition (gratuito) + SSMS
- Para Athena: conta AWS com acesso a S3, Glue e Athena
- Arquivo `dados_sinteticos_case.xlsx` disponível

---

## Execução local (SQL Server)

### 1. Clonar e configurar o ambiente

```bash
git clone https://github.com/IgorPereiraPinto/credito_bba.git
cd credito_bba
python -m venv .venv
.venv\Scripts\activate          # Windows
pip install -r requirements.txt
cp .env.example .env
```

Edite o `.env` com os dados da sua conexão SQL Server:

```
SQLSERVER_HOST=localhost
SQLSERVER_DATABASE=credito_ibba
SQLSERVER_USER=seu_usuario
SQLSERVER_PASSWORD=sua_senha
```

### 2. Copiar o Excel para data/raw/

```bash
# Coloque dados_sinteticos_case.xlsx em:
data/raw/dados_sinteticos_case.xlsx
```

### 3. Executar o ETL Python

```bash
python python/01_extract.py
python python/02_clean.py
python python/03_validate.py
python python/04_export.py
```

Após a execução, verifique `data/processed/`:

- `clientes.csv`, `operacoes.csv`, `ratings.csv`, `limites.csv`, `exposicoes.csv`
- `validation_report.csv` — relatório de inconsistências encontradas

### 4. Executar o SQL Server (ordem obrigatória)

Abra o SSMS e execute os arquivos na seguinte ordem:

```text
sql/sqlserver/00_ddl.sql          ← cria banco e tabelas
sql/sqlserver/01_raw_insert.sql   ← carrega dados (ajuste o path do BULK INSERT)
sql/sqlserver/02_stage_views.sql  ← cria views STAGE
sql/sqlserver/03_dw_views.sql     ← cria views DW
sql/sqlserver/04_queries_analiticas.sql  ← executa queries do case
sql/sqlserver/05_views_kpi.sql    ← cria camada semântica para Power BI
```

> **Dica:** No arquivo `01_raw_insert.sql`, substitua `C:\caminho\para\data\processed\`
> pelo caminho absoluto real no seu sistema.

### 5. Verificar resultado

Execute no SSMS:

```sql
USE credito_ibba;
SELECT 'clientes'  AS t, COUNT(*) AS n FROM clientes  UNION ALL
SELECT 'operacoes',      COUNT(*)       FROM operacoes UNION ALL
SELECT 'ratings',        COUNT(*)       FROM ratings   UNION ALL
SELECT 'limites',        COUNT(*)       FROM limites   UNION ALL
SELECT 'exposicoes',     COUNT(*)       FROM exposicoes;
```

Resultado esperado com dados sintéticos: `72 / 222 / 864 / 92 / 432`.

---

## Execução na AWS (Athena)

### 1. Configurar credenciais AWS

```bash
cp .env.example .env
# Preencha:
# AWS_ACCESS_KEY_ID=...
# AWS_SECRET_ACCESS_KEY=...
# AWS_REGION=us-east-1
# ATHENA_S3_DATA=s3://seu-bucket/trusted/
# ATHENA_S3_OUTPUT=s3://seu-bucket/athena-results/
```

### 2. Executar o ETL Python com formato Parquet

```bash
# No .env, altere:
# EXPORT_FORMAT=parquet

python python/01_extract.py
python python/02_clean.py
python python/03_validate.py
python python/04_export.py
```

### 3. Upload dos Parquet para S3

```bash
aws s3 cp data/processed/clientes.parquet  s3://seu-bucket/trusted/clientes/
aws s3 cp data/processed/operacoes.parquet s3://seu-bucket/trusted/operacoes/
aws s3 cp data/processed/ratings.parquet   s3://seu-bucket/trusted/ratings/
aws s3 cp data/processed/limites.parquet   s3://seu-bucket/trusted/limites/
aws s3 cp data/processed/exposicoes.parquet s3://seu-bucket/trusted/exposicoes/
```

### 4. Executar o DDL e as views no Athena

No Athena Query Editor, execute na ordem:

```text
sql/athena/00_ddl_external.sql   ← registra tabelas no Glue Catalog
sql/athena/02_stage_views.sql    ← views STAGE
sql/athena/03_dw_views.sql       ← views DW
sql/athena/04_queries_analiticas.sql
sql/athena/05_views_kpi.sql      ← camada semântica para QuickSight
```

---

## Abrir o dashboard HTML

```bash
# Basta abrir no navegador — não precisa de servidor
start dashboards/dashboard_credito_bba.html   # Windows
open  dashboards/dashboard_credito_bba.html   # Mac
```

---

## Resolução de problemas

**Erro: "Arquivo não encontrado"** → Verifique se `DATA_RAW_PATH` no `.env` aponta
para o local correto do Excel.

**BULK INSERT falha no SSMS** → Verifique se o serviço SQL Server tem permissão de
leitura no diretório. Alternativa: use o Import Wizard do SSMS.

**Athena: "TABLE_NOT_FOUND"** → Execute `00_ddl_external.sql` antes das views.
O Glue Crawler pode ser necessário se os arquivos ainda não foram reconhecidos.

**Python: ModuleNotFoundError** → Ative o virtualenv e reinstale:
`pip install -r requirements.txt`
