---
name: customer-experience-analytics
description: >
  Especialista em análise de customer experience, operação de atendimento e qualidade com
  foco em NPS, SLA, TMA, TMO, monitoria, reincidência e causa raiz. Use sempre que o usuário
  pedir análise de atendimento, experiência do cliente, performance de operação, monitoria
  de qualidade, indicadores de suporte, ou qualquer análise de CX e contact center. Trigger
  para: "analisa NPS", "como melhorar SLA", "TMA e TMO", "monitoria de qualidade",
  "causa raiz do atendimento", "análise de reincidência", "satisfação do cliente",
  "performance da operação", "backlog de atendimento", "CX analytics".
---

# Customer Experience Analytics — CX e Operação de Atendimento

## Identidade

Especialista em análise de customer experience e operação de atendimento. Traduz indicadores
operacionais em leitura gerencial clara, hipóteses de causa raiz e recomendações práticas que
equilibram experiência do cliente e eficiência operacional.

---

## Quando Usar

Use esta skill para qualquer análise de NPS, SLA, TMA, TMO, reincidência, qualidade,
produtividade de equipe e experiência do cliente. Combina bem com `analista-dados-bi`
para análises descritivas e com `planejamento-vendas-comercial` para análises de retenção.

---

## Como Atuar

1. Entender o contexto operacional: canal, volume, equipe, segmento de cliente
2. Separar desempenho **percebido pelo cliente** (NPS, CSAT) do **desempenho operacional** (SLA, TMA, TMO)
3. Analisar indicadores em conjunto — nunca em silos
4. Identificar gargalos, causas prováveis e segmentos impactados
5. Priorizar ações com impacto simultâneo em experiência e eficiência

---

## Entradas Esperadas

Indicadores operacionais, notas de NPS/CSAT, monitorias, volume de atendimentos, tempos,
motivos de contato, filas, equipes, canais, períodos e metas acordadas.

---

## Formato de Saída Padrão

```
1. RESUMO OPERACIONAL (período, canal, volume, contexto)
2. KPIs PRINCIPAIS (NPS, SLA, TMA, TMO, reincidência, produtividade)
3. LEITURA DO CENÁRIO (o que os indicadores mostram)
4. HIPÓTESES EXPLICATIVAS (causas prováveis — declarar suposições)
5. ANÁLISES DE VALIDAÇÃO (o que investigar para confirmar)
6. RECOMENDAÇÃO PRÁTICA (ação priorizada por impacto)
7. PRÓXIMOS PASSOS (com responsável e prazo)
```

---

## Dicionário de KPIs de CX

### NPS — Net Promoter Score
```
Fórmula: NPS = % Promotores (9-10) - % Detratores (0-6)
Escala:  -100 a +100

Classificação padrão:
  Excelente:  > 75
  Muito Bom:  50 - 75   ← alertar se cair abaixo de 50
  Regular:    0 - 49
  Crítico:    < 0

Análise recomendada:
  - Distribuição de notas (histograma)
  - NPS por canal, motivo, equipe e período
  - Textuais dos detratores (análise de causa raiz qualitativa)
  - Correlação NPS vs TMA, vs reincidência, vs agente
```

### SLA — Service Level Agreement
```
Fórmula: SLA = atendimentos dentro do tempo acordado / total de atendimentos * 100
Meta típica: ≥ 95% (alertar se < 95%, crítico se < 90%)

Análise recomendada:
  - SLA por canal, fila, horário e dia da semana
  - Distribuição do tempo de espera (percentis P50, P80, P95)
  - Picos de violação (data, horário, equipe)
  - Correlação com backlog e ausências
```

### TMA — Tempo Médio de Atendimento
```
Fórmula: TMA = soma do tempo de atendimento / qtd atendimentos
         (inclui tempo de conversa + tempo de hold)

Nota: TMA não inclui tempo pós-atendimento (ACW)
      TMA alto pode indicar: complexidade, falta de treinamento, tools ruins

Análise recomendada:
  - TMA por agente, canal, motivo e período
  - Distribuição (histograma) — identificar outliers
  - Correlação TMA vs NPS, TMA vs reincidência
```

### TMO — Tempo Médio Operacional
```
Fórmula: TMO = TMA + ACW (After Call Work — tempo pós-atendimento)
         TMO > TMA sempre (inclui tabulação, registros, etc.)

Nota: TMO é o custo real por contato para a operação
      Diferença (TMO - TMA) mede eficiência do processo pós-contato

Análise recomendada:
  - TMO por agente e equipe
  - Benchmark interno: TMO mediana vs melhor quartil
```

### Taxa de Reincidência
```
Fórmula: % atendimentos do mesmo cliente em [janela de tempo] / total de atendimentos
Janela padrão: 7 dias ou 30 dias (definir com o negócio)
Meta típica: < 15% (alertar se > 20%)

Análise recomendada:
  - Reincidência por motivo, canal e produto
  - Motivos mais frequentes de retorno
  - Identificar "loop de contato" — cliente que retorna 3+ vezes
```

### FCR — First Contact Resolution
```
Fórmula: % atendimentos resolvidos no primeiro contato / total
Meta típica: > 80%

Nota: FCR alto + reincidência baixa = boa qualidade de resolução
      FCR baixo pode indicar: processo inadequado, falta de autonomia, produto complexo
```

---

## Análise de Causa Raiz — Framework 5 Camadas

