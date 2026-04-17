-- ================================================================
-- credito_bba | Athena — Queries analíticas do case
-- Arquivo   : 04_queries_analiticas.sql
-- Camada    : DW (consumo analítico)
-- Objetivo  : Equivalente a sql/sqlserver/04_queries_analiticas.sql,
--             com sintaxe adaptada para Athena (Presto/Trino).
--
-- Guia rápido de adaptações SQL Server → Athena:
--   FORMAT(date,'yyyy-MM') → DATE_FORMAT(date,'%Y-%m')
--   STDEV()               → STDDEV()
--   TOP N                 → LIMIT N
--   GETDATE()             → CURRENT_DATE
--   DATEDIFF(DAY,d1,d2)   → DATE_DIFF('day', d1, d2)
--   PERCENTILE_CONT WITHIN GROUP → APPROX_PERCENTILE(col, p)
--   CONCAT(a,b)           → CONCAT(a,b) (igual)
--
-- Nota técnica : Script convertido a partir da versão SQL Server (sql/sqlserver/).
--               Sintaxe adaptada para Athena/Presto — lógica analítica equivalente.
-- ================================================================

-- ================================================================
-- QUESTÃO 2.1 — Clientes ativos com operações
-- ================================================================
SELECT
    c.cliente_id,
    c.segmento,
    COUNT(o.operacao_id)                                       AS total_operacoes_ativas,
    SUM(o.valor_aprovado)                                      AS valor_aprovado_total,
    SUM(o.valor_utilizado)                                     AS valor_utilizado_total,
    ROUND(
        SUM(o.valor_utilizado) / NULLIF(SUM(o.valor_aprovado), 0) * 100, 1
    )                                                          AS pct_utilizacao
FROM credito_ibba.clientes c
INNER JOIN credito_ibba.operacoes o
    ON c.cliente_id = o.cliente_id
   AND o.status_operacao = 'Ativa'
WHERE c.status_cliente = 'Ativo'
GROUP BY c.cliente_id, c.segmento
ORDER BY valor_aprovado_total DESC;


-- ================================================================
-- QUESTÃO 2.2 — Exposição por subsetor (>5 clientes)
-- ================================================================
WITH exposicao_recente AS (
    SELECT e.cliente_id, e.exposicao_total, e.exposicao_descoberta
    FROM credito_ibba.exposicoes e
    INNER JOIN (
        SELECT cliente_id, MAX(data_referencia) AS ultima_data
        FROM credito_ibba.exposicoes GROUP BY cliente_id
    ) ult ON e.cliente_id = ult.cliente_id
          AND e.data_referencia = ult.ultima_data
)
SELECT
    c.subsetor,
    COUNT(DISTINCT c.cliente_id)                               AS qtd_clientes,
    ROUND(AVG(er.exposicao_total) / 1e6, 2)                   AS exposicao_media_MM,
    ROUND(MAX(er.exposicao_total) / 1e6, 2)                   AS maior_exposicao_MM,
    ROUND(SUM(er.exposicao_total) / 1e6, 2)                   AS exposicao_total_MM,
    ROUND(
        SUM(er.exposicao_descoberta) / NULLIF(SUM(er.exposicao_total), 0) * 100, 1
    )                                                          AS pct_descoberta
FROM credito_ibba.clientes c
INNER JOIN exposicao_recente er ON c.cliente_id = er.cliente_id
GROUP BY c.subsetor
HAVING COUNT(DISTINCT c.cliente_id) > 5
ORDER BY exposicao_total_MM DESC;


-- ================================================================
-- QUESTÃO 2.3 — Evolução de rating por segmento
-- Nota: DATE_FORMAT em vez de FORMAT; sem GO
-- ================================================================
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
FROM rating_mensal
ORDER BY segmento, ano_mes;


-- ================================================================
-- QUESTÃO 2.4 — Clientes em alerta combinado de risco
-- ================================================================
SELECT
    cliente_id,
    segmento,
    subsetor,
    rating_interno,
    score_interno,
    ROUND(pd_12m * 100, 3)          AS pd_12m_pct,
    pct_utilizacao_limite,
    pct_exposicao_descoberta,
    ROUND(exposicao_total / 1e6, 2) AS exposicao_MM,
    flag_deterioracao_rating,
    flag_utilizacao_alta,
    flag_descoberta_alta,
    classificacao_risco
FROM credito_ibba.vw_matriz_risco
WHERE classificacao_risco IN ('ALTO_RISCO', 'ATENCAO')
ORDER BY
    CASE classificacao_risco WHEN 'ALTO_RISCO' THEN 1 WHEN 'ATENCAO' THEN 2 END,
    exposicao_total DESC;


-- ================================================================
-- QUESTÃO 2.5 — Análise estatística avançada
-- Nota: APPROX_PERCENTILE em vez de PERCENTILE_CONT
--       STDDEV() em vez de STDEV()
-- ================================================================
WITH stats_base AS (
    SELECT
        c.cliente_id,
        c.segmento,
        er.exposicao_total,
        rr.score_interno,
        lc.pct_utilizacao_limite
    FROM credito_ibba.clientes c
    LEFT JOIN credito_ibba.vw_stage_exposicao_recente  er ON c.cliente_id = er.cliente_id
    LEFT JOIN credito_ibba.vw_stage_rating_recente     rr ON c.cliente_id = rr.cliente_id
    LEFT JOIN credito_ibba.vw_stage_limite_consolidado lc ON c.cliente_id = lc.cliente_id
    WHERE c.status_cliente = 'Ativo'
),
stats_segmento AS (
    SELECT
        segmento,
        AVG(exposicao_total)   AS media_exp,
        STDDEV(exposicao_total) AS desvio_exp   -- STDDEV no Athena
    FROM stats_base
    GROUP BY segmento
)
SELECT
    sb.cliente_id,
    sb.segmento,
    ROUND(sb.exposicao_total / 1e6, 2)                         AS exposicao_MM,
    ROUND((sb.exposicao_total - ss.media_exp) / NULLIF(ss.desvio_exp, 0), 2)
                                                               AS zscore_exposicao,
    CASE
        WHEN ABS((sb.exposicao_total - ss.media_exp) / NULLIF(ss.desvio_exp, 0)) > 2
        THEN 'OUTLIER' ELSE 'NORMAL'
    END                                                        AS flag_outlier
FROM stats_base sb
JOIN stats_segmento ss ON sb.segmento = ss.segmento
ORDER BY ABS((sb.exposicao_total - ss.media_exp) / NULLIF(ss.desvio_exp, 0)) DESC
LIMIT 20;
