-- ================================================================
-- credito_bba | SQL Server — Queries analíticas do case
-- Arquivo   : 04_queries_analiticas.sql
-- Camada    : DW (consumo analítico)
-- Objetivo  : Queries comentadas para as 6 questões do case IBBA.
--             Cada query documenta: objetivo, técnicas, resultado
--             e insight de negócio derivado.
--
-- Pré-requisito: 03_dw_views.sql executado com sucesso
-- ================================================================

USE credito_ibba;
GO

-- ================================================================
-- QUESTÃO 2.1 — Clientes ativos com operações
-- ================================================================
-- OBJETIVO: Identificar volume e valor das operações ativas por
--           cliente para priorizar relacionamentos de maior risco.
-- RESULTADO: 48 clientes | CLI862 lidera com R$605M e 89.4% utilização
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
FROM clientes c
INNER JOIN operacoes o
    ON  c.cliente_id    = o.cliente_id
    AND o.status_operacao = 'Ativa'
WHERE c.status_cliente = 'Ativo'
GROUP BY c.cliente_id, c.segmento
ORDER BY valor_aprovado_total DESC;
GO


-- ================================================================
-- QUESTÃO 2.2 — Exposição por subsetor (apenas subsetores c/ >5 clientes)
-- ================================================================
-- OBJETIVO: Mapear concentração por subsetor para identificar riscos.
-- RESULTADO: 2 subsetores com >5 clientes — portfólio pulverizado.
--            Farmacêuticos: R$1.07B | Software e TI: R$821M
-- ================================================================

WITH exposicao_recente AS (
    SELECT e.cliente_id, e.exposicao_total, e.exposicao_descoberta
    FROM exposicoes e
    INNER JOIN (
        SELECT cliente_id, MAX(data_referencia) AS ultima_data
        FROM exposicoes GROUP BY cliente_id
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
FROM clientes c
INNER JOIN exposicao_recente er ON c.cliente_id = er.cliente_id
GROUP BY c.subsetor
HAVING COUNT(DISTINCT c.cliente_id) > 5
ORDER BY exposicao_total_MM DESC;
GO


-- ================================================================
-- QUESTÃO 2.3 — Evolução mensal de rating por segmento
-- ================================================================
-- OBJETIVO: Monitorar qualidade de crédito por segmento ao longo do tempo.
-- RESULTADO: 36 linhas (3 segmentos x 12 meses)
--            Corporate em 3º em todos os meses — faixa ATENÇÃO (~762)
-- ================================================================

SELECT
    segmento,
    ano_mes,
    nota_media,
    score_medio,
    nota_mes_anterior,
    variacao_pct_mom,
    ranking_segmento_mes
FROM vw_evolucao_rating_segmento
ORDER BY segmento, ano_mes;
GO


-- ================================================================
-- QUESTÃO 2.4 — Clientes em alerta combinado de risco
-- ================================================================
-- OBJETIVO: Priorizar clientes com múltiplos fatores de risco
--           para ação preventiva do Comitê de Crédito.
-- RESULTADO: Clientes ALTO_RISCO = deterioração + utilização alta
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
FROM vw_matriz_risco
WHERE classificacao_risco IN ('ALTO_RISCO', 'ATENCAO')
ORDER BY
    CASE classificacao_risco WHEN 'ALTO_RISCO' THEN 1 WHEN 'ATENCAO' THEN 2 END,
    exposicao_total DESC;
GO


-- ================================================================
-- QUESTÃO 2.5 — Análise estatística avançada
-- ================================================================
-- OBJETIVO: Z-Score, percentis, volatilidade e correlações.
-- ================================================================

WITH stats_base AS (
    SELECT
        c.cliente_id,
        c.segmento,
        c.subsetor,
        er.exposicao_total,
        rr.score_interno,
        lc.pct_utilizacao_limite
    FROM clientes c
    LEFT JOIN vw_stage_exposicao_recente  er ON c.cliente_id = er.cliente_id
    LEFT JOIN vw_stage_rating_recente     rr ON c.cliente_id = rr.cliente_id
    LEFT JOIN vw_stage_limite_consolidado lc ON c.cliente_id = lc.cliente_id
    WHERE c.status_cliente = 'Ativo'
),
stats_segmento AS (
    SELECT
        segmento,
        AVG(exposicao_total)  AS media_exp,
        STDEV(exposicao_total) AS desvio_exp
    FROM stats_base
    GROUP BY segmento
),
-- 1. Z-Score para detecção de outliers de exposição
zscore AS (
    SELECT
        sb.cliente_id,
        sb.segmento,
        sb.exposicao_total,
        ROUND((sb.exposicao_total - ss.media_exp) / NULLIF(ss.desvio_exp, 0), 2)
            AS zscore_exposicao,
        CASE
            WHEN ABS((sb.exposicao_total - ss.media_exp) / NULLIF(ss.desvio_exp, 0)) > 2
            THEN 'OUTLIER' ELSE 'NORMAL'
        END AS flag_outlier
    FROM stats_base sb
    JOIN stats_segmento ss ON sb.segmento = ss.segmento
),
-- 2. Percentis de exposição por segmento
percentis AS (
    SELECT
        segmento,
        ROUND(PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY exposicao_total)
              OVER (PARTITION BY segmento) / 1e6, 2) AS p25_MM,
        ROUND(PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY exposicao_total)
              OVER (PARTITION BY segmento) / 1e6, 2) AS p50_MM,
        ROUND(PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY exposicao_total)
              OVER (PARTITION BY segmento) / 1e6, 2) AS p75_MM,
        ROUND(PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY exposicao_total)
              OVER (PARTITION BY segmento) / 1e6, 2) AS p95_MM
    FROM stats_base
)
-- Resultado 1: Outliers por segmento
SELECT 'Z-SCORE' AS analise, cliente_id, segmento,
       ROUND(exposicao_total / 1e6, 2) AS exposicao_MM,
       zscore_exposicao, flag_outlier AS resultado
