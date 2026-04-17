-- ================================================================
-- credito_bba | SQL Server — Camada STAGE: Views de enriquecimento
-- Arquivo   : 02_stage_views.sql
-- Camada    : STAGE
-- Objetivo  : Enriquecer e consolidar os dados brutos da camada RAW.
--             Aqui entram: joins base, campos calculados, flags de
--             qualidade, escala de rating e posição mais recente.
--
-- O que é STAGE:
--   Dado limpo e enriquecido — ainda não é KPI final, mas já tem
--   os campos derivados necessários para a camada DW.
--   As views STAGE são reutilizadas pelas views DW e pelas queries
--   analíticas do case.
--
-- Pré-requisito: 01_raw_insert.sql executado com sucesso
--
-- Nota técnica : Queries escritas em SQL Server para prototipagem local.
--               Versão convertida para Amazon Athena disponível em sql/athena/
-- ================================================================

USE credito_ibba;
GO

-- ----------------------------------------------------------------
-- STAGE 1: vw_stage_escala_rating
-- Converte rating alfanumérico em escala numérica (1-17)
-- Reutilizada em todas as análises temporais de rating
-- ----------------------------------------------------------------
CREATE OR ALTER VIEW vw_stage_escala_rating AS
SELECT *
FROM (VALUES
    ('AAA', 17), ('AA+', 16), ('AA',  15), ('AA-', 14),
    ('A+',  13), ('A',   12), ('A-',  11), ('BBB+',10),
    ('BBB',  9), ('BBB-', 8), ('BB+',  7), ('BB',   6),
    ('BB-',  5), ('B+',   4), ('B',    3), ('B-',   2),
    ('C',    1)
) AS t(rating, nota);
GO

-- ----------------------------------------------------------------
-- STAGE 2: vw_stage_exposicao_recente
-- Última posição de exposição por cliente (data_referencia = MAX)
-- Base para todos os KPIs de snapshot de carteira
-- ----------------------------------------------------------------
CREATE OR ALTER VIEW vw_stage_exposicao_recente AS
WITH ultima_data AS (
    SELECT cliente_id, MAX(data_referencia) AS data_ref_max
    FROM exposicoes
    GROUP BY cliente_id
)
SELECT
    e.cliente_id,
    e.data_referencia,
    e.exposicao_total,
    e.exposicao_garantida,
    e.exposicao_descoberta,
    e.provisao_necessaria,
    e.classificacao_risco,
    ROUND(e.exposicao_descoberta / NULLIF(e.exposicao_total, 0) * 100, 1)
        AS pct_exposicao_descoberta
FROM exposicoes e
INNER JOIN ultima_data ud
    ON e.cliente_id = ud.cliente_id
   AND e.data_referencia = ud.data_ref_max;
GO

-- ----------------------------------------------------------------
-- STAGE 3: vw_stage_rating_recente
-- Último rating por cliente (data_referencia = MAX)
-- Inclui nota numérica para cálculo de score ponderado
-- ----------------------------------------------------------------
CREATE OR ALTER VIEW vw_stage_rating_recente AS
WITH ultimo_rating AS (
    SELECT cliente_id, MAX(data_referencia) AS data_ref_max
    FROM ratings
    GROUP BY cliente_id
)
SELECT
    r.cliente_id,
    r.data_referencia,
    r.rating_interno,
    r.rating_externo,
    r.pd_12m,
    r.score_interno,
    er.nota AS nota_rating
FROM ratings r
INNER JOIN ultimo_rating ur
    ON r.cliente_id = ur.cliente_id
   AND r.data_referencia = ur.data_ref_max
LEFT JOIN vw_stage_escala_rating er
    ON r.rating_interno = er.rating;
GO

-- ----------------------------------------------------------------
-- STAGE 4: vw_stage_limite_consolidado
-- Limite total consolidado por cliente (soma de todos os tipos)
-- Inclui utilização percentual
-- ----------------------------------------------------------------
CREATE OR ALTER VIEW vw_stage_limite_consolidado AS
SELECT
    cliente_id,
    SUM(valor_limite)    AS limite_total,
    SUM(valor_utilizado) AS utilizado_total,
    ROUND(
        SUM(valor_utilizado) / NULLIF(SUM(valor_limite), 0) * 100, 1
    ) AS pct_utilizacao_limite,
    MIN(data_revisao) AS proxima_revisao
FROM limites
WHERE status_limite = 'Ativo'
GROUP BY cliente_id;
GO

-- ----------------------------------------------------------------
-- STAGE 5: vw_stage_operacoes_ativas
-- Operações ativas agregadas por cliente
-- Base para cálculos de utilização e risco de carteira
-- ----------------------------------------------------------------
CREATE OR ALTER VIEW vw_stage_operacoes_ativas AS
SELECT
    cliente_id,
    COUNT(operacao_id)                                          AS qtd_operacoes_ativas,
    SUM(valor_aprovado)                                         AS aprovado_total,
    SUM(valor_utilizado)                                        AS utilizado_total,
    ROUND(SUM(valor_utilizado) / NULLIF(SUM(valor_aprovado), 0) * 100, 1)
                                                                AS pct_utilizacao,
    MIN(data_vencimento)                                        AS proximo_vencimento,
    MAX(taxa_juros)                                             AS maior_taxa,
    ROUND(AVG(taxa_juros), 4)                                   AS taxa_media
FROM operacoes
WHERE status_operacao = 'Ativa'
GROUP BY cliente_id;
GO

-- ----------------------------------------------------------------
-- STAGE 6: vw_stage_cliente_enriquecido
-- Visão 360° do cliente — une todas as 5 tabelas
-- Base principal para as views DW e para o dashboard
-- ----------------------------------------------------------------
CREATE OR ALTER VIEW vw_stage_cliente_enriquecido AS
SELECT
    c.cliente_id,
    c.segmento,
    c.porte,
    c.setor,
    c.subsetor,
    c.regiao,
    c.status_cliente,
    c.data_inicio_relacionamento,
    DATEDIFF(MONTH, c.data_inicio_relacionamento, GETDATE()) AS meses_relacionamento,

    -- Exposição
    er.exposicao_total,
    er.exposicao_garantida,
    er.exposicao_descoberta,
    er.pct_exposicao_descoberta,
    er.provisao_necessaria,
    er.classificacao_risco,

    -- Rating
    rr.rating_interno,
    rr.rating_externo,
    rr.pd_12m,
    rr.score_interno,
    rr.nota_rating,

    -- Limite
    lc.limite_total,
    lc.utilizado_total   AS limite_utilizado,
    lc.pct_utilizacao_limite,
    lc.proxima_revisao,

    -- Operações
    oa.qtd_operacoes_ativas,
    oa.aprovado_total,
    oa.taxa_media,
    oa.proximo_vencimento
FROM clientes c
LEFT JOIN vw_stage_exposicao_recente     er ON c.cliente_id = er.cliente_id
LEFT JOIN vw_stage_rating_recente        rr ON c.cliente_id = rr.cliente_id
LEFT JOIN vw_stage_limite_consolidado    lc ON c.cliente_id = lc.cliente_id
LEFT JOIN vw_stage_operacoes_ativas      oa ON c.cliente_id = oa.cliente_id;
GO
