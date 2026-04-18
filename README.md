# credito_bba

Pipeline de dados ponta a ponta para analise de portfolio de credito corporativo.

Construido a partir de um case tecnico real para a posicao de Analista de Dados no Credito IBBA (Itau BBA). O repositorio cobre o fluxo completo: Excel -> Python ETL -> SQL em 3 camadas -> views analiticas -> dashboard executivo.

---

## Status do projeto

- Estrutura organizada para estudo, portfolio e reutilizacao
- Pipeline Python com execucao oficial via `python run_etl.py`
- Implementacoes paralelas para `SQL Server` e `Athena`
- Suite automatizada validada com `43 passed, 1 skipped`

---

## O que este repositorio resolve

O desafio do case e transformar cinco tabelas de origem (`clientes`, `operacoes`, `ratings`, `limites`, `exposicoes`) em indicadores acionaveis para comite de credito, com trilha tecnica clara do dado bruto ate o consumo analitico.

Este repositorio organiza e documenta todo o processo:

- extracao e validacao da base Excel
- limpeza e padronizacao em Python
- modelagem SQL em `raw`, `stage` e `dw`
- adaptacao da logica para `SQL Server` e `Athena`
- consumo final em dashboard HTML e apresentacao executiva

---

## Fluxo do pipeline

```text
Excel (dados_sinteticos_case.xlsx)
  |
  v
[Python ETL - porta de qualidade da fonte]
  01_extract.py   -> le o Excel, valida abas e schema minimo
  02_clean.py     -> padroniza tipos, trata nulos e normaliza strings
  03_validate.py  -> aplica regras de negocio e gera validation_report.csv
  04_export.py    -> exporta para data/processed/ (CSV ou Parquet)
  |
  v
[SQL - RAW]
  Primeiro landing SQL a partir do output validado do ETL Python
  SQL Server: tabelas relacionais com PK/FK
  Athena: tabelas externas em Parquet no S3
  |
  v
[SQL - STAGE]
  Enriquecimento, tipagem, deduplicacao e consolidacao
  |
  v
[SQL - DW]
  Views analiticas, KPIs e camada semantica para BI
  |
  v
[Consumo]
  dashboard_credito_bba.html
  plano_implementacao_credito_bba.pptx
```

---

## Estrutura do repositorio

```text
credito_bba/
|-- README.md
|-- .env.example
|-- requirements.txt
|-- requirements-dev.txt
|-- run_etl.py
|-- data/
|   |-- raw/
|   `-- processed/
|-- python/
|   |-- README.md
|   |-- 01_extract.py
|   |-- 02_clean.py
|   |-- 03_validate.py
|   `-- 04_export.py
|-- sql/
|   |-- sqlserver/
|   |   |-- 00_ddl.sql
|   |   |-- 01_raw_insert.sql
|   |   |-- 02_stage_views.sql
|   |   |-- 03_dw_views.sql
|   |   |-- 04_queries_analiticas.sql
|   |   `-- 05_views_kpi.sql
|   |-- athena/
|   |   |-- 00_ddl_external.sql
|   |   |-- 02_stage_views.sql
|   |   |-- 03_dw_views.sql
|   |   |-- 04_queries_analiticas.sql
|   |   `-- 05_views_kpi.sql
|   `-- extras/
|-- dashboards/
|   `-- dashboard_credito_bba.html
|-- presentations/
|   `-- plano_implementacao_credito_bba.pptx
|-- docs/
|   |-- arquitetura.md
|   |-- dicionario_de_dados.md
|   |-- regras_de_negocio.md
|   |-- como_executar.md
|   `-- faq_reutilizacao.md
|-- roadmap/
|   |-- 01_visao_geral_do_projeto.md
|   |-- 02_entendimento_do_case.md
|   |-- 03_analise_da_base_excel.md
|   |-- 04_arquitetura_do_pipeline.md
|   |-- 05_etl_extracao.md
|   |-- 06_etl_padronizacao_e_validacoes.md
|   |-- 07_modelagem_raw.md
|   |-- 08_modelagem_stage.md
|   |-- 09_modelagem_dw.md
|   |-- 10_sql_server_vs_athena.md
|   |-- 11_kpis_e_views_analiticas.md
|   |-- 12_dashboard_e_storytelling.md
|   |-- 13_apresentacao_executiva.md
|   `-- 14_como_reutilizar_o_projeto.md
`-- tests/
```

