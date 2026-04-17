-- ================================================================
-- credito_bba | SQL Server — Camada RAW: Carga de dados
-- Arquivo   : 01_raw_insert.sql
-- Camada    : RAW
-- Objetivo  : Carregar os CSVs gerados pelo Python ETL nas tabelas
--             RAW. Dado bruto, sem transformação.
--
-- Pré-requisito : 00_ddl.sql executado com sucesso
--                 CSVs disponíveis em data/processed/
--
-- Opção A (SSMS): usar o Import Flat File Wizard ou BULK INSERT
-- Opção B (Python): usar pyodbc com pandas.to_sql() — recomendado
--
-- Nota técnica : Queries escritas em SQL Server para prototipagem local.
--               Versão convertida para Amazon Athena disponível em sql/athena/
-- ================================================================

USE credito_ibba;
GO

-- ----------------------------------------------------------------
-- Opção A: BULK INSERT manual (ajuste o path para o seu ambiente)
-- ----------------------------------------------------------------

-- Clientes
BULK INSERT clientes
FROM 'C:\caminho\para\data\processed\clientes.csv'
WITH (
    FIRSTROW        = 2,        -- ignora cabeçalho
    FIELDTERMINATOR = ';',
    ROWTERMINATOR   = '\n',
    CODEPAGE        = '65001',  -- UTF-8
    TABLOCK
);

-- Operacoes
BULK INSERT operacoes
FROM 'C:\caminho\para\data\processed\operacoes.csv'
WITH (
    FIRSTROW        = 2,
    FIELDTERMINATOR = ';',
    ROWTERMINATOR   = '\n',
    CODEPAGE        = '65001',
    TABLOCK
);

-- Ratings
BULK INSERT ratings
FROM 'C:\caminho\para\data\processed\ratings.csv'
WITH (
    FIRSTROW        = 2,
    FIELDTERMINATOR = ';',
    ROWTERMINATOR   = '\n',
    CODEPAGE        = '65001',
    TABLOCK
);

-- Limites
BULK INSERT limites
FROM 'C:\caminho\para\data\processed\limites.csv'
WITH (
    FIRSTROW        = 2,
    FIELDTERMINATOR = ';',
    ROWTERMINATOR   = '\n',
    CODEPAGE        = '65001',
    TABLOCK
);

-- Exposicoes
BULK INSERT exposicoes
FROM 'C:\caminho\para\data\processed\exposicoes.csv'
WITH (
    FIRSTROW        = 2,
    FIELDTERMINATOR = ';',
    ROWTERMINATOR   = '\n',
    CODEPAGE        = '65001',
    TABLOCK
);
GO

-- ----------------------------------------------------------------
-- Verificação pós-carga
-- Resultado esperado (dados sintéticos): 72 / 222 / 864 / 92 / 432
-- Diferenças em relação ao Excel original refletem deduplicação por PK
-- ----------------------------------------------------------------
SELECT 'clientes'   AS tabela, COUNT(*) AS registros FROM clientes  UNION ALL
SELECT 'operacoes',             COUNT(*)              FROM operacoes UNION ALL
SELECT 'ratings',               COUNT(*)              FROM ratings   UNION ALL
SELECT 'limites',               COUNT(*)              FROM limites   UNION ALL
SELECT 'exposicoes',            COUNT(*)              FROM exposicoes;
GO

-- ----------------------------------------------------------------
-- Verificações de qualidade de dados (Parte 1.2 do case)
-- ----------------------------------------------------------------

-- CHECK 1: valor_utilizado <= valor_aprovado
SELECT operacao_id, cliente_id, valor_aprovado, valor_utilizado
FROM operacoes
WHERE valor_utilizado > valor_aprovado;

-- CHECK 2: consistência aritmética da exposição descoberta
SELECT cliente_id, data_referencia,
       exposicao_total,
       exposicao_garantida,
       exposicao_descoberta,
       ROUND(exposicao_total - exposicao_garantida, 2) AS descoberta_calculada,
       ROUND(ABS(exposicao_descoberta - (exposicao_total - exposicao_garantida)), 2) AS diferenca
FROM exposicoes
WHERE ABS(exposicao_descoberta - (exposicao_total - exposicao_garantida)) > 0.01;

-- CHECK 3: pd_12m entre 0 e 1
SELECT cliente_id, data_referencia, pd_12m
FROM ratings
WHERE pd_12m < 0 OR pd_12m > 1 OR pd_12m IS NULL;

-- CHECK 4: data_vencimento >= data_aprovacao
SELECT operacao_id, data_aprovacao, data_vencimento
FROM operacoes
WHERE data_aprovacao >= data_vencimento;

-- CHECK 5: integridade referencial — registros órfãos
SELECT 'ratings sem cliente'    AS verificacao, COUNT(*) AS qtd
FROM ratings r
LEFT JOIN clientes c ON r.cliente_id = c.cliente_id
WHERE c.cliente_id IS NULL
UNION ALL
SELECT 'limites sem cliente',    COUNT(*)
FROM limites l
LEFT JOIN clientes c ON l.cliente_id = c.cliente_id
WHERE c.cliente_id IS NULL
UNION ALL
SELECT 'exposicoes sem cliente', COUNT(*)
FROM exposicoes e
LEFT JOIN clientes c ON e.cliente_id = c.cliente_id
WHERE c.cliente_id IS NULL
UNION ALL
SELECT 'operacoes sem cliente',  COUNT(*)
FROM operacoes o
LEFT JOIN clientes c ON o.cliente_id = c.cliente_id
WHERE c.cliente_id IS NULL;
GO
