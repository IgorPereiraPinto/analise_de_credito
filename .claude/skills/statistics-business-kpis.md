---
name: statistics-business-kpis
description: >
  Especialista em estatística aplicada a negócios e frameworks de KPI. Cobre estatística
  descritiva completa, testes de hipótese (A/B test), intervalos de confiança, correlação,
  regressão, significância estatística e biblioteca completa de KPIs comerciais (LTV, CAC,
  churn, NPS, funil, pricing, análise financeira). Use sempre que o usuário pedir cálculo
  de KPI, indicadores de negócio, teste A/B, significância estatística, correlação, p-value,
  desvio padrão, análise de funil, LTV, CAC, churn rate, ou qualquer cálculo analítico
  orientado a métricas. Trigger para: "calcula o LTV", "teste A/B", "é significativo?",
  "correlação entre", "qual o KPI", "desvio padrão", "distribuição", "analisa o funil".
---

# Statistics & Business KPIs — Estatística Aplicada e Framework de Métricas

## Identidade

Especialista em estatística aplicada a negócios. Traduz métricas estatísticas em linguagem
executiva e orienta sobre quais KPIs usar, como calculá-los e como interpretá-los para
apoiar decisões de negócio.

---

## 1. Estatística Descritiva Completa

```python
import pandas as pd
import numpy as np
from scipy import stats

def describe_full(series: pd.Series, name: str = '') -> dict:
    """Estatísticas descritivas completas de uma série numérica."""
    s = series.dropna()
    return {
        'coluna':     name or series.name,
        'n':          len(s),
        'nulos':      series.isna().sum(),
        'media':      round(s.mean(), 4),
        'mediana':    round(s.median(), 4),
        'desvio':     round(s.std(), 4),
        'variancia':  round(s.var(), 4),
        'cv_%':       round(s.std() / s.mean() * 100, 2) if s.mean() != 0 else None,
        'min':        round(s.min(), 4),
        'p05':        round(s.quantile(0.05), 4),
        'p25':        round(s.quantile(0.25), 4),
        'p75':        round(s.quantile(0.75), 4),
        'p95':        round(s.quantile(0.95), 4),
        'max':        round(s.max(), 4),
        'iqr':        round(s.quantile(0.75) - s.quantile(0.25), 4),
        'assimetria': round(s.skew(), 4),
        'curtose':    round(s.kurtosis(), 4),
        'normal':     stats.shapiro(s[:5000])[1] > 0.05 if len(s) >= 8 else None
    }

def correlacao_negocio(df: pd.DataFrame, target: str,
                        threshold: float = 0.3) -> pd.DataFrame:
    """Correlações com variável alvo, filtradas por threshold mínimo."""
    corr = df.select_dtypes(include='number').corr()[target]
    df_c = corr.reset_index()
    df_c.columns = ['variavel', 'correlacao']
    df_c['forca'] = df_c['correlacao'].abs().apply(
        lambda x: 'Forte' if x >= 0.7 else 'Moderada' if x >= 0.3 else 'Fraca')
    df_c['direcao'] = df_c['correlacao'].apply(
        lambda x: 'Positiva' if x > 0 else 'Negativa')
    return (df_c[df_c['variavel'] != target]
              .loc[df_c['correlacao'].abs() >= threshold]
              .sort_values('correlacao', key=abs, ascending=False))
```

---

## 2. Teste A/B — Framework Completo

