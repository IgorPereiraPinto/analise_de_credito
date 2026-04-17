-- ================================================================
-- credito_bba | SQL Server — Camada RAW: DDL
-- Arquivo   : 00_ddl.sql
-- Camada    : RAW
-- Objetivo  : Criar o banco de dados, todas as tabelas e índices
--             que receberão os dados brutos exportados pelo ETL Python.
--
-- O que é RAW:
--   Dado bruto, fiel à fonte. Nenhuma transformação de negócio aqui.
--   A integridade referencial (FK) é declarada porque o SQL Server
--   permite — diferente do Athena, onde não existem FKs nativas.
--
-- Executar antes de: 01_raw_insert.sql
-- ================================================================

CREATE DATABASE credito_ibba;
GO

USE credito_ibba;
GO

-- ----------------------------------------------------------------
-- Tabela 1: clientes — cadastro base de clientes corporativos
-- PK: cliente_id
-- ----------------------------------------------------------------
CREATE TABLE clientes (
    cliente_id                 VARCHAR(10)  NOT NULL,
    segmento                   VARCHAR(20),
    porte                      VARCHAR(10),
    setor                      VARCHAR(30),
    subsetor                   VARCHAR(50),
    data_inicio_relacionamento DATE,
    regiao                     VARCHAR(15),
    status_cliente             VARCHAR(10),
    CONSTRAINT pk_clientes PRIMARY KEY (cliente_id)
);

-- ----------------------------------------------------------------
-- Tabela 2: operacoes — operações de crédito por cliente
-- PK: operacao_id | FK: cliente_id → clientes
-- ----------------------------------------------------------------
CREATE TABLE operacoes (
    operacao_id      VARCHAR(20)   NOT NULL,
    cliente_id       VARCHAR(10)   NOT NULL,
    produto          VARCHAR(30),
    modalidade       VARCHAR(30),
    valor_aprovado   DECIMAL(15,2),
    valor_utilizado  DECIMAL(15,2),
    taxa_juros       DECIMAL(8,4),
    prazo_meses      INT,
    data_aprovacao   DATE,
    data_vencimento  DATE,
    garantia_tipo    VARCHAR(30),
    status_operacao  VARCHAR(15),
    CONSTRAINT pk_operacoes PRIMARY KEY (operacao_id),
    CONSTRAINT fk_operacoes_clientes FOREIGN KEY (cliente_id)
        REFERENCES clientes (cliente_id)
);

-- ----------------------------------------------------------------
-- Tabela 3: ratings — histórico mensal de rating por cliente
-- PK: (cliente_id, data_referencia)
-- ----------------------------------------------------------------
CREATE TABLE ratings (
    cliente_id       VARCHAR(10)   NOT NULL,
    data_referencia  DATE          NOT NULL,
    rating_interno   VARCHAR(5),
    rating_externo   VARCHAR(5),
    pd_12m           DECIMAL(8,6),
    score_interno    INT,
    observacao       VARCHAR(150),
    CONSTRAINT pk_ratings PRIMARY KEY (cliente_id, data_referencia),
    CONSTRAINT fk_ratings_clientes FOREIGN KEY (cliente_id)
        REFERENCES clientes (cliente_id)
);

-- ----------------------------------------------------------------
-- Tabela 4: limites — limites de crédito aprovados por tipo
-- PK: (cliente_id, tipo_limite)
-- ----------------------------------------------------------------
CREATE TABLE limites (
    cliente_id      VARCHAR(10)   NOT NULL,
    tipo_limite     VARCHAR(20)   NOT NULL,
    valor_limite    DECIMAL(15,2),
    valor_utilizado DECIMAL(15,2),
    data_aprovacao  DATE,
    data_revisao    DATE,
    aprovador       VARCHAR(60),
    status_limite   VARCHAR(10),
    CONSTRAINT pk_limites PRIMARY KEY (cliente_id, tipo_limite),
    CONSTRAINT fk_limites_clientes FOREIGN KEY (cliente_id)
        REFERENCES clientes (cliente_id)
);

-- ----------------------------------------------------------------
-- Tabela 5: exposicoes — posição consolidada mensal por cliente
-- PK: (cliente_id, data_referencia)
-- Nota: provisao_necessaria e classificacao_risco foram adicionados
--       para suportar os KPIs da camada DW sem joins adicionais.
-- ----------------------------------------------------------------
CREATE TABLE exposicoes (
    cliente_id            VARCHAR(10)   NOT NULL,
    data_referencia       DATE          NOT NULL,
    exposicao_total       DECIMAL(15,2),
    exposicao_garantida   DECIMAL(15,2),
    exposicao_descoberta  DECIMAL(15,2),
    provisao_necessaria   DECIMAL(15,2),
    classificacao_risco   VARCHAR(2),
    CONSTRAINT pk_exposicoes PRIMARY KEY (cliente_id, data_referencia),
    CONSTRAINT fk_exposicoes_clientes FOREIGN KEY (cliente_id)
        REFERENCES clientes (cliente_id)
);
GO

-- ----------------------------------------------------------------
-- Índices de suporte para performance analítica
-- ----------------------------------------------------------------
CREATE INDEX ix_operacoes_status   ON operacoes  (status_operacao);
CREATE INDEX ix_ratings_data       ON ratings    (data_referencia);
CREATE INDEX ix_exposicoes_data    ON exposicoes (data_referencia);
CREATE INDEX ix_clientes_segmento  ON clientes   (segmento);
CREATE INDEX ix_clientes_subsetor  ON clientes   (subsetor);
GO

-- ----------------------------------------------------------------
-- Verificação pós-criação
-- ----------------------------------------------------------------
SELECT TABLE_NAME AS tabela
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME;
GO
