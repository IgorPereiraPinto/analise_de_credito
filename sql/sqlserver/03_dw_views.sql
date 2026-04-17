-- ================================================================
-- credito_bba | SQL Server — Camada DW: Views analíticas e KPIs
-- Arquivo   : 03_dw_views.sql
-- Camada    : DW (Data Warehouse / Gold)
-- Objetivo  : Construir a camada semântica com KPIs calculados,
--             classificações de risco, alertas e rankings.
--             Estas views são consumidas diretamente pelo Power BI
--             e pelo dashboard HTML.
--
-- O que é DW:
--   Dado de negócio. KPIs prontos para consumo, classificações,
--   scores agregados por segmento/subsetor, e matriz de risco.
--   Nenhuma lógica de limpeza aqui — apenas cálculo e apresentação.
--
-- Pré-requisito: 02_stage_views.sql executado com sucesso
--
-- Nota técnica : Queries escritas em SQL Server para prototipagem local.
--               Versão convertida para Amazon Athena disponível em sql/athena/
-- ================================================================

USE credito_ibba;
GO

-- ----------------------------------------------------------------
-- DW 1: vw_kpi_exposicao
-- KPIs consolidados de exposição do portfólio
-- Alimenta: cards de KPI e gráfico de pizza no dashboard
-- ----------------------------------------------------------------
CREATE OR ALTER VIEW vw_kpi_exposicao AS
SELECT
    SUM(exposicao_total)                                        AS exposicao_total_portfolio,
    SUM(exposicao_garantida)                                    AS exposicao_garantida_total,
    SUM(exposicao_descoberta)                                   AS exposicao_descoberta_total,
    SUM(provisao_necessaria)                                    AS provisao_total,
    ROUND(SUM(exposicao_descoberta) /
          NULLIF(SUM(exposicao_total), 0) * 100, 1)            AS pct_descoberta_portfolio,
    COUNT(DISTINCT cliente_id)                                  AS qtd_clientes_ativos
FROM vw_stage_exposicao_recente;
GO

-- ----------------------------------------------------------------
-- DW 2: vw_kpi_por_segmento
-- KPIs de exposição, rating e risco por segmento
-- Alimenta: gráfico de barras e tabela de segmento no dashboard
-- ----------------------------------------------------------------
CREATE OR ALTER VIEW vw_kpi_por_segmento AS
SELECT
    c.segmento,
    COUNT(DISTINCT c.cliente_id)                                AS qtd_clientes,
    ROUND(SUM(er.exposicao_total) / 1e6, 2)                    AS exposicao_total_MM,
    ROUND(AVG(er.pct_exposicao_descoberta), 1)                  AS pct_descoberta_medio,
    ROUND(AVG(CAST(rr.score_interno AS FLOAT)), 0)              AS score_medio,
    ROUND(AVG(CAST(rr.nota_rating AS FLOAT)), 2)                AS nota_rating_media,
    ROUND(AVG(rr.pd_12m) * 100, 3)                             AS pd_medio_pct,
    ROUND(AVG(lc.pct_utilizacao_limite), 1)                     AS utilizacao_media_limite
FROM clientes c
LEFT JOIN vw_stage_exposicao_recente  er ON c.cliente_id = er.cliente_id
LEFT JOIN vw_stage_rating_recente     rr ON c.cliente_id = rr.cliente_id
LEFT JOIN vw_stage_limite_consolidado lc ON c.cliente_id = lc.cliente_id
WHERE c.status_cliente = 'Ativo'
GROUP BY c.segmento;
GO

-- ----------------------------------------------------------------
-- DW 3: vw_kpi_por_subsetor
-- Concentração e risco por subsetor (Q2.2 do case)
-- Inclui flag de alerta regulatório (>15% da carteira)
-- Alimenta: mapa de concentração e alertas de risco
-- ----------------------------------------------------------------
CREATE OR ALTER VIEW vw_kpi_por_subsetor AS
WITH total_portfolio AS (
    SELECT SUM(exposicao_total) AS total FROM vw_stage_exposicao_recente
)
SELECT
    c.subsetor,
    c.setor,
    COUNT(DISTINCT c.cliente_id)                               AS qtd_clientes,
    ROUND(SUM(er.exposicao_total) / 1e6, 2)                   AS exposicao_total_MM,
    ROUND(AVG(er.exposicao_total) / 1e6, 2)                   AS exposicao_media_MM,
    MAX(er.exposicao_total) / 1e6                              AS maior_exposicao_MM,
    ROUND(SUM(er.exposicao_descoberta) /
          NULLIF(SUM(er.exposicao_total), 0) * 100, 1)        AS pct_descoberta,
    ROUND(SUM(er.exposicao_total) /
          NULLIF(tp.total, 0) * 100, 2)                       AS pct_concentracao,
    CASE
        WHEN SUM(er.exposicao_total) / NULLIF(tp.total, 0) > 0.15 THEN 'LIMITE_REGULATORIO'
        WHEN SUM(er.exposicao_total) / NULLIF(tp.total, 0) > 0.10 THEN 'MONITORAMENTO'
        ELSE 'OK'
    END                                                        AS status_concentracao
