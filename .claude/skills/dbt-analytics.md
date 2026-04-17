--- 

name: dbt-analytics
description: >
  Especialista em dbt (data build tool) para analytics engineering e transformação SQL
  versionada. Cobre dbt Core e Cloud, organização staging/intermediate/marts, testes,
  fontes (sources), documentação, modelos incrementais, snapshots SCD2, macros Jinja e
  integração com Athena, SQL Server, BigQuery e Snowflake. Use sempre que o usuário mencionar
  dbt, analytics engineering, modelo dbt, transformação SQL versionada, data lineage,
  documentação de dados, testes de dados, dbt test, dbt run, snapshot, ou pipeline
  SQL organizado com versionamento. Trigger para: "cria um modelo dbt", "como estruturo
  dbt", "testa esse modelo", "snapshot SCD2 no dbt", "macro dbt", "dbt source".
---

# dbt Analytics — Analytics Engineering com dbt

## Identidade

Analytics Engineer especializado em dbt, com foco em transformações SQL organizadas,
versionadas, testadas e documentadas. Código SQL no dbt é código de produção — precisa de
testes, documentação e revisão como qualquer outro software.

---

## Estrutura de Projeto dbt

```
dbt_project/
├── dbt_project.yml          ← configuração central
├── profiles.yml             ← conexões por ambiente
├── packages.yml             ← dependências (dbt-utils, etc.)
│
├── models/
│   ├── staging/             ← 1:1 com fontes, renomear e tipar
│   │   ├── _sources.yml     ← declaração das fontes
│   │   ├── stg_vendas.sql
│   │   └── stg_clientes.sql
│   ├── intermediate/        ← joins e lógica de negócio
│   │   └── int_pipeline_comercial.sql
│   └── marts/               ← tabelas finais para consumo BI/ML
│       ├── sales/
│       │   ├── _models.yml  ← documentação e testes
│       │   ├── fct_vendas.sql
│       │   └── dim_vendedor.sql
│       └── finance/
│           └── fct_receita_mensal.sql
│
├── tests/                   ← testes customizados SQL
│   └── assert_receita_positiva.sql
├── seeds/                   ← CSVs estáticos (metas, de-para)
│   └── metas_vendedor_2024.csv
├── snapshots/               ← SCD Type 2
│   └── snp_clientes.sql
└── macros/                  ← funções Jinja reutilizáveis
    ├── calcular_atingimento.sql
    └── generate_schema_name.sql
```

---

## dbt_project.yml

```yaml
name: empresa_analytics
version: '1.0.0'
config-version: 2
profile: empresa_athena   # ou empresa_sqlserver, empresa_bigquery

model-paths:    ["models"]
seed-paths:     ["seeds"]
test-paths:     ["tests"]
snapshot-paths: ["snapshots"]
macro-paths:    ["macros"]

models:
  empresa_analytics:
    staging:
      +materialized: view        # staging = sempre view (leve)
      +schema: staging
    intermediate:
      +materialized: view
      +schema: intermediate
    marts:
      +materialized: table       # marts = tabela materializada
      +schema: marts
      sales:
        fct_vendas:
          +materialized: incremental
          +unique_key: id_venda
          +on_schema_change: sync_all_columns
```

---

## Staging Model — Padrão de Qualidade

```sql
-- models/staging/stg_vendas.sql
-- Propósito: limpeza 1:1 da tabela raw de vendas
-- Regras: renomear, tipar, filtrar status inválidos

WITH source AS (

    SELECT * FROM {{ source('sql_server', 'vendas') }}

),

renamed AS (

    SELECT
        -- PKs e FKs
        CAST(id_venda     AS VARCHAR)  AS id_venda,
        CAST(id_cliente   AS VARCHAR)  AS id_cliente,
        CAST(id_vendedor  AS VARCHAR)  AS id_vendedor,

        -- Datas
        CAST(data_venda   AS DATE)     AS data_venda,

        -- Métricas financeiras
        ROUND(CAST(valor_bruto     AS DECIMAL(18,2)), 2) AS valor_bruto,
        ROUND(CAST(valor_desconto  AS DECIMAL(18,2)), 2) AS valor_desconto,
        ROUND(
            CAST(valor_bruto AS DECIMAL(18,2)) -
            COALESCE(CAST(valor_desconto AS DECIMAL(18,2)), 0)
        , 2)                                             AS valor_liquido,

        -- Atributos padronizados
        UPPER(TRIM(status)) AS status,
        UPPER(TRIM(canal))  AS canal,

        -- Metadados
        _ETL_LOADED_AT      AS loaded_at

    FROM source

    -- Filtros de qualidade na origem
    WHERE status NOT IN ('CANCELADO', 'ESTORNADO', 'DUPLICADO')
      AND valor_bruto > 0

)

SELECT * FROM renamed
```

---

## Sources YAML — Declaração e Testes

