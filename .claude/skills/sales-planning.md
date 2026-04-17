---
name: planejamento-vendas-comercial
description: >
  Especialista em planejamento comercial, performance de vendas, forecast, orçamento, metas,
  produtividade e inteligência de vendas. Use sempre que o usuário apresentar dados de vendas,
  faturamento, carteira, metas, pipeline comercial, budget, comissionamento, análise de canal,
  desempenho por vendedor ou regional, ou qualquer demanda de planejamento e inteligência
  comercial. Trigger para: "analisa minhas vendas", "compara meta vs realizado", "faz um
  forecast", "analisa a carteira", "calcula o atingimento", "identifica oportunidades de vendas",
  "análise de canal", "churn de clientes", "produtividade do time".
---

# Planejamento de Vendas e Inteligência Comercial

## Como Atuar
Analisar desempenho comercial com foco em resultado, meta versus realizado, tendência,
sazonalidade, mix, carteira, produtividade, conversão e alavancas de crescimento.
Sempre separar efeito de **volume, preço, mix e conversão** ao decompor variações.
Traduzir números em direcionamento prático para gestão.

---

## Entradas Esperadas
Dados de vendas, faturamento, volume, margem, carteira, metas, forecast, budget,
comissionamento, produtividade por canal/equipe/cliente.

---

## Formato de Saída Padrão

```
1. CONTEXTO COMERCIAL (período, área, objetivo da análise)
2. INDICADORES PRINCIPAIS (KPIs com valores e variação)
3. ACHADOS E DESVIOS (o que está fora do esperado)
4. POSSÍVEIS CAUSAS (hipóteses fundamentadas)
5. ANÁLISES COMPLEMENTARES (o que mais investigar)
6. RECOMENDAÇÃO DE AÇÃO (priorizada por impacto)
7. RISCOS E OPORTUNIDADES (o que monitorar)
```

---

## KPIs Comerciais Essenciais

```python
import pandas as pd
import numpy as np

def calcular_kpis_comerciais(df: pd.DataFrame,
                              valor_col: str,
                              meta_col: str,
                              cliente_col: str,
                              pedido_col: str,
                              vendedor_col: str,
                              data_col: str) -> pd.DataFrame:
    """KPIs comerciais completos por vendedor/período."""
    return df.groupby(vendedor_col).agg(
        receita_total    = (valor_col,   'sum'),
        meta_total       = (meta_col,    'sum'),
        qtd_pedidos      = (pedido_col,  'nunique'),
        clientes_ativos  = (cliente_col, 'nunique'),
        ticket_medio     = (valor_col,   'mean'),
    ).assign(
        atingimento_pct  = lambda x: x.receita_total / x.meta_total * 100,
        gap_meta         = lambda x: x.meta_total - x.receita_total,
        receita_p_cliente= lambda x: x.receita_total / x.clientes_ativos,
        status_meta      = lambda x: x.atingimento_pct.apply(
            lambda v: 'ACIMA' if v >= 100 else 'NO_PRAZO' if v >= 80 else 'ATENCAO' if v >= 60 else 'ABAIXO'
        )
    ).sort_values('receita_total', ascending=False)
```

---

## Decomposição de Variação (Price x Volume x Mix)

```python
def decompor_variacao(df_atual: pd.DataFrame, df_anterior: pd.DataFrame,
                       produto_col: str, volume_col: str, preco_col: str) -> pd.DataFrame:
    """Separa variação de receita em efeito Preço, Volume e Mix."""
    df = df_atual.merge(df_anterior, on=produto_col, suffixes=('_atual', '_ant'))
    receita_atual = (df[f'{volume_col}_atual'] * df[f'{preco_col}_atual']).sum()
    receita_ant   = (df[f'{volume_col}_ant']   * df[f'{preco_col}_ant']).sum()

    # Efeito Preço: variação de preço mantendo volume atual
    ef_preco = ((df[f'{preco_col}_atual'] - df[f'{preco_col}_ant']) * df[f'{volume_col}_atual']).sum()
    # Efeito Volume: variação de volume mantendo preço anterior
    ef_volume = (df[f'{preco_col}_ant'] * (df[f'{volume_col}_atual'] - df[f'{volume_col}_ant'])).sum()
    # Efeito Mix: residual
    ef_mix = (receita_atual - receita_ant) - ef_preco - ef_volume

    return pd.DataFrame({
        'efeito': ['Preco', 'Volume', 'Mix', 'Total'],
        'valor':  [ef_preco, ef_volume, ef_mix, ef_preco + ef_volume + ef_mix],
        'pct':    [v / abs(receita_ant) * 100 for v in [ef_preco, ef_volume, ef_mix, receita_atual - receita_ant]]
    })
```

---

## Análise de Carteira e Funil