FROM clientes c
INNER JOIN vw_stage_exposicao_recente er ON c.cliente_id = er.cliente_id
CROSS JOIN total_portfolio tp
WHERE c.status_cliente = 'Ativo'
GROUP BY c.subsetor, c.setor, tp.total;
GO

-- ----------------------------------------------------------------
-- DW 4: vw_matriz_risco
-- Matriz de risco individual — Q2.4 do case
-- Classifica clientes com múltiplos fatores de risco acumulados
-- Alimenta: tabela de alertas no dashboard
-- ----------------------------------------------------------------
CREATE OR ALTER VIEW vw_matriz_risco AS
WITH deterioracao_rating AS (
    -- Detecta clientes com piora de nota em 2+ meses consecutivos
    SELECT DISTINCT r1.cliente_id
    FROM ratings r1
    INNER JOIN ratings r2
        ON r1.cliente_id = r2.cliente_id
       AND r2.data_referencia = DATEADD(MONTH, -1, r1.data_referencia)
    INNER JOIN ratings r3
        ON r1.cliente_id = r3.cliente_id
       AND r3.data_referencia = DATEADD(MONTH, -2, r1.data_referencia)
    INNER JOIN vw_stage_escala_rating e1 ON r1.rating_interno = e1.rating
    INNER JOIN vw_stage_escala_rating e2 ON r2.rating_interno = e2.rating
    INNER JOIN vw_stage_escala_rating e3 ON r3.rating_interno = e3.rating
    WHERE e1.nota < e2.nota AND e2.nota < e3.nota  -- piora consecutiva
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
    -- Classificação por soma de flags (critério combinado)
    CASE
        WHEN (CASE WHEN dr.cliente_id IS NOT NULL THEN 1 ELSE 0 END
            + CASE WHEN ce.pct_utilizacao_limite > 80   THEN 1 ELSE 0 END
            + CASE WHEN ce.pct_exposicao_descoberta > 30 THEN 1 ELSE 0 END) >= 2
            THEN 'ALTO_RISCO'
        WHEN ce.pct_utilizacao_limite > 75
          OR ce.pct_exposicao_descoberta > 25
            THEN 'ATENCAO'
        ELSE 'NORMAL'
    END AS classificacao_risco
FROM vw_stage_cliente_enriquecido ce
LEFT JOIN deterioracao_rating dr ON ce.cliente_id = dr.cliente_id
WHERE ce.status_cliente = 'Ativo';
GO

-- ----------------------------------------------------------------
-- DW 5: vw_evolucao_rating_segmento
-- Evolução mensal do rating por segmento (Q2.3 do case)
-- Inclui variação MoM e ranking entre segmentos
-- Alimenta: gráfico de linha e tabela temporal no dashboard
-- ----------------------------------------------------------------
CREATE OR ALTER VIEW vw_evolucao_rating_segmento AS
WITH rating_mensal AS (
    SELECT
        c.segmento,
        FORMAT(r.data_referencia, 'yyyy-MM')         AS ano_mes,
        r.data_referencia,
        ROUND(AVG(CAST(er.nota AS FLOAT)), 2)        AS nota_media,
        ROUND(AVG(CAST(r.score_interno AS FLOAT)), 0) AS score_medio
    FROM ratings r
    INNER JOIN clientes c              ON r.cliente_id     = c.cliente_id
    INNER JOIN vw_stage_escala_rating er ON r.rating_interno = er.rating
    GROUP BY c.segmento,
             FORMAT(r.data_referencia, 'yyyy-MM'),
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
    , 2) AS variacao_pct_mom,
    RANK() OVER (PARTITION BY ano_mes ORDER BY nota_media DESC)
        AS ranking_segmento_mes
FROM rating_mensal;
GO
