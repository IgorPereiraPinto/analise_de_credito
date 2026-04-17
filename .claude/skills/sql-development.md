---
name: sql-analytics
description: >
  Especialista em SQL analítico para extração, tratamento, agregação, performance e análise de
  dados. Cobre SQL Server (T-SQL), AWS Athena (Presto/Trino), MySQL, BigQuery e DBeaver. Use
  sempre que o usuário pedir query SQL, precisar de análise via banco de dados, otimização de
  consulta, criação de views, stored procedures, window functions, CTEs, KPIs em SQL, debug de
  query, ou qualquer tarefa envolvendo bancos relacionais ou analíticos. Trigger para: "escreve
  uma query", "como calculo X em SQL", "otimiza essa query", "cria uma view", "por que esse
  JOIN está duplicando", "explica essa query", "transforma isso em CTE".
---

# SQL Analytics — T-SQL | Athena | MySQL | BigQuery

## Como Atuar
Criar, revisar e otimizar queries com foco em clareza, performance e aderência à regra de
negócio. Explicar joins, CTEs, subqueries, window functions e filtros temporais de forma
prática. Sempre comentar o código e explicar o raciocínio por trás das escolhas.

---

## Entradas Esperadas
Estrutura de tabelas, nomes de colunas, regra de negócio, query atual, erro encontrado,
resultado esperado e volume aproximado dos dados.

---

## Formato de Saída Padrão

```
1. ENTENDIMENTO DA NECESSIDADE (o que a query deve responder)
2. ESTRATÉGIA (abordagem escolhida e por quê)
3. CÓDIGO SQL (limpo, comentado, indentado)
4. EXPLICAÇÃO DO RACIOCÍNIO (linha a linha quando útil)
5. VALIDAÇÕES SUGERIDAS (como verificar o resultado)
6. MELHORIAS DE PERFORMANCE (índices, partições, otimizações)
7. ALTERNATIVAS (quando há outras abordagens válidas)
```

---

## 1. Template de Query Analítica Padrão

```sql
-- =============================================
-- Relatório: [Nome]
-- Autor: Igor | Data: YYYY-MM-DD
-- Banco: SQL Server / Athena / BigQuery
-- Objetivo: [Descrição clara]
-- =============================================

WITH
-- ETAPA 1: Filtro e seleção base
base AS (
    SELECT
        id_venda,
        id_cliente,
        id_vendedor,
        data_venda,
        valor_bruto,
        valor_desconto,
        valor_bruto - valor_desconto        AS valor_liquido,
        status,
        canal
    FROM dbo.fVendas  -- ou schema.tabela no Athena
    WHERE
        data_venda >= '2024-01-01'
        AND data_venda <  '2025-01-01'
        AND status NOT IN ('CANCELADO', 'ESTORNADO')
),

-- ETAPA 2: Enriquecimento dimensional
enriquecido AS (
    SELECT
        b.*,
        v.nome_vendedor,
        v.regional,
        v.gerente,
        c.segmento_cliente,
        c.cidade,
        c.uf
    FROM base b
    LEFT JOIN dbo.dVendedor v ON b.id_vendedor = v.id_vendedor
    LEFT JOIN dbo.dCliente  c ON b.id_cliente  = c.id_cliente
),

-- ETAPA 3: Cálculo de KPIs
kpis AS (
    SELECT
        id_vendedor,
        nome_vendedor,
        regional,
        gerente,
        COUNT(*)                                            AS qtd_vendas,
        COUNT(DISTINCT id_cliente)                          AS clientes_atendidos,
        SUM(valor_liquido)                                  AS receita_total,
        AVG(valor_liquido)                                  AS ticket_medio,
        SUM(valor_desconto) / NULLIF(SUM(valor_bruto), 0)  AS taxa_desconto,
        MIN(data_venda)                                     AS primeira_venda,
        MAX(data_venda)                                     AS ultima_venda
    FROM enriquecido
    GROUP BY id_vendedor, nome_vendedor, regional, gerente
)

-- RESULTADO FINAL
SELECT
    *,
    -- Ranking dentro da regional
    RANK()    OVER (PARTITION BY regional ORDER BY receita_total DESC) AS rank_regional,
    -- Participação no total geral
    receita_total / NULLIF(SUM(receita_total) OVER (), 0) * 100        AS pct_total
FROM kpis
ORDER BY receita_total DESC;
```

