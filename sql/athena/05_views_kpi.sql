-- ================================================================
-- credito_bba | Athena — Camada DW: Views de KPI para QuickSight
-- Arquivo   : 05_views_kpi.sql
-- Camada    : DW (camada semântica / Gold)
-- Objetivo  : Equivalente a sql/sqlserver/05_views_kpi.sql,
--             adaptado para Athena. Consumido pelo Amazon QuickSight.
--
-- No QuickSight: cada view é um Dataset.
--   Crie um Dataset por view e use-os nos visuais diretamente.
--
-- Nota técnica : Script convertido a partir da versão SQL Server (sql/sqlserver/).
--               Sintaxe adaptada para Athena/Presto — lógica analítica equivalente.
-- ================================================================

-- KPI 1: Exposição consolidada do portfólio
CREATE OR REPLACE VIEW credito_ibba.vw_kpi_exposicao AS
SELECT
    COUNT(DISTINCT cliente_id)                                  AS qtd_clientes,
    ROUND(SUM(exposicao_total)      / 1e9, 3)                  AS exposicao_total_BI,
    ROUND(SUM(exposicao_garantida)  / 1e9, 3)                  AS exposicao_garantida_BI,
    ROUND(SUM(exposicao_descoberta) / 1e9, 3)                  AS exposicao_descoberta_BI,
    ROUND(SUM(provisao_necessaria)  / 1e9, 3)                  AS provisao_BI,
    ROUND(SUM(exposicao_descoberta) / NULLIF(SUM(exposicao_total), 0) * 100, 1)
                                                                AS pct_descoberta,
    CASE
        WHEN SUM(exposicao_descoberta) / NULLIF(SUM(exposicao_total), 0) * 100 < 30 THEN 'META'
        WHEN SUM(exposicao_descoberta) / NULLIF(SUM(exposicao_total), 0) * 100 < 40 THEN 'ATENCAO'
        ELSE 'CRITICO'
    END                                                         AS status_descoberta
FROM credito_ibba.vw_stage_exposicao_recente;

-- KPI 2: Score ponderado da carteira
CREATE OR REPLACE VIEW credito_ibba.vw_kpi_ratings AS
SELECT
    ROUND(
        SUM(CAST(rr.score_interno AS DOUBLE) * er.exposicao_total)
        / NULLIF(SUM(er.exposicao_total), 0), 0
    )                                                           AS score_ponderado_carteira,
    ROUND(AVG(CAST(rr.score_interno AS DOUBLE)), 0)             AS score_medio_simples,
    ROUND(AVG(rr.pd_12m) * 100, 3)                             AS pd_medio_pct
FROM credito_ibba.vw_stage_rating_recente rr
INNER JOIN credito_ibba.vw_stage_exposicao_recente er ON rr.cliente_id = er.cliente_id;

-- KPI 3: Utilização de limites
CREATE OR REPLACE VIEW credito_ibba.vw_kpi_limites AS
SELECT
    COUNT(DISTINCT cliente_id)                                  AS qtd_clientes_com_limite,
    ROUND(SUM(limite_total)    / 1e9, 3)                       AS limite_total_BI,
    ROUND(SUM(utilizado_total) / 1e9, 3)                       AS utilizado_total_BI,
    ROUND(SUM(utilizado_total) / NULLIF(SUM(limite_total), 0) * 100, 1)
                                                                AS pct_utilizacao_media,
    COUNT(CASE WHEN pct_utilizacao_limite > 85 THEN 1 END)     AS clientes_acima_alerta
FROM credito_ibba.vw_stage_limite_consolidado;

-- KPI 4: Distribuição da carteira por classificação de risco
CREATE OR REPLACE VIEW credito_ibba.vw_kpi_risco AS
SELECT
    classificacao_risco,
    COUNT(*)                                                    AS qtd_clientes,
    ROUND(SUM(exposicao_total) / 1e6, 2)                       AS exposicao_total_MM,
    ROUND(AVG(pd_12m) * 100, 3)                                AS pd_medio_pct
FROM credito_ibba.vw_matriz_risco
GROUP BY classificacao_risco;
