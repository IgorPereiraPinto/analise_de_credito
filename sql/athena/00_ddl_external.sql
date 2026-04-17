-- ================================================================
-- credito_bba | Athena — Camada RAW: DDL Tabelas Externas
-- Arquivo   : 00_ddl_external.sql
-- Camada    : RAW
-- Objetivo  : Criar o banco no Glue Data Catalog e as tabelas
--             externas que apontam para arquivos Parquet no S3.
--
-- Diferenças em relação ao SQL Server:
--   - Não há PKs nem FKs: a integridade é garantida pelo ETL Python
--   - Os dados residem no S3, não no banco — o Athena só lê
--   - Formato Parquet com compressão Snappy para performance
--   - O AWS Glue Crawler pode substituir este DDL manual
--
-- Pré-requisito: arquivos Parquet no S3 gerados por 04_export.py
--                (com EXPORT_FORMAT=parquet no .env)
--
-- Para ajustar ao seu ambiente: substitua 's3://bucket-credito/'
--   pelo nome real do seu bucket S3.
-- ================================================================

-- Passo 1: Criar o banco no Glue Data Catalog
CREATE DATABASE IF NOT EXISTS credito_ibba;

-- ----------------------------------------------------------------
-- Tabela 1: clientes
-- Dados: s3://bucket-credito/trusted/clientes/
-- ----------------------------------------------------------------
CREATE EXTERNAL TABLE IF NOT EXISTS credito_ibba.clientes (
    cliente_id                 STRING,
    segmento                   STRING,
    porte                      STRING,
    setor                      STRING,
    subsetor                   STRING,
    data_inicio_relacionamento DATE,
    regiao                     STRING,
    status_cliente             STRING
)
STORED AS PARQUET
LOCATION 's3://bucket-credito/trusted/clientes/'
TBLPROPERTIES ('parquet.compress' = 'SNAPPY');

-- ----------------------------------------------------------------
-- Tabela 2: operacoes
-- Dados: s3://bucket-credito/trusted/operacoes/
-- ----------------------------------------------------------------
CREATE EXTERNAL TABLE IF NOT EXISTS credito_ibba.operacoes (
    operacao_id      STRING,
    cliente_id       STRING,
    produto          STRING,
    modalidade       STRING,
    valor_aprovado   DECIMAL(15,2),
    valor_utilizado  DECIMAL(15,2),
    taxa_juros       DECIMAL(8,4),
    prazo_meses      INT,
    data_aprovacao   DATE,
    data_vencimento  DATE,
    garantia_tipo    STRING,
    status_operacao  STRING
)
STORED AS PARQUET
LOCATION 's3://bucket-credito/trusted/operacoes/'
TBLPROPERTIES ('parquet.compress' = 'SNAPPY');

-- ----------------------------------------------------------------
-- Tabela 3: ratings
-- ----------------------------------------------------------------
CREATE EXTERNAL TABLE IF NOT EXISTS credito_ibba.ratings (
    cliente_id       STRING,
    data_referencia  DATE,
    rating_interno   STRING,
    rating_externo   STRING,
    pd_12m           DECIMAL(8,6),
    score_interno    INT,
    observacao       STRING
)
STORED AS PARQUET
LOCATION 's3://bucket-credito/trusted/ratings/'
TBLPROPERTIES ('parquet.compress' = 'SNAPPY');

-- ----------------------------------------------------------------
-- Tabela 4: limites
-- ----------------------------------------------------------------
CREATE EXTERNAL TABLE IF NOT EXISTS credito_ibba.limites (
    cliente_id      STRING,
    tipo_limite     STRING,
    valor_limite    DECIMAL(15,2),
    valor_utilizado DECIMAL(15,2),
    data_aprovacao  DATE,
    data_revisao    DATE,
    aprovador       STRING,
    status_limite   STRING
)
STORED AS PARQUET
LOCATION 's3://bucket-credito/trusted/limites/'
TBLPROPERTIES ('parquet.compress' = 'SNAPPY');

-- ----------------------------------------------------------------
-- Tabela 5: exposicoes
-- ----------------------------------------------------------------
CREATE EXTERNAL TABLE IF NOT EXISTS credito_ibba.exposicoes (
    cliente_id            STRING,
    data_referencia       DATE,
    exposicao_total       DECIMAL(15,2),
    exposicao_garantida   DECIMAL(15,2),
    exposicao_descoberta  DECIMAL(15,2),
    provisao_necessaria   DECIMAL(15,2),
    classificacao_risco   STRING
)
STORED AS PARQUET
LOCATION 's3://bucket-credito/trusted/exposicoes/'
TBLPROPERTIES ('parquet.compress' = 'SNAPPY');

-- ----------------------------------------------------------------
-- Verificação pós-criação
-- ----------------------------------------------------------------
SHOW TABLES IN credito_ibba;
