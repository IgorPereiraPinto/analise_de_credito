---
name: procurement-compras
description: >
  Especialista em compras, procurement e strategic sourcing. Cobre análise de spend, budget,
  saving, fornecedores, contratos, compliance, lead time e eficiência operacional. Use sempre
  que o usuário mencionar compras, procurement, fornecedor, spend, saving, orçamento de compras,
  pedidos, requisições, contratos, lead time, SLA de fornecedores, categorias de compra, ou
  qualquer análise de gestão de suprimentos. Trigger para: "analisa os gastos", "compara spend
  vs budget", "concentração de fornecedores", "oportunidades de saving", "SLA de entrega".
---

# Procurement, Compras e Strategic Sourcing

## Como Atuar
Avaliar desempenho de compras sob ótica financeira, operacional e estratégica. Identificar
concentração de fornecedores, desvios orçamentários, oportunidades de saving, gargalos de
prazo e riscos na cadeia. Sempre separar análise por categoria, fornecedor, centro de custo
e período. Evidenciar spend versus budget em valor e percentual.

---

## Formato de Saída Padrão

```
1. VISÃO GERAL DO GASTO (spend total, budget, desvio)
2. KPIs DE PROCUREMENT (métricas principais)
3. DESVIOS E RISCOS (o que está fora do padrão)
4. HIPÓTESES E PONTOS DE ATENÇÃO
5. ANÁLISES COMPLEMENTARES SUGERIDAS
6. OPORTUNIDADES DE AÇÃO (savings, renegociação, consolidação)
7. PRÓXIMOS PASSOS
```

---

## KPIs Essenciais de Procurement

```python
import pandas as pd
import numpy as np

def kpis_procurement(df: pd.DataFrame,
                     valor_col: str, budget_col: str,
                     fornecedor_col: str, categoria_col: str,
                     prazo_previsto_col: str, prazo_real_col: str) -> dict:
    """Calcula KPIs padrão de procurement."""
    spend_total    = df[valor_col].sum()
    budget_total   = df[budget_col].sum()
    desvio         = spend_total - budget_total
    desvio_pct     = desvio / budget_total * 100 if budget_total else 0
    n_fornecedores = df[fornecedor_col].nunique()

    # Concentração (Pareto)
    top5_spend = (df.groupby(fornecedor_col)[valor_col]
                    .sum().sort_values(ascending=False)
                    .head(5).sum())
    concentracao_top5 = top5_spend / spend_total * 100

    # Lead Time
    df = df.copy()
    df['lead_time_dias'] = (df[prazo_real_col] - df[prazo_previsto_col]).dt.days
    sla_ok = (df['lead_time_dias'] <= 0).mean() * 100  # % no prazo

    return {
        'spend_total':        round(spend_total, 2),
        'budget_total':       round(budget_total, 2),
        'desvio_valor':       round(desvio, 2),
        'desvio_pct':         round(desvio_pct, 1),
        'n_fornecedores':     n_fornecedores,
        'concentracao_top5%': round(concentracao_top5, 1),
        'sla_aderencia_%':    round(sla_ok, 1),
        'lead_time_medio_d':  round(df['lead_time_dias'].mean(), 1),
    }

def pareto_fornecedores(df, fornecedor_col, valor_col):
    """Análise de Pareto de fornecedores."""
    forn = (df.groupby(fornecedor_col)[valor_col]
              .sum().sort_values(ascending=False)
              .reset_index())
    forn['pct']      = forn[valor_col] / forn[valor_col].sum() * 100
    forn['pct_acum'] = forn['pct'].cumsum()
    forn['pareto']   = forn['pct_acum'].apply(
        lambda x: 'TOP 80%' if x <= 80 else 'CAUDA 20%')
    return forn
```

---

## Análise de Saving

```sql
-- Saving realizado vs meta de saving
SELECT
    categoria,
    fornecedor,
    SUM(valor_contrato_anterior)       AS custo_base,
    SUM(valor_contrato_atual)          AS custo_atual,
    SUM(valor_contrato_anterior)
      - SUM(valor_contrato_atual)      AS saving_realizado,
    SUM(meta_saving)                   AS meta_saving,
    (SUM(valor_contrato_anterior)
      - SUM(valor_contrato_atual))
      / NULLIF(SUM(meta_saving), 0)
      * 100                            AS atingimento_saving_pct
FROM contratos
WHERE ano_vigencia = 2024
GROUP BY categoria, fornecedor
ORDER BY saving_realizado DESC;
```

## Regras de Qualidade
- Separar análise por categoria, fornecedor, centro de custo e período
- Sempre apresentar desvio em valor absoluto E percentual
- Destacar impacto de risco, custo e prazo simultaneamente
- Propor Pareto, concentração e aderência contratual em toda análise
