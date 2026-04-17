# credito_bba

Pipeline de dados ponta a ponta para análise de portfólio de crédito corporativo.

Construído a partir de um case técnico real para a posição de Analista de Dados no Crédito IBBA (Itaú BBA). Cobre o fluxo completo: Excel → Python ETL → SQL em 3 camadas → Views analíticas → Dashboard executivo.

---

## O que este repositório resolve

O desafio era analisar um portfólio de crédito corporativo com 5 tabelas relacionadas:
clientes, operações, ratings, limites e exposições. O objetivo era transformar dados brutos em
KPIs acionáveis para o Comitê de Crédito.

Este repositório documenta, organiza e reproduz todo o processo, do dado bruto ao painel executivo.

---

## Fluxo do pipeline

```text
Excel (dados_sinteticos_case.xlsx)
  │
  ▼
[Python ETL]
  01_extract.py        → lê o Excel, valida abas e schema mínimo
  02_clean.py          → padroniza tipos, trata nulos, normaliza strings
  03_validate.py       → aplica regras de negócio e gera relatório de qualidade
  04_export.py         → exporta CSVs prontos para carga no banco
  │
  ▼
[SQL — Camada RAW]
  Dado bruto carregado sem transformação
  SQL Server: tabelas relacionais com FK e PK
  Athena:     tabelas externas (Parquet no S3)
  │
  ▼
[SQL — Camada STAGE]
  Limpeza, tipagem, enriquecimento e deduplicação
  Joins entre tabelas, campos calculados, flags de qualidade
  │
  ▼
[SQL — Camada DW]
  Modelo de fatos e dimensões
  Views analíticas com KPIs calculados
  Camada semântica pronta para BI (Power BI / QuickSight)
  │
  ▼
[Dashboard HTML]
  dashboard_credito_bba.html — painel single-file, portável
```

---

## Estrutura do repositório

```text
credito_bba/
│
├── README.md                          ← você está aqui
├── .env.example                       ← variáveis de ambiente (copie para .env)
├── requirements.txt                   ← dependências de produção
├── requirements-dev.txt               ← dependências de desenvolvimento
├── .gitignore
│
├── data/
│   ├── raw/                           ← dado bruto original (não versionado)
│   └── processed/                     ← CSVs exportados pelo Python ETL
│
├── python/
│   ├── README.md                      ← guia dos scripts e ordem de execução
│   ├── 01_extract.py                  ← leitura e validação do Excel
│   ├── 02_clean.py                    ← padronização e limpeza
│   ├── 03_validate.py                 ← validações de negócio e qualidade
│   └── 04_export.py                   ← exportação para carga no banco
│
├── sql/
│   ├── sqlserver/                     ← implementação SQL Server
│   │   ├── 00_ddl.sql                 ← criação de banco, tabelas e índices
│   │   ├── 01_raw_insert.sql          ← carga dos dados brutos
│   │   ├── 02_stage_views.sql         ← camada de limpeza e enriquecimento
│   │   ├── 03_dw_views.sql            ← modelo dimensional e KPIs
│   │   ├── 04_queries_analiticas.sql  ← queries do case (Q2.1 a Q2.5)
│   │   └── 05_views_kpi.sql           ← camada semântica para Power BI
│   │
│   └── athena/                        ← implementação Athena (AWS)
│       ├── 00_ddl_external.sql        ← tabelas externas (S3 + Glue)
│       ├── 01_raw_s3.sql              ← referências ao dado no S3
│       ├── 02_stage_views.sql         ← views de limpeza e enriquecimento
│       ├── 03_dw_views.sql            ← modelo dimensional e KPIs
│       ├── 04_queries_analiticas.sql  ← queries do case adaptadas para Athena
│       └── 05_views_kpi.sql           ← camada semântica para QuickSight
│
├── dashboards/
│   └── dashboard_credito_bba.html     ← painel executivo HTML/Chart.js
│
├── presentations/
│   └── plano_implementacao_credito_bba.pptx
│
├── docs/
│   ├── arquitetura.md                 ← desenho do pipeline e decisões técnicas
│   ├── dicionario_de_dados.md         ← todas as tabelas, campos e tipos
│   ├── regras_de_negocio.md           ← KPIs, benchmarks e lógica de risco
│   ├── como_executar.md               ← passo a passo para rodar localmente
│   └── faq_reutilizacao.md            ← como adaptar para outro case de crédito
│
└── roadmap/                           ← eixo didático do projeto
    ├── 01_visao_geral_do_projeto.md
    ├── 02_entendimento_do_case.md
    ├── 03_analise_da_base_excel.md
    ├── 04_arquitetura_do_pipeline.md
    ├── 05_etl_extracao.md
    ├── 06_etl_padronizacao_e_validacoes.md
    ├── 07_modelagem_raw.md
    ├── 08_modelagem_stage.md
    ├── 09_modelagem_dw.md
    ├── 10_sql_server_vs_athena.md
    ├── 11_kpis_e_views_analiticas.md
    ├── 12_dashboard_e_storytelling.md
    ├── 13_apresentacao_executiva.md
    └── 14_como_reutilizar_o_projeto.md
```