```yaml
# models/staging/_sources.yml
version: 2

sources:
  - name: sql_server
    database: empresa_db
    schema: dbo
    description: "Tabelas transacionais do SQL Server (ERP TOTVS Protheus)"
    freshness:
      warn_after:  {count: 24, period: hour}
      error_after: {count: 48, period: hour}
    loaded_at_field: _etl_loaded_at

    tables:
      - name: vendas
        description: "Tabela de vendas brutas do ERP"
        columns:
          - name: id_venda
            description: "Identificador único da venda (PK natural)"
            tests: [unique, not_null]
          - name: valor_bruto
            description: "Valor bruto antes de descontos"
            tests:
              - not_null
              - dbt_utils.accepted_range:
                  min_value: 0
                  max_value: 10000000
          - name: status
            tests:
              - accepted_values:
                  values: ['APROVADO', 'PENDENTE', 'CANCELADO', 'ESTORNADO']
          - name: data_venda
            tests: [not_null]
```

---

## Fact Table Incremental — Gold

```sql
-- models/marts/sales/fct_vendas.sql

{{
  config(
    materialized        = 'incremental',
    unique_key          = 'id_venda',
    incremental_strategy = 'merge',
    on_schema_change    = 'sync_all_columns',
    tags                = ['daily', 'sales']
  )
}}

WITH vendas AS (

    SELECT * FROM {{ ref('stg_vendas') }}

    {% if is_incremental() %}
    -- Carga incremental: apenas registros novos ou atualizados
    WHERE data_venda > (SELECT MAX(data_venda) FROM {{ this }})
    {% endif %}

),

vendedor AS (SELECT * FROM {{ ref('dim_vendedor') }}),
cliente  AS (SELECT * FROM {{ ref('dim_cliente') }}),
data     AS (SELECT * FROM {{ ref('dim_data') }})

SELECT
    -- Chaves
    v.id_venda,
    v.id_vendedor,
    v.id_cliente,
    v.data_venda,

    -- Dimensões denormalizadas (performance de leitura)
    d.ano, d.mes, d.trimestre, d.nome_mes, d.ano_mes,
    ve.nome_vendedor, ve.regional, ve.gerente,
    c.segmento_cliente, c.cidade, c.uf,

    -- Métricas
    v.valor_bruto,
    v.valor_desconto,
    v.valor_liquido,
    v.status, v.canal,

    -- Classificação de porte (regra de negócio documentada)
    CASE
        WHEN v.valor_liquido >= 50000 THEN 'GRANDE'
        WHEN v.valor_liquido >= 10000 THEN 'MEDIO'
        ELSE 'PEQUENO'
    END AS porte_venda,

    -- Metadados
    CURRENT_TIMESTAMP AS _dbt_updated_at

FROM vendas v
LEFT JOIN vendedor ve ON v.id_vendedor = ve.id_vendedor
LEFT JOIN cliente  c  ON v.id_cliente  = c.id_cliente
LEFT JOIN data     d  ON v.data_venda  = d.data
```

---

## Macros Reutilizáveis

```sql
-- macros/calcular_atingimento.sql
{% macro calcular_atingimento(realizado, meta) %}
    CASE
        WHEN {{ meta }} = 0 OR {{ meta }} IS NULL THEN NULL
        WHEN {{ realizado }} / NULLIF({{ meta }}, 0) >= 1.0 THEN 'ACIMA'
        WHEN {{ realizado }} / NULLIF({{ meta }}, 0) >= 0.8 THEN 'NO_PRAZO'
        WHEN {{ realizado }} / NULLIF({{ meta }}, 0) >= 0.6 THEN 'ATENCAO'
        ELSE 'ABAIXO'
    END
{% endmacro %}

-- Uso em qualquer model:
-- {{ calcular_atingimento('receita_realizada', 'meta_receita') }} AS status_meta
```

---

## Snapshot SCD Type 2

```sql
-- snapshots/snp_clientes.sql
{% snapshot snp_clientes %}

{{
  config(
    target_schema    = 'snapshots',
    unique_key       = 'id_cliente',
    strategy         = 'check',
    check_cols       = ['segmento', 'cidade', 'uf', 'status_ativo', 'plano']
  )
}}

SELECT
    id_cliente,
    nome,
    segmento,
    cidade,
    uf,
    status_ativo,
    plano,
    _etl_loaded_at
FROM {{ source('sql_server', 'clientes') }}

{% endsnapshot %}
```

---

## Comandos dbt Essenciais

```bash
dbt debug                           # testa conexão
dbt deps                            # instala packages (dbt-utils, etc.)
dbt run                             # executa todos os modelos
dbt run --select staging            # apenas pasta staging
dbt run --select fct_vendas+        # fct_vendas e todos dependentes
dbt run --select +fct_vendas        # fct_vendas e todos ancestrais
dbt run --select tag:daily          # modelos com tag daily
dbt test                            # executa todos os testes
dbt test --select fct_vendas        # testa apenas fct_vendas
dbt snapshot                        # executa snapshots SCD2
dbt seed                            # carrega CSVs de seeds
dbt source freshness                # verifica atualidade das fontes
dbt docs generate && dbt docs serve # gera e abre documentação
dbt compile                         # compila SQL sem executar
```

## Regras de Qualidade

- Todo modelo deve ter ao menos `not_null` + `unique` no unique_key
- Staging é 1:1 com a fonte — sem joins, sem agregações
- Marts são o único lugar para joins complexos e regras de negócio
- Usar `ref()` para dependências entre modelos — nunca nome de tabela hardcoded
- Documentar regras de negócio em YAML (description) e comentários SQL
- Sempre testar `accepted_values` em colunas de status e categoria
