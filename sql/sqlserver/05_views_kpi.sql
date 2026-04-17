-- ================================================================
-- credito_bba | SQL Server — Camada DW: Views de KPI para Power BI
-- Arquivo   : 05_views_kpi.sql
-- Camada    : DW (camada semântica / Gold)
-- Objetivo  : Views finais expostas diretamente ao Power BI.
--             Cada view corresponde a uma "pasta de métricas" no
--             modelo do Power BI — os campos chegam prontos,
--             sem necessidade de medidas DAX adicionais.
--
-- Mapeamento Power BI:
--   vw_kpi_exposicao       → Pasta "0. Exposição" (cards principais)
--   vw_kpi_ratings         → Pasta "1. Ratings"
--   vw_kpi_limites         → Pasta "2. Limites"
--   vw_kpi_operacoes       → Pasta "3. Operações"
--   vw_kpi_risco           → Pasta "4. Risco" (matriz de alertas)
--
-- Para QuickSight: use os mesmos arquivos da pasta athena/
--
-- Nota técnica : Queries escritas em SQL Server para prototipagem local.
--               Versão convertida para Amazon Athena disponível em sql/athena/
-- ================================================================

USE credito_ibba;
GO

-- ----------------------------------------------------------------
-- KPI 1: vw_kpi_exposicao
-- Exposição consolidada do portfólio — snapshot atual
-- ----------------------------------------------------------------
CREATE OR ALTER VIEW vw_kpi_exposicao AS
SELECT
    COUNT(DISTINCT cliente_id)                                  AS qtd_clientes,
    ROUND(SUM(exposicao_total)      / 1e9, 3)                  AS exposicao_total_BI,
    ROUND(SUM(exposicao_garantida)  / 1e9, 3)                  AS exposicao_garantida_BI,
    ROUND(SUM(exposicao_descoberta) / 1e9, 3)                  AS exposicao_descoberta_BI,
    ROUND(SUM(provisao_necessaria)  / 1e9, 3)                  AS provisao_BI,
    ROUND(SUM(exposicao_descoberta) / NULLIF(SUM(exposicao_total), 0) * 100, 1)
                                                                AS pct_descoberta,
    -- Status do KPI de descoberta (benchmark: meta <30%)
    CASE
        WHEN SUM(exposicao_descoberta) / NULLIF(SUM(exposicao_total), 0) * 100 < 30
        THEN 'META'
        WHEN SUM(exposicao_descoberta) / NULLIF(SUM(exposicao_total), 0) * 100 < 40
        THEN 'ATENCAO'
        ELSE 'CRITICO'
    END                                                         AS status_descoberta
FROM vw_stage_exposicao_recente;
GO

-- ----------------------------------------------------------------
-- KPI 2: vw_kpi_ratings
-- Score ponderado por exposição — qualidade da carteira
-- ----------------------------------------------------------------
CREATE OR ALTER VIEW vw_kpi_ratings AS
SELECT
    ROUND(
        SUM(CAST(rr.score_interno AS FLOAT) * er.exposicao_total)
        / NULLIF(SUM(er.exposicao_total), 0), 0
    )                                                           AS score_ponderado_carteira,
    ROUND(AVG(CAST(rr.score_interno AS FLOAT)), 0)              AS score_medio_simples,
    ROUND(AVG(rr.pd_12m) * 100, 3)                             AS pd_medio_pct,
    COUNT(DISTINCT CASE WHEN rr.rating_interno IN ('BB', 'BB-', 'B+', 'B', 'B-', 'C')
        THEN rr.cliente_id END)                                 AS clientes_subinvestment,
    -- Status do score ponderado (benchmark interno)
    CASE
        WHEN SUM(CAST(rr.score_interno AS FLOAT) * er.exposicao_total)
             / NULLIF(SUM(er.exposicao_total), 0) >= 850  THEN 'EXCELENTE'
        WHEN SUM(CAST(rr.score_interno AS FLOAT) * er.exposicao_total)
             / NULLIF(SUM(er.exposicao_total), 0) >= 800  THEN 'MUITO_BOM'
        WHEN SUM(CAST(rr.score_interno AS FLOAT) * er.exposicao_total)
             / NULLIF(SUM(er.exposicao_total), 0) >= 750  THEN 'ATENCAO'
        WHEN SUM(CAST(rr.score_interno AS FLOAT) * er.exposicao_total)
             / NULLIF(SUM(er.exposicao_total), 0) >= 650  THEN 'CUIDADO'
        ELSE 'CRITICO'
    END                                                         AS status_rating
