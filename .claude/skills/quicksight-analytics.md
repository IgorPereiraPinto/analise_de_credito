---
name: quicksight-analytics
description: >
  Especialista em Amazon QuickSight para construção de dashboards analíticos, calculated fields,
  parâmetros, filtros, SPICE, datasets e comparação com Power BI. Use sempre que o usuário
  pedir ajuda com QuickSight, campo calculado, filtro de dashboard AWS, parâmetro dinâmico,
  dataset de análise, SPICE refresh, visualizações QuickSight, ou comparação entre QuickSight
  e Power BI. Trigger para: "cria campo calculado no QuickSight", "dashboard no QuickSight",
  "parâmetro no QuickSight", "compara Power BI e QuickSight", "SPICE", "QuickSight dataset",
  "análise no QuickSight", "filtro no QuickSight".
---

# QuickSight Analytics — Amazon QuickSight

## Identidade

Especialista em Amazon QuickSight para construção de dashboards analíticos, modelagem de
datasets, criação de calculated fields e comparação com Power BI. Atua com foco na pergunta
de negócio antes do visual, garantindo análises claras e reutilizáveis na plataforma AWS.

---

## Quando Usar

Use esta skill para qualquer tarefa envolvendo Amazon QuickSight: criação de dashboards,
calculated fields, parâmetros, filtros, SPICE, datasets conectados a S3/Athena/RDS, e
comparações com Power BI. Skill irmã: `bi-dashboards-powerbi` para Power BI e DAX.
Skill irmã: `aws-data-stack` para infraestrutura S3, Glue e Athena.

---

## Como Atuar

1. Entender a pergunta de negócio antes de qualquer visual
2. Sugerir estrutura de dataset e relacionamentos necessários
3. Criar calculated fields claros e reutilizáveis
4. Orientar sobre performance, SPICE e refresh quando relevante
5. Adaptar linguagem para usuário que conhece Power BI quando necessário

---

## Entradas Esperadas

Campos do dataset, KPIs, objetivo do painel, regra de negócio, erro encontrado, tipo de
visual desejado, filtros, parâmetros e layout esperado.

---

## Formato de Saída Padrão

```
1. DIAGNÓSTICO (o que está sendo pedido ou o que está errado)
2. ESTRUTURA DO DATASET (campos necessários, fonte de dados)
3. CALCULATED FIELDS (código + explicação)
4. VISUAL SUGERIDO (tipo + configuração)
5. FILTROS E PARÂMETROS (configuração e lógica)
6. VALIDAÇÕES (como confirmar o resultado)
7. BOAS PRÁTICAS (performance, SPICE, governa)
```

---

## Calculated Fields Padrão — Sintaxe QuickSight

```sql
-- ── Tratamento de nulos ────────────────────────────────────────────────
ifelse(isnull({valor_liquido}), 0, {valor_liquido})

-- ── Divisão segura (evitar divisão por zero) ──────────────────────────
ifelse({meta} = 0, NULL, {realizado} / {meta})

-- ── Atingimento de meta ───────────────────────────────────────────────
{realizado} / nullIf({meta}, 0)

-- ── Status de meta (classificação) ───────────────────────────────────
ifelse(
  {realizado}/{meta} >= 1,   'ACIMA',
  {realizado}/{meta} >= 0.8, 'NO_PRAZO',
  {realizado}/{meta} >= 0.6, 'ATENCAO',
  'ABAIXO'
)

-- ── Crescimento MoM ───────────────────────────────────────────────────
({receita_atual} - {receita_anterior}) / nullIf({receita_anterior}, 0)

-- ── Classificação de cliente por LTV ──────────────────────────────────
ifelse({ltv} >= 10000, 'PREMIUM',
  ifelse({ltv} >= 3000, 'REGULAR', 'BASICO'))

-- ── Ticket médio usando PRE_AGG ────────────────────────────────────────
sumOver({valor_liquido}, [], PRE_AGG) / countOver({id_pedido}, [], PRE_AGG)

-- ── Participação percentual (window function) ─────────────────────────
sumOver({receita}, [{regional}], PRE_AGG) /
  sumOver({receita}, [], PRE_AGG) * 100

-- ── Running total ────────────────────────────────────────────────────
sumOver({receita}, [{regional}], PRE_AGG, [{mes} ASC])

-- ── Rank dentro da dimensão ──────────────────────────────────────────
dense_rank() OVER (PARTITION BY {regional} ORDER BY {receita} DESC)
```

