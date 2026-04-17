-- ================================================================
-- credito_bba | Athena — Camada STAGE: Views de enriquecimento
-- Arquivo   : 02_stage_views.sql
-- Camada    : STAGE
-- Objetivo  : Equivalente ao sql/sqlserver/02_stage_views.sql,
--             adaptado para sintaxe Athena (Presto/Trino).
--
-- Diferenças de sintaxe em relação ao SQL Server:
--   FORMAT(date, 'yyyy-MM')  →  DATE_FORMAT(date, '%Y-%m')
--   GETDATE()                →  CURRENT_DATE
--   DATEDIFF(MONTH,...)      →  DATE_DIFF('month', date1, date2)
--   STDEV()                  →  STDDEV()
--   CREATE OR ALTER VIEW     →  CREATE OR REPLACE VIEW
--
-- No Athena, views são armazenadas no Glue Data Catalog.
--
-- Nota técnica : Script convertido a partir da versão SQL Server (sql/sqlserver/).
--               Sintaxe adaptada para Athena/Presto — lógica analítica equivalente.
-- ================================================================

-- ----------------------------------------------------------------
-- STAGE 1: escala de rating — CTE inline (Athena não suporta views
--           com VALUES, então usamos UNION ALL ou tabela auxiliar)
-- ----------------------------------------------------------------
CREATE OR REPLACE VIEW credito_ibba.vw_stage_escala_rating AS
SELECT 'AAA' AS rating, 17 AS nota  UNION ALL SELECT 'AA+', 16
UNION ALL SELECT 'AA',  15          UNION ALL SELECT 'AA-', 14
UNION ALL SELECT 'A+',  13          UNION ALL SELECT 'A',   12
UNION ALL SELECT 'A-',  11          UNION ALL SELECT 'BBB+',10
UNION ALL SELECT 'BBB',  9          UNION ALL SELECT 'BBB-', 8
UNION ALL SELECT 'BB+',  7          UNION ALL SELECT 'BB',   6
UNION ALL SELECT 'BB-',  5          UNION ALL SELECT 'B+',   4
UNION ALL SELECT 'B',    3          UNION ALL SELECT 'B-',   2
UNION ALL SELECT 'C',    1;

-- ----------------------------------------------------------------
-- STAGE 2: última exposição por cliente
-- classificacao_risco e provisao_necessaria derivados aqui (STAGE),
-- não armazenados em RAW — mantém RAW fiel à fonte.
-- ----------------------------------------------------------------
CREATE OR REPLACE VIEW credito_ibba.vw_stage_exposicao_recente AS
WITH ultima_data AS (
    SELECT cliente_id, MAX(data_referencia) AS data_ref_max
    FROM credito_ibba.exposicoes
    GROUP BY cliente_id
),
ultimo_score AS (
    SELECT r.cliente_id, r.score_interno
    FROM credito_ibba.ratings r
    INNER JOIN (
        SELECT cliente_id, MAX(data_referencia) AS data_ref_max
        FROM credito_ibba.ratings
        GROUP BY cliente_id
    ) ur ON r.cliente_id = ur.cliente_id
         AND r.data_referencia = ur.data_ref_max
)
SELECT
    e.cliente_id,
    e.data_referencia,
    e.exposicao_total,
    e.exposicao_garantida,
    e.exposicao_descoberta,
    ROUND(e.exposicao_descoberta / NULLIF(e.exposicao_total, 0) * 100, 1)
        AS pct_exposicao_descoberta,
    CASE
        WHEN s.score_interno >= 850 THEN 'AA'
        WHEN s.score_interno >= 750 THEN 'A'
        WHEN s.score_interno >= 650 THEN 'BBB'
        WHEN s.score_interno >= 550 THEN 'BB'
        WHEN s.score_interno >= 450 THEN 'B'
        ELSE                             'C'
    END AS classificacao_risco,
    ROUND(e.exposicao_total * CASE
        WHEN s.score_interno >= 850 THEN 0.000
        WHEN s.score_interno >= 750 THEN 0.005
        WHEN s.score_interno >= 650 THEN 0.010
        WHEN s.score_interno >= 550 THEN 0.030
        WHEN s.score_interno >= 450 THEN 0.100
        ELSE                             0.300
    END, 2) AS provisao_necessaria
