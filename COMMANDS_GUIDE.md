# COMMANDS_GUIDE.md

Guia rápido de consulta para saber quando usar cada command do repositório.

---

## Diferença entre rules, skills, agents e commands

### `rules`
Use para padronizar **como executar** uma tarefa.  
As rules definem critérios técnicos, convenções e qualidade de entrega.

### `skills`
Use para orientar **quando e como atuar** em determinado tipo de trabalho.  
As skills funcionam como especializações reutilizáveis por domínio ou objetivo.

### `agents`
Use quando você quiser uma atuação mais focada, com um papel mais claro e uma linha de raciocínio especializada.

### `commands`
Use como **atalhos operacionais** para tarefas recorrentes.  
Commands são úteis quando você já sabe o tipo de entrega que quer e precisa acelerar a execução.

Resumo prático:
- `rules` = padrão técnico
- `skills` = especialização por tipo de trabalho
- `agents` = papel operacional especializado
- `commands` = atalho para executar mais rápido

---

## Quando usar cada command

| Command | Quando usar | Exemplos de pedido | Quando não usar |
|---|---|---|---|
| `analyze-business-problem.md` | Quando o usuário traz uma dúvida de negócio, um problema analítico ou um resultado inesperado e precisa de estruturação | “Analisa esse cenário”, “o que pode estar acontecendo?”, “quais hipóteses testar?” | Quando a tarefa já está claramente focada em SQL, Power BI, automação ou apresentação |
| `build-executive-summary.md` | Quando precisa condensar análise, projeto ou relatório em poucas linhas executivas | “Cria um sumário executivo”, “resume isso para a diretoria”, “faz um one-pager” | Quando a demanda é uma apresentação completa ou apenas revisão de texto |
| `create-corporate-presentation.md` | Quando precisa montar uma apresentação corporativa com sequência lógica, mensagem por slide e visual sugerido | “Monta os slides”, “cria outline do deck”, “mensagem por slide” | Quando a necessidade é só um resumo curto ou só design visual do slide |
| `review-sql-query.md` | Quando precisa revisar, corrigir, explicar ou otimizar uma query SQL | “Otimiza essa query”, “corrige esse SQL”, “esse join está duplicando” | Quando o problema ainda nem foi traduzido em lógica SQL |
| `design-dashboard.md` | Quando precisa estruturar um dashboard conceitualmente, com KPIs, layout, visuais e filtros | “Como estruturar esse painel?”, “qual gráfico usar?”, “me ajuda a desenhar esse dashboard” | Quando a necessidade é gerar diretamente o HTML final |
| `create-html-dashboard.md` | Quando precisa criar um dashboard web em HTML/CSS/JS, especialmente para protótipo, portfólio ou apresentação | “Cria um dashboard HTML”, “faz um painel web com filtros”, “adapta isso para HTML” | Quando a necessidade é só desenho conceitual ou recomendação visual |
| `plan-data-pipeline.md` | Quando precisa desenhar pipeline, ETL, Data Lake, camadas e fluxo ponta a ponta | “Estrutura esse pipeline”, “como montar Bronze/Silver/Gold?”, “desenha a arquitetura dos dados” | Quando a tarefa é apenas extrair dados ou apenas analisar resultado |
| `improve-professional-text.md` | Quando precisa humanizar, revisar ou melhorar textos profissionais | “Melhora esse e-mail”, “humaniza esse texto”, “reescreve esse relatório” | Quando a demanda é análise técnica, SQL ou modelagem |

---

## Atalho rápido por objetivo

| Se eu quiser... | Command mais indicado |
|---|---|
| Estruturar um problema de negócio com dados | `analyze-business-problem.md` |
| Criar um sumário executivo | `build-executive-summary.md` |
| Montar uma apresentação corporativa | `create-corporate-presentation.md` |
| Revisar ou otimizar SQL | `review-sql-query.md` |
| Desenhar um dashboard | `design-dashboard.md` |
| Criar um dashboard web em HTML | `create-html-dashboard.md` |
| Planejar pipeline e ETL | `plan-data-pipeline.md` |
| Melhorar um texto profissional | `improve-professional-text.md` |

---

## Como combinar commands na prática

Algumas tarefas funcionam melhor quando você usa mais de um command em sequência.

### Fluxo 1 — Problema de negócio até recomendação executiva
`analyze-business-problem.md` → `build-executive-summary.md`

### Fluxo 2 — Problema de negócio até apresentação
`analyze-business-problem.md` → `create-corporate-presentation.md`

### Fluxo 3 — SQL até painel
`review-sql-query.md` → `design-dashboard.md`

### Fluxo 4 — Pipeline até consumo analítico
`plan-data-pipeline.md` → `review-sql-query.md` → `design-dashboard.md`

### Fluxo 5 — Dashboard conceitual até dashboard web
`design-dashboard.md` → `create-html-dashboard.md`

### Fluxo 6 — Texto técnico até comunicação executiva
`improve-professional-text.md` → `build-executive-summary.md`

---

## Quando usar command em vez de skill

Use **command** quando:
- você já sabe o tipo de entrega que quer;
- a tarefa é recorrente;
- quer acelerar a execução com uma estrutura pronta;
- precisa de um atalho para começar mais rápido.

Use **skill** quando:
- quiser uma especialização mais rica por domínio;
- precisar de templates, frameworks e exemplos mais amplos;
- a tarefa for mais aberta ou exigir profundidade temática.

Regra prática:
- **command** para acelerar
- **skill** para especializar
- **agent** para conduzir
- **rule** para padronizar

---

## Combinações recomendadas entre commands, agents e skills

| Situação | Command | Agent complementar | Skill complementar |
|---|---|---|---|
| Diagnóstico de negócio | `analyze-business-problem.md` | `data-analyst.md` | `data-analysis.md` |
| Sumário executivo | `build-executive-summary.md` | `technical-writer.md` | `executive-summaries.md` |
| Deck executivo | `create-corporate-presentation.md` | `presentation-strategist.md` | `corporate-presentations.md` |
| Revisão de SQL | `review-sql-query.md` | `sql-optimizer.md` | `sql-development.md` |
| Estrutura de dashboard | `design-dashboard.md` | `dashboard-designer.md` | `dashboard-design.md` |
| Dashboard HTML | `create-html-dashboard.md` | `dashboard-designer.md` | `dashboard-html.md` |
| Planejamento de pipeline | `plan-data-pipeline.md` | `data-engineer.md` | `etl-data-lake.md` |
| Melhoria de texto | `improve-professional-text.md` | `technical-writer.md` | `technical-writing.md` |

---

## Observações

- Commands não substituem skills, rules ou agents; eles aceleram tarefas recorrentes.
- Quando houver dúvida, escolha o command mais próximo da **entrega final** que você quer.
- Se a tarefa estiver muito aberta, comece por skill ou agent antes do command.
- Mantenha este guia atualizado sempre que um novo command for criado.

## Estrutura atual esperada

```text
.claude/commands/
├── analyze-business-problem.md
├── build-executive-summary.md
├── create-corporate-presentation.md
├── review-sql-query.md
├── design-dashboard.md
├── create-html-dashboard.md
├── plan-data-pipeline.md
└── improve-professional-text.md