```
SINTOMA:       NPS caiu 15 pontos em 30 dias

CAMADA 1 (O quê):    Qual métrica piorou? — NPS, SLA ou TMA?
CAMADA 2 (Onde):     Qual canal, fila ou equipe concentra o problema?
CAMADA 3 (Quando):   O problema é constante ou pontual? Qual evento coincidiu?
CAMADA 4 (Quem):     Há agentes ou equipes específicas com padrão diferente?
CAMADA 5 (Por quê):  Qual a causa raiz? — processo, ferramenta, produto, treinamento?

VALIDAÇÃO:
  - Compare o período de queda com mudanças de processo, produto, equipe ou sistema
  - Analise textuais de NPS dos detratores do período
  - Verifique TMA, SLA e reincidência no mesmo período
  - Ouça gravações ou monitorias do canal/período impactado
```

---

## Análise em Python — KPIs de CX

```python
import pandas as pd
import numpy as np

def calcular_nps(df: pd.DataFrame, nota_col: str, segmento_col: str = None) -> pd.DataFrame:
    """Calcula NPS global e por segmento."""
    def _nps(series):
        promotores  = (series >= 9).mean() * 100
        detratores  = (series <= 6).mean() * 100
        passivos    = 100 - promotores - detratores
        return pd.Series({
            'nps':           round(promotores - detratores, 1),
            'promotores_%':  round(promotores, 1),
            'passivos_%':    round(passivos, 1),
            'detratores_%':  round(detratores, 1),
            'total_respostas': len(series)
        })

    if segmento_col:
        return df.groupby(segmento_col)[nota_col].apply(_nps).reset_index()
    return _nps(df[nota_col]).to_frame().T

def calcular_sla(df: pd.DataFrame, tempo_espera_col: str,
                 meta_segundos: int = 60, janela_pct: float = 0.95) -> dict:
    """Calcula aderência de SLA e distribuição de tempos de espera."""
    total     = len(df)
    dentro_sla = (df[tempo_espera_col] <= meta_segundos).sum()
    return {
        'sla_%':           round(dentro_sla / total * 100, 2),
        'dentro_sla':      int(dentro_sla),
        'fora_sla':        int(total - dentro_sla),
        'meta_segundos':   meta_segundos,
        'p50_espera':      round(df[tempo_espera_col].quantile(0.50), 1),
        'p80_espera':      round(df[tempo_espera_col].quantile(0.80), 1),
        'p95_espera':      round(df[tempo_espera_col].quantile(0.95), 1),
        'max_espera':      round(df[tempo_espera_col].max(), 1),
        'status':          'OK' if dentro_sla / total >= janela_pct else 'ALERTA'
    }

def calcular_reincidencia(df: pd.DataFrame, cliente_col: str,
                          data_col: str, janela_dias: int = 7) -> pd.DataFrame:
    """Identifica clientes que retornaram em menos de N dias."""
    df = df.copy().sort_values([cliente_col, data_col])
    df['contato_anterior'] = df.groupby(cliente_col)[data_col].shift(1)
    df['dias_desde_ultimo'] = (df[data_col] - df['contato_anterior']).dt.days
    df['reincidencia'] = (df['dias_desde_ultimo'] <= janela_dias) & df['dias_desde_ultimo'].notna()

    taxa = df['reincidencia'].mean() * 100
    print(f"Taxa de reincidência ({janela_dias}d): {taxa:.1f}%")
    return df

def ranking_motivos_detratores(df: pd.DataFrame, nota_col: str,
                                motivo_col: str, top_n: int = 10) -> pd.DataFrame:
    """Motivos mais frequentes entre detratores (nota <= 6)."""
    detratores = df[df[nota_col] <= 6]
    return (detratores.groupby(motivo_col)
                      .agg(qtd=('motivo_col', 'count'))
                      .assign(pct=lambda x: x.qtd / len(detratores) * 100)
                      .sort_values('qtd', ascending=False)
                      .head(top_n))
```

---

## Análise em SQL — Operação de Atendimento

```sql
-- KPIs de CX consolidados por período e canal
SELECT
    canal,
    MONTH(data_atendimento)                                    AS mes,
    COUNT(*)                                                   AS total_atendimentos,
    AVG(tempo_atendimento_seg)                                 AS tma_segundos,
    AVG(tempo_operacional_seg)                                 AS tmo_segundos,
    SUM(CASE WHEN tempo_espera_seg <= 60 THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*)                                     AS sla_pct,
    AVG(nota_nps)                                              AS nota_media,
    SUM(CASE WHEN nota_nps >= 9 THEN 1 ELSE 0 END) * 100.0 / COUNT(*)
        - SUM(CASE WHEN nota_nps <= 6 THEN 1 ELSE 0 END) * 100.0 / COUNT(*)
                                                               AS nps,
    SUM(CASE WHEN reincidencia_7d = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*)
                                                               AS taxa_reincidencia_pct
FROM atendimentos
WHERE data_atendimento >= '2024-01-01'
GROUP BY canal, MONTH(data_atendimento)
ORDER BY mes, canal;
```

---

## Regras de Qualidade

- Sempre diferenciar TMA e TMO — nunca tratar como sinônimos
- NPS e SLA são indicadores complementares — analisá-los juntos
- Declarar hipóteses de causa raiz antes de afirmar a causa
- Correlacionar NPS com TMA, SLA e reincidência — não analisar em silos
- Alertar automaticamente: NPS < 50, SLA < 95%, reincidência > 20%
- Análise de reincidência exige definição da janela temporal com o negócio
- Monitoria de qualidade: mínimo de 10% de sampling das interações
- Segmentar sempre por canal, equipe e motivo — nunca só o global

## Observações

Esta skill cobre indicadores operacionais de CX. Para análise de churn, LTV e RFM de
clientes comerciais, use `planejamento-vendas-comercial`. Para análises de NPS em
pesquisas de produto ou marketing, adapte o framework desta skill ao contexto.
