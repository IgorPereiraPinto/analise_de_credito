-- ================================================================
-- credito_bba | Athena — Camada DW: Views analíticas e KPIs
-- Arquivo   : 03_dw_views.sql
-- Camada    : DW (Gold)
-- Objetivo  : Equivalente a sql/sqlserver/03_dw_views.sql,
--             adaptado para sintaxe Athena.
-- ================================================================

-- ----------------------------------------------------------------
-- DW 1: KPIs de subsetor com flag regulatório
-- ----------------------------------------------------------------
CREATE OR REPLACE VIEW credito_ibba.vw_kpi_por_subsetor AS
WITH total_portfolio AS (
    SELECT SUM(exposicao_total) AS total
    FROM credito_ibba.vw_stage_exposicao_recente
)
SELECT
    c.subsetor,
    c.setor,
    COUNT(DISTINCT c.cliente_id)                               AS qtd_clientes,
    ROUND(SUM(er.exposicao_total) / 1e6, 2)                   AS exposicao_total_MM,
    ROUND(AVG(er.exposicao_total) / 1e6, 2)                   AS exposicao_media_MM,
    ROUND(
        SUM(er.exposicao_descoberta) / NULLIF(SUM(er.exposicao_total), 0) * 100, 1
    )                                                          AS pct_descoberta,
    ROUND(SUM(er.exposicao_total) / NULLIF(tp.total, 0) * 100, 2)
                                                               AS pct_concentracao,
    CASE
        WHEN SUM(er.exposicao_total) / NULLIF(tp.total, 0) > 0.15 THEN 'LIMITE_REGULATORIO'
        WHEN SUM(er.exposicao_total) / NULLIF(tp.total, 0) > 0.10 THEN 'MONITORAMENTO'
        ELSE 'OK'
    END                                                        AS status_concentracao
FROM credito_ibba.clientes c
INNER JOIN credito_ibba.vw_stage_exposicao_recente er ON c.cliente_id = er.cliente_id
CROSS JOIN total_portfolio tp
WHERE c.status_cliente = 'Ativo'
GROUP BY c.subsetor, c.setor, tp.total;

-- ----------------------------------------------------------------
-- DW 2: Evolução de rating por segmento
-- Nota: DATE_FORMAT em vez de FORMAT
-- ----------------------------------------------------------------
CREATE OR REPLACE VIEW credito_ibba.vw_evolucao_rating_segmento AS
WITH rating_mensal AS (
    SELECT
        c.segmento,
        DATE_FORMAT(r.data_referencia, '%Y-%m')               AS ano_mes,
        r.data_referencia,
        ROUND(AVG(CAST(er.nota AS DOUBLE)), 2)                AS nota_media,
        ROUND(AVG(CAST(r.score_interno AS DOUBLE)), 0)        AS score_medio
    FROM credito_ibba.ratings r
    INNER JOIN credito_ibba.clientes c
        ON r.cliente_id = c.cliente_id
    INNER JOIN credito_ibba.vw_stage_escala_rating er
        ON r.rating_interno = er.rating
    GROUP BY
        c.segmento,
        DATE_FORMAT(r.data_referencia, '%Y-%m'),
        r.data_referencia
)
SELECT
    segmento,
    ano_mes,
    nota_media,
    score_medio,
    LAG(nota_media) OVER (PARTITION BY segmento ORDER BY data_referencia)
        AS nota_mes_anterior,
    ROUND(
        (nota_media - LAG(nota_media) OVER (PARTITION BY segmento ORDER BY data_referencia))
        / NULLIF(LAG(nota_media) OVER (PARTITION BY segmento ORDER BY data_referencia), 0) * 100
    , 2)                                                       AS variacao_pct_mom,
    RANK() OVER (PARTITION BY ano_mes ORDER BY nota_media DESC)
        AS ranking_segmento_mes
FROM rating_mensal;

-- ----------------------------------------------------------------
-- DW 3: Matriz de risco individual
-- Nota: DATE_ADD em vez de DATEADD
-- ----------------------------------------------------------------
CREATE OR REPLACE VIEW credito_ibba.vw_matriz_risco AS
WITH deterioracao_rating AS (
    SELECT DISTINCT r1.cliente_id
    FROM credito_ibba.ratings r1
    INNER JOIN credito_ibba.ratings r2
        ON r1.cliente_id = r2.cliente_id
       AND r2.data_referencia = DATE_ADD('month', -1, r1.data_referencia)
    INNER JOIN credito_ibba.ratings r3
        ON r1.cliente_id = r3.cliente_id
       AND r3.data_referencia = DATE_ADD('month', -2, r1.data_referencia)
    INNER JOIN credito_ibba.vw_stage_escala_rating e1 ON r1.rating_interno = e1.rating
    INNER JOIN credito_ibba.vw_stage_escala_rating e2 ON r2.rating_interno = e2.rating
    INNER JOIN credito_ibba.vw_stage_escala_rating e3 ON r3.rating_interno = e3.rating
    WHERE e1.nota < e2.nota AND e2.nota < e3.nota
)
SELECT
    ce.cliente_id,
    ce.segmento,
    ce.subsetor,
    ce.rating_interno,
    ce.score_interno,
    ce.pd_12m,
    ce.pct_utilizacao_limite,
    ce.pct_exposicao_descoberta,
    ce.exposicao_total,
    CASE WHEN dr.cliente_id IS NOT NULL THEN 1 ELSE 0 END AS flag_deterioracao_rating,
    CASE WHEN ce.pct_utilizacao_limite > 80             THEN 1 ELSE 0 END AS flag_utilizacao_alta,
    CASE WHEN ce.pct_exposicao_descoberta > 30          THEN 1 ELSE 0 END AS flag_descoberta_alta,
    CASE
        WHEN (CASE WHEN dr.cliente_id IS NOT NULL THEN 1 ELSE 0 END
            + CASE WHEN ce.pct_utilizacao_limite > 80   THEN 1 ELSE 0 END
            + CASE WHEN ce.pct_exposicao_descoberta > 30 THEN 1 ELSE 0 END) >= 2
            THEN 'ALTO_RISCO'
        WHEN ce.pct_utilizacao_limite > 75
          OR ce.pct_exposicao_descoberta > 25
            THEN 'ATENCAO'
        ELSE 'NORMAL'
    END                                                        AS classificacao_risco
FROM credito_ibba.vw_stage_cliente_enriquecido ce
LEFT JOIN deterioracao_rating dr ON ce.cliente_id = dr.cliente_id
WHERE ce.status_cliente = 'Ativo';