FROM vw_stage_rating_recente rr
INNER JOIN vw_stage_exposicao_recente er ON rr.cliente_id = er.cliente_id;
GO

-- ----------------------------------------------------------------
-- KPI 3: vw_kpi_limites
-- Utilização de limites da carteira
-- ----------------------------------------------------------------
CREATE OR ALTER VIEW vw_kpi_limites AS
SELECT
    COUNT(DISTINCT cliente_id)                                  AS qtd_clientes_com_limite,
    ROUND(SUM(limite_total)    / 1e9, 3)                       AS limite_total_BI,
    ROUND(SUM(utilizado_total) / 1e9, 3)                       AS utilizado_total_BI,
    ROUND(SUM(utilizado_total) / NULLIF(SUM(limite_total), 0) * 100, 1)
                                                                AS pct_utilizacao_media,
    COUNT(CASE WHEN pct_utilizacao_limite > 85 THEN 1 END)     AS clientes_acima_alerta,
    COUNT(CASE WHEN pct_utilizacao_limite > 75
               AND pct_utilizacao_limite <= 85 THEN 1 END)     AS clientes_em_atencao,
    -- Status (benchmark: 60-75% ideal, >85% alerta)
    CASE
        WHEN SUM(utilizado_total) / NULLIF(SUM(limite_total), 0) * 100 BETWEEN 60 AND 75
        THEN 'IDEAL'
        WHEN SUM(utilizado_total) / NULLIF(SUM(limite_total), 0) * 100 > 85
        THEN 'ALERTA'
        ELSE 'MONITORAR'
    END                                                         AS status_utilizacao
FROM vw_stage_limite_consolidado;
GO

-- ----------------------------------------------------------------
-- KPI 4: vw_kpi_operacoes
-- Volume e valor das operações ativas
-- ----------------------------------------------------------------
CREATE OR ALTER VIEW vw_kpi_operacoes AS
SELECT
    COUNT(operacao_id)                                          AS total_operacoes_ativas,
    COUNT(DISTINCT cliente_id)                                  AS clientes_com_operacao,
    ROUND(SUM(valor_aprovado)  / 1e9, 3)                       AS aprovado_total_BI,
    ROUND(SUM(valor_utilizado) / 1e9, 3)                       AS utilizado_total_BI,
    ROUND(AVG(taxa_juros) * 100, 2)                            AS taxa_media_pct,
    ROUND(AVG(CAST(prazo_meses AS FLOAT)), 0)                  AS prazo_medio_meses
FROM operacoes
WHERE status_operacao = 'Ativa';
GO

-- ----------------------------------------------------------------
-- KPI 5: vw_kpi_risco
-- Distribuição de clientes por classificação de risco
-- ----------------------------------------------------------------
CREATE OR ALTER VIEW vw_kpi_risco AS
SELECT
    classificacao_risco,
    COUNT(*)                                                    AS qtd_clientes,
    ROUND(SUM(exposicao_total) / 1e6, 2)                       AS exposicao_total_MM,
    ROUND(AVG(pd_12m) * 100, 3)                                AS pd_medio_pct,
    ROUND(SUM(exposicao_total) /
          (SELECT SUM(exposicao_total) FROM vw_matriz_risco) * 100, 1)
                                                                AS pct_carteira
FROM vw_matriz_risco
GROUP BY classificacao_risco;
GO