---

## Dataset — Fontes Suportadas e Configuração

```
FONTES COMUNS NO STACK AWS:
  AWS Athena   → dataset sobre S3 particionado (parquet, orc)
  AWS S3       → CSV ou parquet direto
  AWS RDS      → MySQL, PostgreSQL, SQL Server
  Amazon Redshift → data warehouse gerenciado

BOAS PRÁTICAS DE DATASET:
  ✅ Preferir SPICE para dashboards com < 250M linhas (performance máxima)
  ✅ Usar Direct Query apenas para dados que precisam ser em tempo real
  ✅ Criar joins no dataset, não no Athena/SQL quando possível
  ✅ Filtrar partições (year/month) logo na query base do dataset
  ✅ Criar campos calculados no dataset (não no visual) — reutilizáveis
  ✅ Nomear campos de forma clara: receita_total, atingimento_pct

CONFIGURAÇÃO DE REFRESH SPICE:
  Incremental: para tabelas com partição de data (recomendado)
  Full:        para tabelas pequenas ou sem data de carga confiável
  Frequência:  diária às 06:00 UTC (padrão corporativo)
```

---

## Parâmetros e Filtros Dinâmicos

```
PARÂMETRO SIMPLES (seleção de período):
  Tipo: DateTime | String | Integer
  Uso: filtrar visuals inteiros por um valor selecionado

PARÂMETRO COMO FILTRO CASCATA:
  Ex: Regional → Vendedor → Canal
  Configuração: Criar controle em cascata no painel de filtros

FILTRO DE RELATIVE DATE:
  Últimos 30 dias / Mês atual / Ano atual
  Uso: dateAdd(truncDate('MM', now()), -1, 'MM') para mês anterior

DICA: Parâmetros controlam visuals. Filtros de painel controlam datasets.
      Usar parâmetros para flexibilidade; filtros para restrição de dados.
```

---

## Comparativo QuickSight vs Power BI

| Recurso | Amazon QuickSight | Power BI |
|---|---|---|
| Motor de cálculo | SQL-like calculated fields | DAX (mais expressivo) |
| Modelagem | Simples (joins no dataset) | Star schema completo |
| Time intelligence | Manual (funções de data) | Nativo (TOTALYTD, SAMEPERIODLASTYEAR) |
| Contexto de filtro | Menos granular | Filter context poderoso |
| Performance | SPICE (em memória) | VertiPaq (Import mode) |
| Direct Lake | Não disponível | Disponível no Fabric |
| Integração cloud | AWS nativo | Microsoft 365 / Fabric |
| Custo | Por sessão/usuário AWS | Por capacidade/usuário |
| RLS | Row-level security via dataset | RLS via roles no modelo |
| Melhor para | Ecossistema AWS / Athena | Modelagem complexa / Microsoft |

---

## Templates de KPI no QuickSight

```
KPI CARD (Visual type: KPI):
  Primary value:  {receita_total}
  Comparison:     {receita_anterior}
  Target:         {meta_valor}
  Format:         R$ #,##0

BAR CHART (Realizado vs Meta):
  Y-axis:    {mes}
  Value:     {receita_total} (bar), {meta_valor} (reference line)
  Color by:  {status_meta}  → cores: verde/vermelho/laranja

LINE CHART (Evolução temporal):
  X-axis:    {mes}
  Value:     {receita_total}, {meta_valor}
  Small multiples: {regional}

TABLE (Detalhe por vendedor):
  Columns: nome_vendedor, regional, receita_total, meta, atingimento_pct, status
  Conditional formatting: atingimento_pct → verde/vermelho/laranja
```

---

## Regras de Qualidade

- Criar calculated fields no dataset — nunca no visual individual
- Nomear campos com clareza: `receita_total` não `campo1`
- Explicar diferenças em relação ao Power BI quando o usuário mencionar DAX
- Sempre recomendar SPICE para dashboards executivos (performance)
- Filtros de painel devem ser testados antes da publicação
- Validar totais: soma dos segmentos = total geral antes de publicar
- RLS configurado antes de compartilhar com múltiplos usuários

## Observações

Para infraestrutura AWS (S3, Glue, Athena), use `aws-data-stack`.
Para Power BI e DAX, use `bi-dashboards-powerbi`.
QuickSight e Power BI podem coexistir no mesmo stack: QuickSight para análises
self-service em AWS, Power BI para dashboards gerenciais via Fabric/Microsoft.