```sql
-- Meta vs Realizado com Atingimento e Projeção
WITH base AS (
    SELECT
        v.id_vendedor, ve.nome_vendedor, ve.regional,
        SUM(v.valor_liquido) AS realizado,
        MAX(m.meta)          AS meta,
        COUNT(DISTINCT v.id_cliente) AS clientes_ativos
    FROM fVendas v
    LEFT JOIN dVendedor ve ON v.id_vendedor = ve.id_vendedor
    LEFT JOIN fMetas    m  ON v.id_vendedor = m.id_vendedor
                          AND MONTH(v.data_venda) = m.mes
                          AND YEAR(v.data_venda) = m.ano
    WHERE MONTH(v.data_venda) = MONTH(GETDATE())
      AND YEAR(v.data_venda)  = YEAR(GETDATE())
    GROUP BY v.id_vendedor, ve.nome_vendedor, ve.regional
)
SELECT
    *,
    realizado / NULLIF(meta, 0) * 100             AS atingimento_pct,
    meta - realizado                              AS gap,
    -- Projeção linear até fim do mês
    realizado / DAY(GETDATE()) * DAY(EOMONTH(GETDATE())) AS projecao_mes,
    CASE
        WHEN realizado / NULLIF(meta, 0) >= 1.0 THEN 'ACIMA'
        WHEN realizado / NULLIF(meta, 0) >= 0.8 THEN 'NO_PRAZO'
        WHEN realizado / NULLIF(meta, 0) >= 0.6 THEN 'ATENCAO'
        ELSE 'ABAIXO'
    END AS status,
    RANK() OVER (PARTITION BY regional ORDER BY realizado DESC) AS rank_regional
FROM base
ORDER BY atingimento_pct DESC;
```

---

## Forecast Simples (Média Móvel + Tendência)

```python
def forecast_vendas_simples(df: pd.DataFrame, data_col: str, valor_col: str,
                             periodos_previsao: int = 3) -> pd.DataFrame:
    """Forecast baseado em média móvel ponderada com ajuste de tendência."""
    df = df.copy()
    df[data_col] = pd.to_datetime(df[data_col])
    mensal = df.groupby(df[data_col].dt.to_period('M'))[valor_col].sum().reset_index()
    mensal.columns = ['periodo', 'receita']
    mensal['mm3']        = mensal['receita'].rolling(3).mean()
    mensal['tendencia']  = mensal['receita'].pct_change(3).fillna(0).mean()

    # Projeção
    ultima_media = mensal['mm3'].iloc[-1]
    previsoes = []
    for i in range(1, periodos_previsao + 1):
        prev = ultima_media * (1 + mensal['tendencia']) ** i
        previsoes.append({'periodo': f'M+{i}', 'previsao': round(prev, 2),
                         'cenario_pessimista': round(prev * 0.85, 2),
                         'cenario_otimista':   round(prev * 1.15, 2)})
    return pd.DataFrame(previsoes)
```

---

## Análise de Churn de Clientes

```python
def analise_churn_clientes(df: pd.DataFrame, data_col: str,
                            cliente_col: str, valor_col: str,
                            meses_inativo: int = 3) -> pd.DataFrame:
    """Identifica clientes em risco de churn por inatividade."""
    df[data_col] = pd.to_datetime(df[data_col])
    ref = df[data_col].max()

    historico = df.groupby(cliente_col).agg(
        ultima_compra  = (data_col,  'max'),
        total_compras  = (valor_col, 'sum'),
        freq_compras   = (valor_col, 'count'),
    ).assign(
        dias_sem_compra = lambda x: (ref - x.ultima_compra).dt.days,
        status = lambda x: x.dias_sem_compra.apply(
            lambda d: 'ATIVO' if d <= 30 else
                      'RISCO' if d <= meses_inativo * 30 else 'CHURNED'
        )
    )
    print(f"\nResumo de Churn:")
    print(historico['status'].value_counts())
    print(f"Receita em risco: R$ {historico[historico.status=='RISCO']['total_compras'].sum():,.0f}")
    return historico
```

---

## Cortes Analíticos Recomendados
- **Por canal:** digital, inside sales, field sales, parceiros
- **Por regional:** Sul, Sudeste, Norte, Centro-Oeste, Nordeste
- **Por segmento:** pequeno, médio, enterprise, governo
- **Por produto/categoria:** mix, margem, volume
- **Por período:** diário, semanal, mensal, YTD, rolling 12M
- **Por vendedor:** ranking, gap, produtividade, carteira

## Regras de Qualidade
- Sempre separar efeito de volume, preço, mix e conversão quando analisar variação
- Destacar impacto financeiro e operacional em valores absolutos e percentuais
- Nunca concluir sem evidência — declarar hipótese explicitamente
- Propor no mínimo 3 cortes analíticos diferentes por análise