---

## Pré-requisitos

- Python 3.11+
- SQL Server Developer Edition (para execução local) ou acesso à AWS (Athena)
- Arquivo `dados_sinteticos_case.xlsx` na pasta `data/raw/`

```bash
# 1. Clone e acesse o projeto
git clone https://github.com/IgorPereiraPinto/credito_bba.git
cd credito_bba

# 2. Crie o ambiente virtual
python -m venv .venv
source .venv/bin/activate   # Linux/Mac
.venv\Scripts\activate      # Windows

# 3. Instale as dependências
pip install -r requirements.txt

# 4. Configure o ambiente
cp .env.example .env
# edite o .env com seus dados de conexão

# 5. Execute o ETL Python (na ordem)
python python/01_extract.py
python python/02_clean.py
python python/03_validate.py
python python/04_export.py

# 6. Execute o SQL na ordem indicada em sql/sqlserver/ ou sql/athena/
```

Instruções detalhadas estão em [docs/como_executar.md](docs/como_executar.md).

---

## Domínio do case

**Tabelas:** `clientes`, `operacoes`, `ratings`, `limites`, `exposicoes`

**KPIs principais calculados:**

- Exposição total, garantida e descoberta por cliente e subsetor
- Taxa de utilização de limite (meta: 60-75%, alerta: >85%)
- Rating ponderado por segmento (escala 0-1000)
- Probabilidade de default (PD 12m) por cliente
- Concentração de exposição por subsetor (limite regulatório: <15%)
- Clientes em deterioração de rating (2+ meses consecutivos)
- Matriz de risco combinado: utilização + exposição descoberta

**Benchmarks aplicados:**

- Rating ponderado: Excelente ≥850 | Atenção <800 | Crítico <650
- Utilização de limite: Ideal 60-75% | Alerta >85%
- Exposição descoberta: Meta <30% | Atenção >40%
- Concentração por subsetor: Monitoramento >10% | Limite regulatório >15%

---

## Dualidade SQL Server / Athena

O projeto mantém duas implementações paralelas e funcionais:

| Aspecto              | SQL Server                    | Athena (AWS)                        |
|----------------------|-------------------------------|-------------------------------------|
| Armazenamento        | Tabelas relacionais locais    | Tabelas externas (Parquet no S3)    |
| Integridade          | FK e PK declaradas            | Garantida pelo ETL (sem FK nativas) |
| Sintaxe de data      | `FORMAT()`, `GETDATE()`       | `DATE_FORMAT()`, `CURRENT_DATE`     |
| Desvio padrão        | `STDEV()`                     | `STDDEV()`                          |
| Paginação            | `TOP N`                       | `LIMIT N`                           |
| Views                | `CREATE OR ALTER VIEW`        | `CREATE OR REPLACE VIEW`            |
| BI conectado         | Power BI                      | Amazon QuickSight                   |

Veja o guia completo em [roadmap/10_sql_server_vs_athena.md](roadmap/10_sql_server_vs_athena.md).

---

## Como reutilizar em outro case de crédito

Este repositório foi construído para ser portável. Para adaptar a outro contexto:

1. Substitua o Excel em `data/raw/` pela nova fonte
2. Ajuste os schemas em `python/01_extract.py` (nomes de abas e colunas)
3. Atualize os benchmarks em `docs/regras_de_negocio.md`
4. Re-execute o pipeline na ordem indicada no `roadmap/`

Guia completo de reutilização: [roadmap/14_como_reutilizar_o_projeto.md](roadmap/14_como_reutilizar_o_projeto.md)

---

## Autor

**Igor Pereira Pinto**
Analista de Dados / BI e Planejamento Comercial Sênior
[github.com/IgorPereiraPinto](https://github.com/IgorPereiraPinto)

## Objetivo

Centralizar uma estrutura reutilizável para projetos analíticos e técnicos, permitindo que o Claude Code atue com mais consistência, contexto e especialização.

Este repositório foi pensado para apoiar demandas como:
- análise de dados e BI
- planejamento comercial e procurement
- SQL, Python e Power BI
- dashboards web em HTML
- Microsoft Fabric, AWS e dbt
- automações e integrações
- prompts, skills e documentação técnica

## Como este repositório está organizado

```text
claude-code-setup/
├── CLAUDE.md
├── README.md
├── SKILLS_GUIDE.md
├── AGENTS_GUIDE.md
├── COMMANDS_GUIDE.md
└── .claude/
    ├── rules/
    ├── skills/
    ├── agents/
    └── commands/

## Status da versão

**Versão atual: 1.0**

A versão 1.0 deste repositório consolida uma base estruturada para uso com Claude Code, incluindo `CLAUDE.md`, guides de consulta, rules, skills, agents e commands alinhados a um contexto real de dados, BI, automação, dashboards, analytics engineering e comunicação executiva.

O objetivo desta versão é servir como fundação reutilizável, consistente e escalável para futuros projetos, mantendo clareza de navegação, padronização técnica e especialização por tipo de tarefa.
