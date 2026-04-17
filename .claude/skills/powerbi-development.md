---
name: bi-dashboards-powerbi
description: >
  Especialista em Power BI, DAX, modelagem dimensional, performance e construção de dashboards
  analíticos. Cobre medidas DAX, colunas calculadas, star schema, tabela calendário, RLS,
  inteligência de tempo, otimização, QuickSight e storytelling visual. Use sempre que o usuário
  mencionar Power BI, DAX, medida, coluna calculada, modelo de dados, relacionamento, slicer,
  visual, drill-through, RLS, tabela calendário, QuickSight, dashboard BI, ou qualquer tarefa
  de construção de relatório analítico. Trigger para: "cria uma medida DAX", "meu modelo está
  errado", "como faço YTD", "por que meu filtro não funciona", "otimiza meu Power BI".
---

# BI Dashboards — Power BI, DAX & QuickSight

## Como Atuar
Ajudar na modelagem, criação de medidas, colunas calculadas, tabelas auxiliares, inteligência
de tempo, otimização e boas práticas de visualização. Sempre explicar o contexto de filtro
(filter context) e o raciocínio por trás das fórmulas DAX. Priorizar medidas reutilizáveis
e modelos limpos.

---

## Formato de Saída Padrão

```
1. DIAGNÓSTICO (o que está acontecendo ou o que foi pedido)
2. ESTRUTURA RECOMENDADA (modelagem, relacionamentos)
3. MEDIDAS/AJUSTES DAX (código com comentário)
4. EXPLICAÇÃO LINHA A LINHA (quando útil)
5. VALIDAÇÕES SUGERIDAS (como confirmar o resultado)
6. BOAS PRÁTICAS DE PERFORMANCE
7. RESULTADO ESPERADO
```

---

## 1. KPIs Fundamentais — DAX

```dax
// ── Receita ──────────────────────────────────────────────────────
Receita Total =
SUM(fVendas[valor_liquido])

Receita Bruta =
SUM(fVendas[valor_bruto])

Ticket Médio =
DIVIDE([Receita Total], [Qtd Pedidos], 0)

Qtd Pedidos =
COUNTROWS(fVendas)

Clientes Unicos =
DISTINCTCOUNT(fVendas[id_cliente])

Margem % =
DIVIDE([Receita Total] - [Custo Total], [Receita Total], 0)

Taxa de Desconto % =
DIVIDE(SUM(fVendas[valor_desconto]), SUM(fVendas[valor_bruto]), 0)
```

---

## 2. Inteligência de Tempo — DAX

```dax
// ── Mês Anterior ─────────────────────────────────────────────────
Receita Mes Anterior =
CALCULATE([Receita Total],
    DATEADD(dCalendario[Data], -1, MONTH))

Crescimento MoM % =
DIVIDE([Receita Total] - [Receita Mes Anterior],
       [Receita Mes Anterior], 0)

// ── Mesmo Período Ano Anterior ────────────────────────────────────
Receita SPLY =
CALCULATE([Receita Total],
    SAMEPERIODLASTYEAR(dCalendario[Data]))

Crescimento YoY % =
DIVIDE([Receita Total] - [Receita SPLY],
       [Receita SPLY], 0)

// ── Acumulados ────────────────────────────────────────────────────
Receita YTD =
TOTALYTD([Receita Total], dCalendario[Data])

Receita MTD =
TOTALMTD([Receita Total], dCalendario[Data])

Receita QTD =
TOTALQTD([Receita Total], dCalendario[Data])

// ── Rolling 12 meses ─────────────────────────────────────────────
Receita Rolling 12M =
CALCULATE([Receita Total],
    DATESINPERIOD(dCalendario[Data],
                  LASTDATE(dCalendario[Data]),
                  -12, MONTH))
```

---

## 3. Meta e Atingimento — DAX

```dax
// ── Atingimento ───────────────────────────────────────────────────
Atingimento % =
DIVIDE([Receita Total], SUM(fMetas[meta_valor]), 0)

Status Meta =
SWITCH(TRUE(),
    [Atingimento %] >= 1.0,  "Acima",
    [Atingimento %] >= 0.8,  "No Prazo",
    [Atingimento %] >= 0.6,  "Atencao",
    "Abaixo")

Gap Meta =
SUM(fMetas[meta_valor]) - [Receita Total]

// ── Projeção de fechamento (run rate) ─────────────────────────────
Projecao Fechamento =
VAR DiasDecorridos = DATEDIFF(MIN(dCalendario[Data]), TODAY(), DAY)
VAR DiasDoMes      = DAY(EOMONTH(TODAY(), 0))
RETURN DIVIDE([Receita MTD], DiasDecorridos, 0) * DiasDoMes

// ── Ícone de status (para KPI card) ──────────────────────────────
Icone Status =
SWITCH([Status Meta],
    "Acima",    "▲",
    "No Prazo", "●",
    "Atencao",  "▼",
    "Abaixo",   "✖")
```

---

## 4. Ranking e Participação — DAX

```dax
// ── Rank dentro do contexto selecionado ──────────────────────────
Rank Vendedor =
RANKX(ALLSELECTED(dVendedor[vendedor]),
      [Receita Total], , DESC, DENSE)

// ── Participação no total ─────────────────────────────────────────
Participacao % =
DIVIDE([Receita Total],
    CALCULATE([Receita Total], REMOVEFILTERS(dVendedor)), 0)

// ── Participação na regional ──────────────────────────────────────
Participacao Regional % =
DIVIDE([Receita Total],
    CALCULATE([Receita Total], REMOVEFILTERS(dVendedor[vendedor])), 0)
```

---

## 5. Star Schema Padrão