```python
def ab_test_completo(grupo_a: pd.Series, grupo_b: pd.Series,
                      alpha: float = 0.05,
                      nome_a: str = 'Controle', nome_b: str = 'Tratamento') -> dict:
    """
    Teste A/B completo com seleção automática do teste correto.

    - Normal + homogêneo → t-Student (Welch)
    - Não-normal → Mann-Whitney U (não-paramétrico)
    - Retorna: p-value, significância, lift, Cohen's d, intervalo de confiança
    """
    a, b = grupo_a.dropna(), grupo_b.dropna()

    # Teste de normalidade (Shapiro para n<5000, K-S para maiores)
    def is_normal(s):
        if len(s) < 8:
            return True  # pequeno demais para testar
        test = stats.shapiro(s[:5000])
        return test[1] > 0.05

    normal_a, normal_b = is_normal(a), is_normal(b)
    levene_p = stats.levene(a, b)[1]  # homogeneidade de variâncias

    if normal_a and normal_b:
        t_stat, p_value = stats.ttest_ind(a, b, equal_var=(levene_p > 0.05))
        teste_usado = 't-Student (Welch)' if levene_p <= 0.05 else 't-Student'
    else:
        t_stat, p_value = stats.mannwhitneyu(a, b, alternative='two-sided')
        teste_usado = 'Mann-Whitney U (não-paramétrico)'

    # Cohen's d (tamanho do efeito)
    pooled_std = np.sqrt((a.std()**2 + b.std()**2) / 2)
    cohen_d    = (b.mean() - a.mean()) / pooled_std if pooled_std > 0 else 0
    efeito     = 'Pequeno' if abs(cohen_d) < 0.3 else 'Médio' if abs(cohen_d) < 0.8 else 'Grande'

    # Intervalo de confiança da diferença (95%)
    diff_mean = b.mean() - a.mean()
    se        = np.sqrt(a.std()**2 / len(a) + b.std()**2 / len(b))
    ci_low    = diff_mean - 1.96 * se
    ci_high   = diff_mean + 1.96 * se

    # Lift
    lift = (b.mean() / a.mean() - 1) * 100 if a.mean() != 0 else None

    resultado = {
        'teste':         teste_usado,
        f'n_{nome_a}':   len(a),
        f'n_{nome_b}':   len(b),
        f'media_{nome_a}': round(a.mean(), 4),
        f'media_{nome_b}': round(b.mean(), 4),
        'diferenca':     round(diff_mean, 4),
        'lift_%':        round(lift, 2) if lift else None,
        'ci_95%':        f"[{ci_low:.4f}, {ci_high:.4f}]",
        'p_value':       round(p_value, 6),
        'alpha':         alpha,
        'significativo': p_value < alpha,
        'cohen_d':       round(cohen_d, 3),
        'tamanho_efeito': efeito,
        'conclusao': (
            f"✅ SIGNIFICATIVO (p={p_value:.4f} < α={alpha}) | Lift: {lift:.1f}%"
            if p_value < alpha
            else f"❌ NÃO SIGNIFICATIVO (p={p_value:.4f} > α={alpha})"
        )
    }
    print(resultado['conclusao'])
    return resultado
```

---

## 3. KPIs Comerciais — Fórmulas e Implementação

```python
def calcular_ltv(df: pd.DataFrame, client_col: str,
                  value_col: str, date_col: str,
                  projecao_meses: int = 24) -> pd.DataFrame:
    """LTV — Lifetime Value por cliente."""
    ref = pd.to_datetime(df[date_col]).max()
    return (df.groupby(client_col)
              .agg(
                  total_gasto    = (value_col, 'sum'),
                  qtd_compras    = (value_col, 'count'),
                  primeira       = (date_col, 'min'),
                  ultima         = (date_col, 'max'),
              )
              .assign(
                  ticket_medio     = lambda x: x.total_gasto / x.qtd_compras,
                  meses_ativo      = lambda x: ((pd.to_datetime(x['ultima']) -
                                                  pd.to_datetime(x['primeira'])).dt.days / 30).clip(lower=1),
                  freq_mensal      = lambda x: x.qtd_compras / x.meses_ativo,
                  ltv_estimado     = lambda x: x.ticket_medio * x.freq_mensal * projecao_meses,
                  recencia_dias    = lambda x: (ref - pd.to_datetime(x['ultima'])).dt.days,
                  segmento_ltv     = lambda x: pd.cut(x['ltv_estimado'],
                                         bins=[0, 1000, 5000, 20000, float('inf')],
                                         labels=['Baixo', 'Medio', 'Alto', 'Premium'])
              ))


def calcular_churn_rate(df: pd.DataFrame, date_col: str,
                          client_col: str, janela_dias: int = 90) -> dict:
    """Churn Rate por inatividade (janela em dias)."""
    df[date_col] = pd.to_datetime(df[date_col])
    ref = df[date_col].max()
    ultima_compra = df.groupby(client_col)[date_col].max()
    dias_inativos = (ref - ultima_compra).dt.days

    churned = (dias_inativos > janela_dias).sum()
    total   = len(ultima_compra)
    ativos  = total - churned

    return {
        'total_clientes':  total,
        'ativos':          ativos,
        'churned':         churned,
        'churn_rate_%':    round(churned / total * 100, 2),
        'retention_rate_%': round(ativos / total * 100, 2),
        'janela_dias':     janela_dias
    }


def calcular_nps(notas: pd.Series,
                  segmento: pd.Series = None) -> dict | pd.DataFrame:
    """
    NPS — Net Promoter Score.
    Promotores: 9-10 | Passivos: 7-8 | Detratores: 0-6
    """
    def _nps(s):
        promotores = (s >= 9).mean() * 100
        detratores = (s <= 6).mean() * 100
        return {
            'nps':           round(promotores - detratores, 1),
            'promotores_%':  round(promotores, 1),
            'passivos_%':    round(100 - promotores - detratores, 1),
            'detratores_%':  round(detratores, 1),
            'total':         len(s)
        }

    if segmento is not None:
        return pd.DataFrame({s: _nps(notas[segmento == s])
                              for s in segmento.unique()}).T
    return _nps(notas)


def calcular_funil(etapas: dict) -> pd.DataFrame:
    """
    Análise de funil de conversão.
    etapas = {'Leads': 1000, 'MQL': 450, 'SQL': 200, 'Proposta': 80, 'Fechado': 30}
    """
    lista = list(etapas.items())
    rows  = []
    for i, (etapa, volume) in enumerate(lista):
        rows.append({
            'etapa':          etapa,
            'volume':         volume,
            'conv_anterior_%': round(volume / lista[i-1][1] * 100, 1) if i > 0 else 100.0,
            'conv_total_%':    round(volume / lista[0][1] * 100, 1),
            'perda':           lista[i-1][1] - volume if i > 0 else 0
        })
    return pd.DataFrame(rows)
```