---

## 2. Window Functions Completas

```sql
-- ── Acumulado (Running Total) ──────────────────────────────────────────
SUM(valor)   OVER (PARTITION BY regional ORDER BY mes
                   ROWS UNBOUNDED PRECEDING)               AS acumulado

-- ── Média Móvel ────────────────────────────────────────────────────────
AVG(valor)   OVER (PARTITION BY vendedor ORDER BY mes
                   ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS mm3

-- ── Crescimento MoM / YoY ──────────────────────────────────────────────
valor / NULLIF(LAG(valor, 1) OVER (PARTITION BY vendedor ORDER BY mes), 0) - 1
                                                           AS crescimento_mom
valor / NULLIF(LAG(valor, 12) OVER (PARTITION BY vendedor ORDER BY mes), 0) - 1
                                                           AS crescimento_yoy

-- ── Rankings ──────────────────────────────────────────────────────────
RANK()       OVER (PARTITION BY regional ORDER BY receita DESC)  -- com empate
DENSE_RANK() OVER (PARTITION BY regional ORDER BY receita DESC)  -- sem gap
ROW_NUMBER() OVER (PARTITION BY regional ORDER BY receita DESC)  -- sequencial

-- ── Participação percentual ─────────────────────────────────────────────
valor / NULLIF(SUM(valor) OVER (PARTITION BY regional), 0) * 100 AS pct_regional

-- ── Lead/Lag para comparações ──────────────────────────────────────────
LAG(valor, 1)  OVER (PARTITION BY vendedor ORDER BY mes) AS valor_mes_anterior
LEAD(valor, 1) OVER (PARTITION BY vendedor ORDER BY mes) AS valor_proximo_mes

-- ── Primeira e última compra ───────────────────────────────────────────
MIN(data_compra) OVER (PARTITION BY id_cliente) AS primeira_compra
MAX(data_compra) OVER (PARTITION BY id_cliente) AS ultima_compra

-- ── Percentil ─────────────────────────────────────────────────────────
PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY valor)  -- mediana (SQL Server)
APPROX_PERCENTILE(valor, 0.5)                        -- Athena/BigQuery
```

---

## 3. Análise de Coorte

```sql
WITH primeira_compra AS (
    SELECT
        id_cliente,
        MIN(DATE_TRUNC('month', data_compra)) AS coorte
    FROM vendas
    GROUP BY id_cliente
),
atividade AS (
    SELECT
        v.id_cliente,
        pc.coorte,
        DATE_TRUNC('month', v.data_compra)                          AS mes_ativo,
        DATEDIFF('month', pc.coorte,
                 DATE_TRUNC('month', v.data_compra))                AS mes_offset
    FROM vendas v
    JOIN primeira_compra pc ON v.id_cliente = pc.id_cliente
)
SELECT
    coorte,
    mes_offset,
    COUNT(DISTINCT id_cliente)                                       AS clientes_ativos,
    COUNT(DISTINCT id_cliente) * 100.0 /
        FIRST_VALUE(COUNT(DISTINCT id_cliente))
            OVER (PARTITION BY coorte ORDER BY mes_offset)          AS retencao_pct
FROM atividade
GROUP BY coorte, mes_offset
ORDER BY coorte, mes_offset;
```

---

## 4. KPIs em SQL — Templates Prontos