```
fVendas (FATO — tabela central)
  ├── id_data       → dCalendario[Data]       (muitos-para-um)
  ├── id_vendedor   → dVendedor[id_vendedor]  (muitos-para-um)
  ├── id_cliente    → dCliente[id_cliente]    (muitos-para-um)
  ├── id_produto    → dProduto[id_produto]    (muitos-para-um)
  ├── valor_bruto
  ├── valor_desconto
  └── valor_liquido

fMetas (FATO secundário — bridge por período/vendedor)
  ├── id_vendedor   → dVendedor
  ├── ano, mes
  └── meta_valor

DIMENSÕES:
dCalendario:  Data, Ano, Mes, NomeMes, Trimestre, DiaSemana, AnoMes, IsFDS
dVendedor:    id, nome, regional, gerente, cargo, cluster
dCliente:     id, nome, segmento, cidade, uf, porte
dProduto:     id, nome, categoria, subcategoria, marca
```

---

## 6. Tabela Calendário Completa (Power Query M)

```m
let
    DataInicio = #date(2022, 1, 1),
    DataFim    = Date.From(DateTime.FixedLocalNow()),
    TotalDias  = Duration.Days(DataFim - DataInicio) + 1,
    Datas      = List.Dates(DataInicio, TotalDias, #duration(1,0,0,0)),
    Tabela     = Table.FromList(Datas, Splitter.SplitByNothing(), {"Data"}),
    Tipagem    = Table.TransformColumnTypes(Tabela, {{"Data", type date}}),
    T1  = Table.AddColumn(Tipagem, "Ano",         each Date.Year([Data]),              Int64.Type),
    T2  = Table.AddColumn(T1,      "Mes",         each Date.Month([Data]),             Int64.Type),
    T3  = Table.AddColumn(T2,      "NomeMes",     each Date.MonthName([Data], "pt-BR"), type text),
    T4  = Table.AddColumn(T3,      "NomeMesAbr",  each Text.Start(Date.MonthName([Data], "pt-BR"), 3), type text),
    T5  = Table.AddColumn(T4,      "Trimestre",   each "T" & Text.From(Date.QuarterOfYear([Data])), type text),
    T6  = Table.AddColumn(T5,      "AnoTrimestre",each Text.From(Date.Year([Data])) & " " & "T" & Text.From(Date.QuarterOfYear([Data])), type text),
    T7  = Table.AddColumn(T6,      "AnoMes",      each Text.From(Date.Year([Data])) & "/" & Text.PadStart(Text.From(Date.Month([Data])),2,"0"), type text),
    T8  = Table.AddColumn(T7,      "DiaSemana",   each Date.DayOfWeekName([Data], "pt-BR"), type text),
    T9  = Table.AddColumn(T8,      "NumDiaSemana",each Date.DayOfWeek([Data], Day.Monday) + 1, Int64.Type),
    T10 = Table.AddColumn(T9,      "IsFimDeSemana", each Date.DayOfWeek([Data]) >= 5, type logical),
    T11 = Table.AddColumn(T10,     "SemanaAno",   each Date.WeekOfYear([Data]), Int64.Type),
    T12 = Table.AddColumn(T11,     "Dia",         each Date.Day([Data]),        Int64.Type)
in
    T12
```

---

## 7. AWS QuickSight — Calculated Fields

```sql
-- Receita Líquida (tratando nulos)
ifelse(isnull({valor_liquido}), 0, {valor_liquido})

-- Atingimento de Meta
{realizado} / nullIf({meta}, 0)

-- Status de Meta
ifelse({realizado}/{meta} >= 1, 'ACIMA',
  ifelse({realizado}/{meta} >= 0.8, 'NO_PRAZO',
    ifelse({realizado}/{meta} >= 0.6, 'ATENCAO', 'ABAIXO')))

-- Classificação de Cliente
ifelse({ltv} >= 10000, 'PREMIUM', {ltv} >= 3000, 'REGULAR', 'BASICO')

-- Crescimento MoM (usando Window Functions do QS)
({receita_atual} - {receita_anterior}) / nullIf({receita_anterior}, 0)
```

---

## Design de Dashboard — Padrão F-Pattern

```
┌─ FILTROS ─────────────────────────────────────────────┐
│  [Período ▼]  [Regional ▼]  [Vendedor ▼]  [Canal ▼]  │
├───────────────────────────────────────────────────────┤
│ [KPI Receita] [KPI Meta] [KPI Ating%] [KPI Ticket]   │
├───────────────────────────────────────────────────────┤
│ [Evolução Mensal — Realizado vs Meta]  [Top 10 Vend.] │
├───────────────────────────────────────────────────────┤
│ [Por Regional — Donut]  [Por Categoria — Barras]      │
├───────────────────────────────────────────────────────┤
│ [Tabela Detalhe com Status, Rank e Gap]               │
└───────────────────────────────────────────────────────┘

Cores semânticas:
Verde  (#2ecc71) → Acima da meta / crescimento
Vermelho (#e74c3c) → Abaixo / queda
Laranja (#f39c12) → Atenção / neutro
Azul   (#1a3a5c) → Realizado / base
```

## Regras de Qualidade
- Sempre explicar contexto de filtro (filter context) quando relevante
- Evitar DAX excessivamente complexo sem necessidade — preferir medidas simples e combinadas
- Priorizar medidas reutilizáveis e nomeação clara (`[Receita MTD]` não `[Calc1]`)
- Alertar sobre cardinalidade alta, direção de filtro incorreta e ausência de dCalendario
- Sugerir validações: tabela de apoio, matriz com total = soma das partes
- Código DAX sempre comentado com `//`
