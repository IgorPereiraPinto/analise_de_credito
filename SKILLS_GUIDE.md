# SKILLS_GUIDE.md

Guia rápido de consulta para saber quando usar cada skill do repositório.

---

## Quando usar cada skill

| Skill | Quando usar | Exemplos de pedido | Quando não usar |
|---|---|---|---|
| `data-analysis.md` | Quando o ponto de partida é um problema de negócio, uma base ou uma pergunta analítica | “Analisa esses dados”, “o que está acontecendo aqui?”, “quais hipóteses testar?” | Quando você já sabe que precisa de SQL, DAX ou apresentação específica |
| `business-intelligence.md` | Quando precisa definir KPIs, visão gerencial, estrutura de dashboard e monitoramento recorrente | “Quais KPIs devo acompanhar?”, “como estruturar esse painel?” | Quando a demanda é técnica de Power BI ou DAX |
| `sales-planning.md` | Quando a análise é de vendas, metas, forecast, carteira, conversão e produtividade comercial | “Compara meta vs realizado”, “faz forecast”, “analisa a carteira” | Quando o tema é compras, CX ou outro domínio fora do comercial |
| `procurement.md` | Quando o tema envolve compras, fornecedores, spend, saving, budget e lead time | “Analisa spend vs budget”, “onde está o maior desvio de compras?” | Quando o tema é performance comercial ou atendimento |
| `sql-development.md` | Quando precisa escrever, revisar, otimizar ou explicar SQL | “Cria uma query”, “otimiza esse SQL”, “esse join está duplicando” | Quando a discussão é mais conceitual de KPI ou apresentação |
| `python-for-data.md` | Quando precisa de código Python para análise, EDA, manipulação e automação de dados | “Cria um script em pandas”, “faz EDA”, “automatiza essa planilha” | Quando a demanda principal é modelagem de ML ou forecast |
| `powerbi-development.md` | Quando precisa de medidas DAX, modelagem, contexto de filtro, tabela calendário e performance no Power BI | “Cria uma medida DAX”, “por que o filtro não funciona?”, “otimiza meu Power BI” | Quando a necessidade é BI conceitual, não implementação |
| `excel-analytics.md` | Quando a demanda envolve Excel, fórmulas, VBA, Power Query no Excel e dashboards em planilha | “Cria fórmula”, “faz uma macro”, “Power Query no Excel” | Quando o melhor caminho já é Python, SQL ou Power BI |
| `fabric-analytics.md` | Quando o foco é uso prático do Microsoft Fabric no dia a dia analítico | “Como organizar isso no Fabric?”, “uso Lakehouse ou Warehouse aqui?” | Quando a discussão é mais ampla de arquitetura cloud |
| `fabric-azure-analytics.md` | Quando a demanda é arquitetura analítica no ecossistema Microsoft | “Desenha uma arquitetura no Fabric/Azure”, “Fabric vs AWS” | Quando você só quer implementar uma análise prática no Fabric |
| `quicksight-analytics.md` | Quando precisa montar dashboard, calculated fields, parâmetros e filtros no Amazon QuickSight | “Cria campo calculado no QuickSight”, “como uso SPICE?” | Quando a ferramenta é Power BI |
| `dashboard-design.md` | Quando precisa escolher visuais, organizar layout e estruturar a comunicação visual de um dashboard | “Qual gráfico usar?”, “como estruturar esse dashboard?” | Quando você já quer o código HTML pronto |
| `dashboard-html.md` | Quando quer criar um dashboard web em HTML/CSS/JS/Chart.js, especialmente para portfólio, protótipo executivo ou apresentação | “Cria um dashboard HTML”, “adapta esse Power BI para web” | Quando o pedido é apenas desenho conceitual, sem código |
| `executive-storytelling.md` | Quando precisa transformar análise em narrativa executiva | “Qual a história desses dados?”, “transforma isso em narrativa” | Quando você quer só um resumo curto ou um deck completo |
| `executive-summaries.md` | Quando precisa de resumo executivo, one-pager, abertura de relatório ou síntese para diretoria | “Cria um sumário executivo”, “resume isso para a diretoria” | Quando precisa da estrutura completa de slides |
| `corporate-presentations.md` | Quando precisa estruturar uma apresentação corporativa completa | “Monta os slides”, “cria outline da apresentação”, “mensagem por slide” | Quando a demanda é só texto curto ou só design visual |
| `slide-design.md` | Quando o foco é visual do slide: layout, hierarquia, tipografia e distribuição de conteúdo | “Melhora esse slide”, “como organizar esse conteúdo no PPT?” | Quando a apresentação ainda nem foi estruturada |
| `technical-writing.md` | Quando precisa humanizar textos, melhorar e-mails, relatórios, mensagens profissionais e escrita executiva | “Humaniza esse texto”, “melhora esse e-mail”, “deixa mais natural” | Quando a demanda é apresentação em slides ou sumário executivo estruturado |
| `automations.md` | Quando precisa mapear processo e propor automação com Power Automate, Power Apps e integrações | “Automatiza esse processo”, “cria um fluxo no Power Automate” | Quando o tema é só análise de dados sem automação |
| `prompt-engineering.md` | Quando precisa criar, melhorar ou estruturar prompts e instruções para IA | “Melhora esse prompt”, “cria um prompt para Claude”, “por que a IA não entendeu?” | Quando a necessidade é o conteúdo final, não a instrução |
| `skill-authoring.md` | Quando precisa criar ou revisar uma skill formal para Claude Code ou Claude.ai | “Transforma isso em skill”, “cria um SKILL.md” | Quando a demanda é só um prompt simples |
| `customer-experience-analytics.md` | Quando o tema envolve NPS, SLA, TMA, TMO, reincidência, monitoria e operação de atendimento | “Analisa NPS”, “como melhorar SLA?”, “causa raiz do atendimento” | Quando o contexto é comercial, procurement ou financeiro |
| `machine-learning.md` | Quando precisa de previsão, classificação, segmentação, churn, propensão, anomalias ou ML aplicado ao negócio | “Cria um modelo preditivo”, “faz forecast”, “segmenta clientes” | Quando a necessidade é só análise descritiva ou diagnóstica |
| `api-data-extraction.md` | Quando precisa consumir API, autenticar, paginar, tratar JSON e trazer dados para análise | “Extrai dados da API”, “como autenticar nesse endpoint?”, “transforma JSON em DataFrame” | Quando a origem é banco, Excel ou SharePoint sem API |
| `data-extraction.md` | Quando a necessidade é extrair dados de várias fontes em pipelines, não só API | “Puxa do Salesforce”, “lê do S3”, “extrai do SharePoint” | Quando a necessidade é só consumir endpoint REST simples |
| `etl-data-lake.md` | Quando precisa estruturar pipeline ETL, Bronze/Silver/Gold, qualidade de dados e SCD2 | “Cria um pipeline ETL”, “estrutura um Data Lake”, “como tratar duplicatas?” | Quando a demanda é apenas extração ou apenas visualização |
| `aws-data-stack.md` | Quando a solução envolve S3, Glue, Athena, Lambda, catálogo e arquitetura AWS de dados | “Cria um Glue Job”, “query no Athena”, “arquitetura no AWS” | Quando o stack é Microsoft Fabric ou Azure |
| `dbt-analytics.md` | Quando a transformação SQL versionada será feita em dbt | “Cria modelo dbt”, “faz snapshot SCD2”, “como estruturar o projeto dbt?” | Quando você está só escrevendo SQL fora de dbt |
| `statistics-business-kpis.md` | Quando precisa calcular KPI, estatística aplicada, teste A/B, significância, correlação e benchmark de métrica | “Calcula LTV”, “isso é significativo?”, “faz teste A/B” | Quando a necessidade principal é SQL, Power BI ou apresentação |
| `git-dataops.md` | Quando o tema é Git, versionamento, branches, commits, pre-commit, CI/CD e boas práticas de engenharia para dados | “Como faço o commit?”, “estrutura de branch”, “CI/CD para dados” | Quando a demanda é analítica ou de dashboard |
| `figma.md` | Quando precisa estruturar wireframes, interfaces analíticas, protótipos e handoff visual no Figma | “Cria um wireframe”, “me ajuda no Figma”, “estrutura essa tela”, “organiza o layout do dashboard” | Quando a demanda é apenas análise, SQL ou implementação técnica sem camada visual |

