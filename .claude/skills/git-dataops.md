---
name: git-dataops
description: >
  Especialista em Git, versionamento de código e práticas DataOps para times de dados. Cobre
  Git workflow (branches, commits, PRs), CI/CD para pipelines de dados e dbt, ambientes
  dev/staging/prod, virtual environments Python, Makefile de automação, pre-commit hooks e
  qualidade de código (black, ruff). Use sempre que o usuário mencionar Git, versionamento,
  branch, commit, pull request, CI/CD, DataOps, ambiente virtual, requirements, .env,
  deploy de pipeline, ou qualquer prática de engenharia de software aplicada a dados.
  Trigger para: "como faço o commit", "estrutura de branches", "CI/CD para dados",
  "configura pre-commit", "ambiente virtual Python", "Makefile para dados", "DataOps".
---

# Git & DataOps — Versionamento e Práticas de Engenharia para Dados

## Identidade

Engenheiro de Dados com foco em qualidade, rastreabilidade e colaboração. Todo pipeline de
dados é código de produção e merece as mesmas práticas de engenharia: versionamento,
revisão, testes automatizados e deploy controlado.

---

## 1. Estrutura de Projeto de Dados

```
data-project/
├── .claude/                    ← instruções para Claude Code
│   ├── CLAUDE.md               ← manual do projeto
│   └── skills/                 ← skills específicas do projeto
├── .env                        ← credenciais (NUNCA commitar)
├── .env.example                ← template sem valores reais (commitar)
├── .gitignore                  ← ignora dados, credenciais, cache
├── .pre-commit-config.yaml     ← qualidade automática no commit
├── CLAUDE.md                   ← alias na raiz para Claude Code
├── Makefile                    ← automação de comandos
├── README.md                   ← documentação do projeto
├── requirements.txt            ← dependências de produção
├── requirements-dev.txt        ← dependências de desenvolvimento
│
├── src/                        ← código-fonte principal
│   ├── __init__.py
│   ├── extract/
│   ├── transform/
│   └── load/
│
├── pipelines/                  ← orquestração ponta a ponta
│   └── pipeline_vendas.py
│
├── notebooks/                  ← exploração (NÃO vai para prod)
│   └── exploracao_2024_01_vendas.ipynb
│
├── tests/                      ← testes automatizados
│   ├── __init__.py
│   ├── test_cleaner.py
│   └── test_aggregator.py
│
├── sql/                        ← queries SQL documentadas
│   ├── staging/
│   └── kpis/
│
└── docs/
    ├── data_dictionary.md
    └── architecture.md
```

---

## 2. .gitignore Padrão para Projetos de Dados

```gitignore
# ── Python ────────────────────────────────────────────────
__pycache__/
*.pyc
*.pyo
*.pyd
.venv/
venv/
env/
*.egg-info/
dist/
build/
.pytest_cache/
.mypy_cache/
.ruff_cache/
htmlcov/
.coverage

# ── Dados — NUNCA commitar dados reais ──────────────────
*.csv
*.xlsx
*.xls
*.parquet
*.json
data/raw/
data/processed/
data/output/
data/sample/     # ← manter dados de amostra sintéticos se necessário

# ── Credenciais ─────────────────────────────────────────
.env
*.key
*.pem
credentials.json
token.json
secrets.yaml
service_account.json

# ── IDEs e OS ───────────────────────────────────────────
.vscode/
.idea/
*.ipynb_checkpoints
.DS_Store
Thumbs.db

# ── dbt ─────────────────────────────────────────────────
target/
dbt_packages/
logs/
profiles.yml    # nunca commitar — contém conexões de banco
```

---

## 3. Git Workflow para Times de Dados

```bash
# ── Estrutura de branches ────────────────────────────────
main          # produção — protegida, nunca commitar direto
develop       # integração — base para features
feat/xxx      # nova feature ou análise
fix/xxx       # correção de bug
hotfix/xxx    # correção urgente em produção
release/vX.Y  # preparação de release

# ── Fluxo diário ─────────────────────────────────────────
git checkout develop
git pull origin develop

git checkout -b feat/pipeline-salesforce

# ... trabalha, testa...

git add src/extract/salesforce_client.py
git add tests/test_salesforce_client.py
git commit -m "feat(extract): adiciona extrator de Opportunities do Salesforce"

git push origin feat/pipeline-salesforce
# → Abre Pull Request para develop
# → Aguarda revisão (pelo menos 1 aprovação)

# ── Merge para produção ───────────────────────────────────
git checkout main
git merge --no-ff develop
git tag -a v1.3.0 -m "Release: Salesforce ETL integrado"
git push origin main --tags
```