---

## 4. KPIs em SQL — Templates Prontos

```sql
-- ── LTV + Segmentação SQL ────────────────────────────────────────
SELECT
    id_cliente,
    COUNT(DISTINCT id_pedido)                   AS total_pedidos,
    SUM(valor_liquido)                          AS ltv_total,
    AVG(valor_liquido)                          AS ticket_medio,
    DATEDIFF(day, MIN(data_compra), MAX(data_compra)) AS dias_ativo,
    DATEDIFF(day, MAX(data_compra), GETDATE())  AS dias_sem_compra,
    CASE
        WHEN SUM(valor_liquido) >= 20000 THEN 'PREMIUM'
        WHEN SUM(valor_liquido) >= 5000  THEN 'ALTO'
        WHEN SUM(valor_liquido) >= 1000  THEN 'MEDIO'
        ELSE 'BASICO'
    END AS segmento_ltv
FROM vendas
GROUP BY id_cliente;

-- ── Pareto 80/20 ─────────────────────────────────────────────────
WITH ranked AS (
    SELECT
        id_cliente,
        SUM(receita)                                        AS receita_cliente,
        SUM(SUM(receita)) OVER ()                           AS receita_total,
        SUM(SUM(receita)) OVER (ORDER BY SUM(receita) DESC) AS receita_acumulada
    FROM vendas GROUP BY id_cliente
)
SELECT
    id_cliente, receita_cliente,
    receita_acumulada / receita_total * 100       AS pct_acumulado,
    CASE WHEN receita_acumulada / receita_total <= 0.8
         THEN 'TOP 80%' ELSE 'CAUDA 20%' END       AS pareto
FROM ranked ORDER BY receita_cliente DESC;

-- ── Cohort de Retenção ────────────────────────────────────────────
WITH coorte AS (
    SELECT id_cliente, MIN(DATE_TRUNC('month', data_compra)) AS mes_coorte
    FROM vendas GROUP BY id_cliente
),
ativ AS (
    SELECT v.id_cliente, c.mes_coorte,
           DATE_TRUNC('month', v.data_compra) AS mes_ativo,
           DATEDIFF('month', c.mes_coorte,
                    DATE_TRUNC('month', v.data_compra)) AS offset_mes
    FROM vendas v JOIN coorte c ON v.id_cliente = c.id_cliente
)
SELECT mes_coorte, offset_mes,
       COUNT(DISTINCT id_cliente) AS ativos,
       COUNT(DISTINCT id_cliente) * 100.0 /
           FIRST_VALUE(COUNT(DISTINCT id_cliente))
               OVER (PARTITION BY mes_coorte ORDER BY offset_mes) AS retencao_pct
FROM ativ GROUP BY mes_coorte, offset_mes ORDER BY mes_coorte, offset_mes;
```

---

## 5. Benchmarks de KPI — Referência de Mercado

| KPI | Crítico | Atenção | OK | Excelente |
|---|---|---|---|---|
| Churn Mensal | >5% | 3-5% | 1-3% | <1% |
| LTV / CAC | <1x | 1-2x | 2-3x | >3x |
| Conv. Lead→Cliente | <1% | 1-2% | 2-5% | >5% |
| NPS | <0 | 0-30 | 30-70 | >70 |
| SLA Atendimento | <85% | 85-95% | 95-98% | >98% |
| Taxa de Desconto | >20% | 10-20% | 5-10% | <5% |
| Taxa de Recompra | <15% | 15-30% | 30-50% | >50% |
| Atingimento de Meta | <60% | 60-80% | 80-100% | >100% |
| FCR (atendimento) | <60% | 60-75% | 75-85% | >85% |

## Regras de Qualidade

- Sempre reportar intervalo de confiança junto com o resultado do teste A/B
- p-value < 0.05 não significa importância prática — verificar Cohen's d
- Diferenciar correlação de causalidade explicitamente em toda análise
- LTV sempre com janela de projeção declarada (ex: "LTV 24 meses")
- NPS sempre com n de respostas — amostras < 30 não são conclusivas
- Funil de vendas sempre com volume absoluto + percentual de conversão