---

## Atalho rápido por objetivo

| Se eu quiser... | Skill mais indicada |
|---|---|
| Entender um problema de negócio com dados | `data-analysis.md` |
| Definir KPIs e visão gerencial | `business-intelligence.md` |
| Fazer análise comercial | `sales-planning.md` |
| Fazer análise de compras | `procurement.md` |
| Escrever SQL | `sql-development.md` |
| Escrever Python para dados | `python-for-data.md` |
| Resolver DAX ou Power BI | `powerbi-development.md` |
| Resolver Excel ou Power Query no Excel | `excel-analytics.md` |
| Trabalhar com Fabric no uso prático | `fabric-analytics.md` |
| Desenhar arquitetura Fabric ou Azure | `fabric-azure-analytics.md` |
| Trabalhar com QuickSight | `quicksight-analytics.md` |
| Escolher visuais e layout de dashboard | `dashboard-design.md` |
| Criar dashboard web em HTML | `dashboard-html.md` |
| Transformar análise em narrativa | `executive-storytelling.md` |
| Criar sumário executivo | `executive-summaries.md` |
| Montar apresentação corporativa | `corporate-presentations.md` |
| Melhorar o visual de slides | `slide-design.md` |
| Humanizar textos e e-mails | `technical-writing.md` |
| Automatizar processos | `automations.md` |
| Melhorar prompts | `prompt-engineering.md` |
| Criar novas skills | `skill-authoring.md` |
| Analisar operação ou CX | `customer-experience-analytics.md` |
| Fazer ML ou forecast | `machine-learning.md` |
| Extrair dados de API | `api-data-extraction.md` |
| Extrair dados de múltiplas fontes | `data-extraction.md` |
| Criar ETL e Data Lake | `etl-data-lake.md` |
| Trabalhar com stack AWS de dados | `aws-data-stack.md` |
| Trabalhar com dbt | `dbt-analytics.md` |
| Aplicar estatística e KPIs | `statistics-business-kpis.md` |
| Organizar Git e DataOps | `git-dataops.md` |
| Estruturar wireframe ou protótipo no Figma | `figma.md` |

---

## Observações

- Algumas skills são complementares e podem ser usadas em sequência.

Exemplos:
- `data-analysis.md` → `executive-storytelling.md` → `corporate-presentations.md`
- `data-extraction.md` → `etl-data-lake.md` → `powerbi-development.md`
- `business-intelligence.md` → `dashboard-design.md` → `dashboard-html.md`

- Quando houver dúvida entre duas skills, prefira:
  - a skill mais conceitual para pensar
  - a skill mais técnica para implementar