---

## 4. Conventional Commits — Padrão de Mensagens

```bash
# Formato: tipo(escopo): descrição no imperativo

feat(extract):     adiciona extrator de dados do Salesforce CRM
feat(transform):   implementa SCD Type 2 para dim_cliente
fix(sql):          corrige NULLIF faltando em cálculo de atingimento
fix(pipeline):     resolve falha de encoding UTF-8 em arquivos CSV
refactor(cleaner): reorganiza funções de limpeza por tipo de dado
test(extract):     adiciona testes unitários para salesforce_client
docs(readme):      atualiza instruções de configuração do ambiente
chore(deps):       atualiza pandas 2.1.4 → 2.2.0
perf(athena):      adiciona filtro de partição obrigatório nas queries
ci(github):        adiciona workflow de testes e linting no PR
build(docker):     cria Dockerfile para execução do pipeline

# Regra: nunca "corrigido", "adicionado" — sempre imperativo
# ✅ "adiciona", "implementa", "corrige", "refatora"
# ❌ "adicionado", "corrigido", "implementando"
```

---

## 5. Makefile — Automação de Tarefas

```makefile
.PHONY: setup install test test-cov lint format clean \
        pipeline-vendas pipeline-salesforce dbt-run dbt-test

# ── Setup inicial ───────────────────────────────────────────────
setup:
	python -m venv .venv
	.venv/bin/pip install --upgrade pip setuptools wheel
	.venv/bin/pip install -r requirements-dev.txt
	.venv/bin/pre-commit install
	@echo "✅ Ambiente configurado. Ative com: source .venv/bin/activate"

# ── Dependências ────────────────────────────────────────────────
install:
	pip install -r requirements.txt

install-dev:
	pip install -r requirements-dev.txt

# ── Testes ─────────────────────────────────────────────────────
test:
	pytest tests/ -v --tb=short

test-cov:
	pytest tests/ --cov=src --cov-report=html --cov-report=term-missing
	@echo "📊 Relatório: htmlcov/index.html"

test-watch:
	ptw tests/ -- --tb=short  # pytest-watch para TDD

# ── Qualidade de código ─────────────────────────────────────────
lint:
	ruff check src/ tests/
	mypy src/ --ignore-missing-imports

format:
	black src/ tests/ --line-length 100
	ruff check --fix src/ tests/

check: lint test
	@echo "✅ Lint e testes OK"

# ── Pipelines ───────────────────────────────────────────────────
pipeline-vendas:
	python pipelines/pipeline_vendas.py

pipeline-salesforce:
	python pipelines/pipeline_salesforce.py

# ── dbt ────────────────────────────────────────────────────────
dbt-run:
	cd dbt && dbt run

dbt-test:
	cd dbt && dbt test

dbt-full:
	cd dbt && dbt run && dbt test && dbt docs generate

# ── Limpeza ─────────────────────────────────────────────────────
clean:
	find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null; true
	find . -name "*.pyc" -delete 2>/dev/null; true
	rm -rf .coverage htmlcov/ dist/ build/ .pytest_cache/ .ruff_cache/
	@echo "🧹 Limpeza concluída"
```

---

## 6. requirements.txt Padrão

```txt
# requirements.txt — Produção
pandas==2.2.0
polars==0.20.6
numpy==1.26.4
pyarrow==15.0.0
duckdb==0.10.0
boto3==1.34.50
pyodbc==5.1.0
sqlalchemy==2.0.27
requests==2.31.0
python-dotenv==1.0.1
openpyxl==3.1.2
simple-salesforce==1.12.5
anthropic>=0.39.0

# requirements-dev.txt — Desenvolvimento
-r requirements.txt
pytest==8.0.0
pytest-cov==4.1.0
pytest-watch==4.2.0
black==24.2.0
ruff==0.2.2
mypy==1.8.0
pre-commit==3.6.2
ipykernel==6.29.2
jupyter==1.0.0
```

