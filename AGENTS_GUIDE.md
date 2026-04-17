# AGENTS_GUIDE.md

Guia rápido de consulta para saber quando usar cada agent do repositório.

---

## Diferença entre rules, skills e agents

### `rules`
Use para padronizar **como executar** uma tarefa.  
As rules definem critérios técnicos, convenções e qualidade de entrega.

### `skills`
Use para orientar **quando e como atuar** em determinado tipo de trabalho.  
As skills funcionam como especializações reutilizáveis por domínio ou objetivo.

### `agents`
Use quando você quiser uma atuação mais focada, com um papel mais claro e uma linha de raciocínio especializada para um tipo específico de tarefa.

Resumo prático:
- `rules` = padrão técnico
- `skills` = especialização por tipo de trabalho
- `agents` = papel operacional especializado

---

## Quando usar cada agent

| Agent | Quando usar | Exemplos de pedido | Quando não usar |
|---|---|---|---|
| `data-analyst.md` | Quando a demanda começa com um problema de negócio, dúvida analítica ou necessidade de leitura de cenário | “Analisa esse resultado”, “o que pode estar acontecendo?”, “quais hipóteses testar?” | Quando a demanda já está claramente focada em SQL, Power BI ou automação |
| `bi-analyst.md` | Quando precisa estruturar visão gerencial, KPIs, dashboards e leitura executiva de indicadores | “Quais KPIs devo acompanhar?”, “como estruturar esse painel?”, “como organizar essa visão de BI?” | Quando a tarefa é implementação técnica em DAX ou código |
| `data-engineer.md` | Quando precisa desenhar pipeline, ETL, Data Lake, ingestão, rastreabilidade e estrutura técnica dos dados | “Estrutura esse pipeline”, “como organizar Bronze/Silver/Gold?”, “qual arquitetura usar para esses dados?” | Quando a tarefa é só análise de negócio ou comunicação executiva |
| `sql-optimizer.md` | Quando precisa escrever, revisar, depurar ou otimizar SQL | “Otimiza essa query”, “esse join está duplicando”, “cria um SQL para esse KPI” | Quando a tarefa é mais conceitual ou não envolve banco |
| `technical-writer.md` | Quando precisa melhorar texto, documentação, e-mails, relatórios ou README | “Humaniza esse texto”, “melhora esse e-mail”, “reescreve essa explicação técnica” | Quando a necessidade principal é análise de dados ou modelagem |
| `powerbi-specialist.md` | Quando a tarefa envolve DAX, modelagem, contexto de filtro, tabela calendário ou performance no Power BI | “Cria essa medida”, “meu filtro não funciona”, “otimiza esse relatório” | Quando a necessidade é BI conceitual ou visual sem implementação |
| `dashboard-designer.md` | Quando precisa estruturar painel, escolher gráficos, organizar layout e pensar a UX analítica | “Como desenhar esse dashboard?”, “qual gráfico usar?”, “como organizar os visuais?” | Quando a necessidade é o código HTML final ou DAX técnico |
| `ml-analyst.md` | Quando precisa pensar em forecasting, churn, classificação, segmentação, baseline e avaliação de modelo | “Faz forecast”, “qual modelo usar?”, “como prever churn?” | Quando a análise é só descritiva/diagnóstica, sem componente preditivo |
| `automation-architect.md` | Quando precisa mapear processo e desenhar automações ponta a ponta com Power Platform, APIs ou integrações | “Automatiza esse processo”, “cria um fluxo”, “como integrar SharePoint com SQL?” | Quando a tarefa é só análise de dados sem automação |
| `presentation-strategist.md` | Quando precisa estruturar uma apresentação, organizar narrativa de slides e preparar material para gestão ou diretoria | “Monta os slides”, “qual a ordem da apresentação?”, “transforma essa análise em deck” | Quando a tarefa é só resumo executivo curto ou design visual do slide |

---

## Atalho rápido por objetivo

| Se eu quiser... | Agent mais indicado |
|---|---|
| Entender um problema de negócio com dados | `data-analyst.md` |
| Estruturar KPIs e visão gerencial | `bi-analyst.md` |
| Desenhar pipeline e arquitetura de dados | `data-engineer.md` |
| Escrever ou otimizar SQL | `sql-optimizer.md` |
| Melhorar texto e documentação | `technical-writer.md` |
| Resolver DAX e Power BI | `powerbi-specialist.md` |
| Desenhar dashboard e escolher visuais | `dashboard-designer.md` |
| Construir solução preditiva ou forecast | `ml-analyst.md` |
| Desenhar automação de processo | `automation-architect.md` |
| Estruturar apresentação executiva | `presentation-strategist.md` |

---

## Como combinar agents na prática

Algumas tarefas funcionam melhor quando você pensa em sequência.

### Fluxo 1 — Problema de negócio até apresentação
`data-analyst.md` → `executive-storytelling.md` (skill) → `presentation-strategist.md`

### Fluxo 2 — KPI até dashboard
`bi-analyst.md` → `dashboard-designer.md` → `powerbi-specialist.md` ou `dashboard-html.md` (skill)

### Fluxo 3 — Fonte de dados até consumo analítico
`data-engineer.md` → `sql-optimizer.md` → `bi-analyst.md`

### Fluxo 4 — Processo manual até automação
`data-analyst.md` → `automation-architect.md` → `technical-writer.md`

### Fluxo 5 — Modelo preditivo com tradução executiva
`ml-analyst.md` → `data-analyst.md` → `presentation-strategist.md`

---

## Quando usar agent em vez de skill

Use **agent** quando:
- você quiser um papel mais definido;
- a tarefa exigir uma linha de raciocínio especializada;
- você quiser delegar a “condução” da tarefa a uma persona operacional mais clara.

Use **skill** quando:
- quiser ativar um domínio ou tipo de trabalho específico;
- precisar de templates, estruturas e regras de atuação;
- quiser apoio mais modular e reutilizável.

Regra prática:
- **agent** para conduzir
- **skill** para especializar
- **rule** para padronizar

---

## Combinações recomendadas entre agents e skills

| Situação | Agent | Skill complementar |
|---|---|---|
| Diagnóstico de negócio | `data-analyst.md` | `data-analysis.md` |
| Estruturação de painel | `bi-analyst.md` | `business-intelligence.md` |
| Query e performance | `sql-optimizer.md` | `sql-development.md` |
| Pipeline e ETL | `data-engineer.md` | `etl-data-lake.md` |
| Power BI e DAX | `powerbi-specialist.md` | `powerbi-development.md` |
| Dashboard executivo | `dashboard-designer.md` | `dashboard-design.md` |
| Forecast e modelo preditivo | `ml-analyst.md` | `machine-learning.md` |
| Automação de processo | `automation-architect.md` | `automations.md` |
| Deck executivo | `presentation-strategist.md` | `corporate-presentations.md` |
| Documentação e texto | `technical-writer.md` | `technical-writing.md` |

---

## Observações

- Agents não substituem skills e rules; eles funcionam melhor em conjunto.
- Quando houver dúvida, comece pelo agent mais próximo do objetivo principal da tarefa.
- Se a tarefa misturar análise, implementação e comunicação, você pode combinar mais de um agent em sequência.
- Mantenha este guia atualizado sempre que um novo agent for criado.

## Estrutura atual esperada

```text
.claude/agents/
├── data-analyst.md
├── bi-analyst.md
├── data-engineer.md
├── sql-optimizer.md
├── technical-writer.md
├── powerbi-specialist.md
├── dashboard-designer.md
├── ml-analyst.md
├── automation-architect.md
└── presentation-strategist.md
