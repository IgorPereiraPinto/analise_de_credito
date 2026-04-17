# 09 — Modelagem DW

## Objetivo da etapa

Criar as views DW com os KPIs finais e a camada semântica para BI.

---

## Entradas

- Views STAGE funcionais (etapa 08)
- `sql/sqlserver/03_dw_views.sql`
- `sql/sqlserver/05_views_kpi.sql`

## Saídas

- Views de KPI prontas para consumo no Power BI ou QuickSight
- Matriz de risco individual com flags de alerta

---

## O que acontece na camada DW

A DW aplica a lógica de negócio final: benchmarks, classificações, scores ponderados,
evolução temporal e matriz de risco combinado.

Nenhum dado bruto aqui. Só cálculo sobre o que a STAGE já preparou.

---

## As 5 views DW principais

### vw_kpi_exposicao (+ vw_kpi_por_segmento, vw_kpi_por_subsetor)

Agregam a posição do portfólio em diferentes cortes.
`vw_kpi_por_subsetor` inclui o flag regulatório (>15% = LIMITE_REGULATORIO).

### vw_matriz_risco

A view mais complexa do projeto. Detecta:

1. **Deterioração de rating:** join triplo da tabela `ratings` com ela mesma (self-join)
   para verificar se o rating piorou em 3 meses consecutivos
2. **Utilização alta:** flag de utilização > 80%
3. **Descoberta alta:** flag de exposição descoberta > 30%
4. **Classificação final:** soma dos 3 flags — 2 ou mais = ALTO_RISCO

### vw_evolucao_rating_segmento

Usa `LAG()` e `RANK()` para calcular variação MoM e posição relativa de cada segmento
no ranking mensal. Alimenta o gráfico de linha no dashboard.

### vw_kpi_* (05_views_kpi.sql)

Camada semântica final para o Power BI. Cada view é uma "pasta de métricas":

- `vw_kpi_exposicao` → cards de KPI
- `vw_kpi_ratings` → score ponderado
- `vw_kpi_limites` → utilização de limites
- `vw_kpi_operacoes` → operações ativas
- `vw_kpi_risco` → distribuição por classificação

---

## Como executar

```sql
-- No SSMS, na ordem:
sql/sqlserver/03_dw_views.sql
sql/sqlserver/05_views_kpi.sql

-- Verificação rápida:
SELECT * FROM vw_kpi_exposicao;
SELECT * FROM vw_kpi_risco ORDER BY exposicao_total_MM DESC;
SELECT TOP 10 * FROM vw_matriz_risco WHERE classificacao_risco = 'ALTO_RISCO';
```

---

## Interpretando o resultado

Com os dados sintéticos, você deve encontrar:

- Score ponderado da carteira: faixa ATENÇÃO (750-799)
- Clientes em ALTO_RISCO: 3-5 clientes com múltiplos flags
- Subsetores com >10% de concentração: 2-3 subsetores
- Utilização média de limites: dentro da faixa ideal (60-75%)

---

## Checklist de conclusão da etapa

- [ ] Views DW criadas sem erro
- [ ] `vw_kpi_exposicao` retorna o total do portfólio coerente
- [ ] `vw_matriz_risco` identifica clientes com ALTO_RISCO
- [ ] `vw_evolucao_rating_segmento` mostra 36 linhas (3 segmentos x 12 meses)
- [ ] Avancei para `10_sql_server_vs_athena.md`