FROM credito_ibba.exposicoes e
INNER JOIN ultima_data ud
    ON e.cliente_id = ud.cliente_id
   AND e.data_referencia = ud.data_ref_max
LEFT JOIN ultimo_score s
    ON e.cliente_id = s.cliente_id;

-- ----------------------------------------------------------------
-- STAGE 3: último rating por cliente
-- ----------------------------------------------------------------
CREATE OR REPLACE VIEW credito_ibba.vw_stage_rating_recente AS
WITH ultimo_rating AS (
    SELECT cliente_id, MAX(data_referencia) AS data_ref_max
    FROM credito_ibba.ratings
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
FROM credito_ibba.ratings r
INNER JOIN ultimo_rating ur
    ON r.cliente_id = ur.cliente_id
   AND r.data_referencia = ur.data_ref_max
LEFT JOIN credito_ibba.vw_stage_escala_rating er
    ON r.rating_interno = er.rating;

-- ----------------------------------------------------------------
-- STAGE 4: limite consolidado por cliente
-- ----------------------------------------------------------------
CREATE OR REPLACE VIEW credito_ibba.vw_stage_limite_consolidado AS
SELECT
    cliente_id,
    SUM(valor_limite)    AS limite_total,
    SUM(valor_utilizado) AS utilizado_total,
    ROUND(
        SUM(valor_utilizado) / NULLIF(SUM(valor_limite), 0) * 100, 1
    ) AS pct_utilizacao_limite,
    MIN(data_revisao) AS proxima_revisao
FROM credito_ibba.limites
WHERE status_limite = 'Ativo'
GROUP BY cliente_id;

-- ----------------------------------------------------------------
-- STAGE 5: operações ativas por cliente
-- ----------------------------------------------------------------
CREATE OR REPLACE VIEW credito_ibba.vw_stage_operacoes_ativas AS
SELECT
    cliente_id,
    COUNT(operacao_id)                                          AS qtd_operacoes_ativas,
    SUM(valor_aprovado)                                         AS aprovado_total,
    SUM(valor_utilizado)                                        AS utilizado_total,
    ROUND(SUM(valor_utilizado) / NULLIF(SUM(valor_aprovado), 0) * 100, 1)
                                                                AS pct_utilizacao,
    MIN(data_vencimento)                                        AS proximo_vencimento,
    ROUND(AVG(taxa_juros), 4)                                   AS taxa_media
FROM credito_ibba.operacoes
WHERE status_operacao = 'Ativa'
GROUP BY cliente_id;

-- ----------------------------------------------------------------
-- STAGE 6: visão 360° do cliente
-- Nota: DATE_DIFF em vez de DATEDIFF; CURRENT_DATE em vez de GETDATE()
-- ----------------------------------------------------------------
CREATE OR REPLACE VIEW credito_ibba.vw_stage_cliente_enriquecido AS
SELECT
    c.cliente_id,
    c.segmento,
    c.porte,
    c.setor,
    c.subsetor,
    c.regiao,
    c.status_cliente,
    c.data_inicio_relacionamento,
    DATE_DIFF('month', c.data_inicio_relacionamento, CURRENT_DATE) AS meses_relacionamento,

    er.exposicao_total,
    er.exposicao_garantida,
    er.exposicao_descoberta,
    er.pct_exposicao_descoberta,
    er.provisao_necessaria,
    er.classificacao_risco,

    rr.rating_interno,
    rr.rating_externo,
    rr.pd_12m,
    rr.score_interno,
    rr.nota_rating,

    lc.limite_total,
    lc.utilizado_total   AS limite_utilizado,
    lc.pct_utilizacao_limite,

    oa.qtd_operacoes_ativas,
    oa.aprovado_total,
    oa.taxa_media,
    oa.proximo_vencimento
FROM credito_ibba.clientes c
LEFT JOIN credito_ibba.vw_stage_exposicao_recente  er ON c.cliente_id = er.cliente_id
LEFT JOIN credito_ibba.vw_stage_rating_recente     rr ON c.cliente_id = rr.cliente_id
LEFT JOIN credito_ibba.vw_stage_limite_consolidado lc ON c.cliente_id = lc.cliente_id
LEFT JOIN credito_ibba.vw_stage_operacoes_ativas   oa ON c.cliente_id = oa.cliente_id;