```sql
-- ── Meta vs Realizado ──────────────────────────────────────────────────
SELECT
    vendedor,
    SUM(receita)                              AS realizado,
    MAX(meta)                                 AS meta,
    SUM(receita) / NULLIF(MAX(meta), 0) * 100 AS atingimento_pct,
    MAX(meta) - SUM(receita)                  AS gap,
    CASE
        WHEN SUM(receita) / NULLIF(MAX(meta), 0) >= 1.0 THEN 'ACIMA'
        WHEN SUM(receita) / NULLIF(MAX(meta), 0) >= 0.8 THEN 'NO_PRAZO'
        WHEN SUM(receita) / NULLIF(MAX(meta), 0) >= 0.6 THEN 'ATENCAO'
        ELSE 'ABAIXO'
    END AS status_meta
FROM vendas_vs_metas
GROUP BY vendedor
ORDER BY atingimento_pct DESC;

-- ── LTV por Cliente ────────────────────────────────────────────────────
SELECT
    id_cliente,
    COUNT(DISTINCT id_pedido)                AS total_pedidos,
    SUM(valor_liquido)                       AS ltv_total,
    AVG(valor_liquido)                       AS ticket_medio,
    DATEDIFF(day, MIN(data_compra),
                  MAX(data_compra))          AS dias_ativo,
    DATEDIFF(day, MAX(data_compra), GETDATE()) AS dias_sem_compra
FROM vendas
GROUP BY id_cliente
ORDER BY ltv_total DESC;

-- ── Pareto 80/20 ───────────────────────────────────────────────────────
WITH ranked AS (
    SELECT
        id_cliente,
        SUM(receita)                                        AS receita_cliente,
        SUM(SUM(receita)) OVER ()                           AS receita_total,
        SUM(SUM(receita)) OVER (ORDER BY SUM(receita) DESC) AS receita_acumulada
    FROM vendas
    GROUP BY id_cliente
)
SELECT
    id_cliente,
    receita_cliente,
    receita_acumulada / receita_total * 100 AS pct_acumulado,
    CASE WHEN receita_acumulada / receita_total <= 0.8
         THEN 'TOP 80%' ELSE 'CAUDA 20%' END AS segmento_pareto
FROM ranked
ORDER BY receita_cliente DESC;
```

---

## 5. Diferenças entre Bancos — Referência Rápida

| Funcionalidade | SQL Server | Athena (Presto) | MySQL | BigQuery |
|---|---|---|---|---|
| Data atual | `GETDATE()` | `CURRENT_DATE` | `NOW()` | `CURRENT_DATE()` |
| Truncar data | `CONVERT(date, col)` | `DATE_TRUNC('month', col)` | `DATE_FORMAT(col,'%Y-%m')` | `DATE_TRUNC(col, MONTH)` |
| Diferença datas | `DATEDIFF(day, d1, d2)` | `DATE_DIFF('day', d1, d2)` | `DATEDIFF(d1, d2)` | `DATE_DIFF(d1, d2, DAY)` |
| Top N | `TOP 10` | `LIMIT 10` | `LIMIT 10` | `LIMIT 10` |
| Percentil | `PERCENTILE_CONT` | `APPROX_PERCENTILE(col, 0.5)` | não nativo | `APPROX_QUANTILES` |
| String concat | `+` ou `CONCAT` | `||` ou `CONCAT` | `CONCAT` | `CONCAT` ou `||` |

---

## 6. Stored Procedure Padrão (SQL Server)

```sql
CREATE OR ALTER PROCEDURE usp_kpi_receita_mensal
    @ano      INT,
    @mes      INT,
    @regional VARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        regional,
        vendedor,
        SUM(valor_liquido) AS receita,
        COUNT(*)           AS qtd_vendas,
        AVG(valor_liquido) AS ticket_medio,
        COUNT(DISTINCT id_cliente) AS clientes
    FROM dbo.vw_vendas_consolidado
    WHERE YEAR(data_venda)  = @ano
      AND MONTH(data_venda) = @mes
      AND (@regional IS NULL OR regional = @regional)
    GROUP BY regional, vendedor
    ORDER BY receita DESC;
END;
-- Uso: EXEC usp_kpi_receita_mensal @ano=2024, @mes=1, @regional='Sudeste'
```

---

## 7. Performance — Checklist Athena

```sql
-- ✅ Sempre filtrar partição primeiro
WHERE year = '2024' AND month = '01'
-- ✅ Usar APPROX para contagens distintas grandes
APPROX_COUNT_DISTINCT(id_cliente)
-- ✅ Nunca SELECT * em tabelas grandes
-- ✅ Formatos: preferir PARQUET/ORC sobre CSV
-- ✅ Verificar plano antes de rodar: EXPLAIN SELECT ...
-- ✅ Limitar em exploração: LIMIT 1000
```

## Regras de Qualidade
- SQL limpo, indentado, comentado — sempre
- Explicar diferenças entre bancos quando relevante
- Nunca `SELECT *` fora de protótipo
- Alertar sobre duplicidade causada por JOIN
- Incluir validações de contagem e consistência
- Sugerir índices, particionamento ou filtros quando aplicável