---

## 7. pre-commit — Qualidade Automática

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/psf/black
    rev: 24.2.0
    hooks:
      - id: black
        language_version: python3.11
        args: ['--line-length=100']

  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.2.2
    hooks:
      - id: ruff
        args: ['--fix', '--exit-non-zero-on-fix']

  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.5.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-json
      - id: check-added-large-files
        args: ['--maxkb=500']
      - id: detect-private-key       # bloqueia commits com chaves privadas
      - id: check-merge-conflict
      - id: no-commit-to-branch
        args: ['--branch', 'main', '--branch', 'develop']

  - repo: https://github.com/commitizen-tools/commitizen
    rev: v3.14.1
    hooks:
      - id: commitizen              # valida formato do commit message
```

---

## 8. GitHub Actions — CI/CD para Dados

```yaml
# .github/workflows/ci.yml
name: CI — Lint, Test e Qualidade

on:
  push:
    branches: [develop, main]
  pull_request:
    branches: [develop, main]

jobs:
  quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'
          cache: 'pip'

      - name: Instalar dependências
        run: |
          pip install -r requirements-dev.txt

      - name: Lint (ruff)
        run: ruff check src/ tests/

      - name: Formatação (black)
        run: black --check src/ tests/ --line-length 100

      - name: Testes com cobertura
        run: pytest tests/ --cov=src --cov-report=xml --cov-fail-under=80

      - name: Upload cobertura
        uses: codecov/codecov-action@v3
        with:
          file: coverage.xml
```

---

## 9. Gerenciamento de Segredos

```bash
# .env — NUNCA commitar (adicione ao .gitignore)
AWS_ACCESS_KEY_ID=AKIA...
AWS_SECRET_ACCESS_KEY=...
AWS_DEFAULT_REGION=us-east-1
S3_BUCKET_RAW=empresa-datalake-prod
SQL_SERVER_CONN=mssql+pyodbc://user:pass@server/db?driver=ODBC+Driver+17+for+SQL+Server
SALESFORCE_USER=user@empresa.com
SALESFORCE_PASSWORD=senha
SALESFORCE_TOKEN=token
ANTHROPIC_API_KEY=sk-ant-...

# .env.example — commitar (template sem valores)
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_DEFAULT_REGION=us-east-1
S3_BUCKET_RAW=
SQL_SERVER_CONN=
SALESFORCE_USER=
SALESFORCE_PASSWORD=
SALESFORCE_TOKEN=
ANTHROPIC_API_KEY=
```

```python
# Uso padrão no código
from dotenv import load_dotenv
import os

load_dotenv()  # carrega .env do diretório corrente

AWS_REGION   = os.getenv('AWS_DEFAULT_REGION', 'us-east-1')
S3_BUCKET    = os.getenv('S3_BUCKET_RAW')
ANTHROPIC_KEY = os.getenv('ANTHROPIC_API_KEY')

# Validação de obrigatórias na inicialização do pipeline
REQUIRED_VARS = ['AWS_ACCESS_KEY_ID', 'S3_BUCKET_RAW', 'SQL_SERVER_CONN']
missing = [v for v in REQUIRED_VARS if not os.getenv(v)]
if missing:
    raise EnvironmentError(f"Variáveis de ambiente obrigatórias não encontradas: {missing}")
```

## Regras de Qualidade

- **Nunca commitar** dados reais, credenciais ou arquivos binários grandes
- **Branch protection** em main e develop — PR obrigatório com 1 revisor
- **Conventional commits** — mensagens claras e padronizadas são auditoria
- **pre-commit** instalado em todo ambiente de desenvolvimento — `pre-commit install`
- **CI verde** antes de merge — nunca dar merge em PR com tests falhando
- **`requirements.txt` com versões fixas** — reprodutibilidade garantida
- **Versionamento semântico** (SemVer) para releases: MAJOR.MINOR.PATCH

## Observações

Para DataOps com dbt, configure também `profiles.yml` por ambiente (dev/staging/prod)
fora do repositório, ou use variáveis de ambiente do CI/CD para injetar conexões seguras.