---

## Como executar

### 1. Preparacao

```bash
git clone https://github.com/IgorPereiraPinto/credito_bba.git
cd credito_bba
python -m venv .venv
```

Ativacao do ambiente virtual:

- Windows: `.venv\Scripts\activate`
- Linux/Mac: `source .venv/bin/activate`

Instalacao:

```bash
pip install -r requirements.txt
cp .env.example .env
```

Coloque `dados_sinteticos_case.xlsx` em `data/raw/`.

### 2. Execucao do ETL

Forma recomendada:

```bash
python run_etl.py
```

Alternativa para debug:

```bash
python python/01_extract.py
python python/02_clean.py
python python/03_validate.py
python python/04_export.py
```

### 3. Execucao do SQL

Execute os scripts na ordem indicada em:

- `sql/sqlserver/` para ambiente local
- `sql/athena/` para ambiente AWS

Guia detalhado: [docs/como_executar.md](docs/como_executar.md)

---

## Testes

Para validar a camada Python e a portabilidade da suite:

```bash
pytest -q
```

Resultado validado nesta versao do repositorio:

- `43 passed`
- `1 skipped`

---

## SQL Server e Athena

O projeto mantem duas implementacoes paralelas com a mesma logica analitica.

| Aspecto | SQL Server | Athena |
|---|---|---|
| Armazenamento | Tabelas relacionais locais | Tabelas externas em Parquet no S3 |
| Integridade | PK e FK declaradas | Garantida pelo ETL |
| Execucao | Desenvolvimento local | Ambiente AWS |
| BI | Power BI | QuickSight |

Observacao importante:

- o repositorio se chama `credito_bba`
- o banco/schema SQL foi mantido como `credito_ibba` por aderencia ao case original
- isso esta documentado e pode ser renomeado em reutilizacoes futuras

Guia comparativo: [roadmap/10_sql_server_vs_athena.md](roadmap/10_sql_server_vs_athena.md)

---

## Roadmap didatico

A pasta [roadmap/](roadmap/) e o eixo pedagogico do projeto. Ela explica, em ordem:

1. como entender o case
2. como analisar a base Excel
3. como estruturar o ETL
4. como modelar `raw`, `stage` e `dw`
5. como transformar a camada analitica em dashboard e apresentacao
6. como reutilizar o projeto em outro contexto de credito

Se a ideia for aprender o projeto do zero, comece por [roadmap/01_visao_geral_do_projeto.md](roadmap/01_visao_geral_do_projeto.md).

---

## Reutilizacao

Para adaptar este repositorio a outro case de credito:

1. substitua o arquivo de origem em `data/raw/`
2. ajuste schemas e nomes de abas em `python/01_extract.py`
3. revise regras de negocio em `docs/regras_de_negocio.md`
4. ajuste naming de banco/schema se necessario
5. reexecute ETL, SQL e testes

Guia completo: [roadmap/14_como_reutilizar_o_projeto.md](roadmap/14_como_reutilizar_o_projeto.md)

---

## Infraestrutura de desenvolvimento

Os arquivos `CLAUDE.md`, `AGENTS_GUIDE.md`, `COMMANDS_GUIDE.md`, `SKILLS_GUIDE.md` e o diretorio `.claude/` sao artefatos de produtividade usados durante o desenvolvimento. Eles nao fazem parte da logica do case e podem ser ignorados ou removidos em outro contexto.

---

## Autor

**Igor Pereira Pinto**  
Analista de Dados / BI e Planejamento Comercial Senior  
[github.com/IgorPereiraPinto](https://github.com/IgorPereiraPinto)