FROM zscore
WHERE flag_outlier = 'OUTLIER'
UNION ALL
-- Resultado 2: Percentis por segmento (1 linha por segmento)
SELECT DISTINCT 'PERCENTIS', NULL, segmento, NULL, p50_MM,
       CONCAT('P25=', p25_MM, ' | P75=', p75_MM, ' | P95=', p95_MM)
FROM percentis
ORDER BY analise, segmento;
GO


-- ================================================================
-- QUESTÃO 2.6 — Análises além do escopo — insights adicionais
-- ================================================================

-- 2.6-A: Concentração por setor — visão regulatória
SELECT
    c.setor,
    COUNT(DISTINCT c.cliente_id)                               AS qtd_clientes,
    ROUND(SUM(er.exposicao_total) / 1e6, 2)                   AS exposicao_total_MM,
    ROUND(SUM(er.exposicao_total) /
          (SELECT SUM(exposicao_total) FROM vw_stage_exposicao_recente) * 100, 1)
                                                               AS pct_carteira
FROM clientes c
INNER JOIN vw_stage_exposicao_recente er ON c.cliente_id = er.cliente_id
GROUP BY c.setor
ORDER BY exposicao_total_MM DESC;
GO

-- 2.6-B: Operações vencidas — risco materializado
SELECT
    c.cliente_id, c.segmento, c.subsetor,
    o.operacao_id, o.produto, o.modalidade,
    o.valor_aprovado, o.valor_utilizado,
    o.data_vencimento,
    DATEDIFF(DAY, o.data_vencimento, GETDATE()) AS dias_vencido
FROM operacoes o
INNER JOIN clientes c ON o.cliente_id = c.cliente_id
WHERE o.status_operacao = 'Vencida'
   OR (o.data_vencimento < CAST(GETDATE() AS DATE) AND o.status_operacao = 'Ativa')
ORDER BY dias_vencido DESC;
GO

-- 2.6-C: Score por segmento e porte — qualidade relativa
SELECT
    c.segmento,
    c.porte,
    COUNT(DISTINCT c.cliente_id)                               AS qtd_clientes,
    ROUND(AVG(CAST(r.score_interno AS FLOAT)), 0)              AS score_medio,
    MIN(r.score_interno)                                       AS score_minimo,
    MAX(r.score_interno)                                       AS score_maximo,
    ROUND(STDEV(r.score_interno), 0)                           AS desvio_score
FROM ratings r
INNER JOIN clientes c ON r.cliente_id = c.cliente_id
INNER JOIN (
    SELECT cliente_id, MAX(data_referencia) AS ultima
    FROM ratings GROUP BY cliente_id
) ult ON r.cliente_id = ult.cliente_id AND r.data_referencia = ult.ultima
GROUP BY c.segmento, c.porte
ORDER BY c.segmento, score_medio DESC;
GO
