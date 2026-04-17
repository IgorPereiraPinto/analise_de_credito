# 14 — Como Reutilizar o Projeto

## Objetivo da etapa

Guia definitivo para adaptar este projeto a qualquer outro case de crédito corporativo,
com o mínimo de reescrita possível.

---

## Princípio de reutilização

Este projeto foi projetado em camadas de abstração:

- **Camada Python:** a mais fácil de reutilizar — só troca o schema
- **Camada SQL RAW:** troca junto com o schema
- **Camada SQL STAGE:** join e snapshot — pouco muda entre cases de crédito
- **Camada SQL DW:** lógica de negócio — muda os benchmarks e os KPIs
- **Dashboard HTML:** muda os dados embutidos e os títulos

---

## Checklist de reutilização

### Passo 1: Entender o novo case

- [ ] Quais são as tabelas/entidades do novo case?
- [ ] Qual é a granularidade de cada tabela?
- [ ] Quais são os KPIs e benchmarks do novo domínio?

### Passo 2: Ajustar o Python ETL

**Arquivo: `python/01_extract.py`**

Atualize `EXPECTED_SHEETS`:

```python
EXPECTED_SHEETS = {
    "nome_da_aba": ["coluna_1", "coluna_2", ...],
}
```

**Arquivo: `python/02_clean.py`**

Atualize `DTYPE_MAP` e `NULL_STRATEGY` com os tipos e estratégias do novo domínio.

**Arquivo: `python/03_validate.py`**

Substitua as regras em `validate_all()` pelas regras do novo case.
Mantenha a estrutura: condição + severidade + log.

### Passo 3: Ajustar o SQL RAW

**Arquivo: `sql/sqlserver/00_ddl.sql`**

Reescreva o DDL com as tabelas do novo case. Preserve:
- PK e FK para SQL Server
- Apenas schema para Athena (sem FK)
- Índices nos campos mais usados em filtros

### Passo 4: Ajustar o SQL STAGE

**Arquivo: `sql/sqlserver/02_stage_views.sql`**

O que quase sempre precisa de ajuste:

1. `vw_stage_escala_rating` — se o novo case tiver outra escala de rating
2. `vw_stage_exposicao_recente` — se o campo de data ou de valor for diferente
3. `vw_stage_cliente_enriquecido` — se o novo case tiver mais ou menos tabelas

O que raramente muda:
- A lógica de `MAX(data_referencia)` para pegar o snapshot mais recente
- A estrutura de consolidação por chave com `GROUP BY`

### Passo 5: Ajustar o SQL DW

**Arquivo: `sql/sqlserver/03_dw_views.sql`**

Atualize:
- Thresholds nos `CASE WHEN` de classificação de risco
- Campos específicos do domínio em `vw_matriz_risco`
- KPIs calculados em `vw_kpi_por_segmento` e `vw_kpi_por_subsetor`

**Arquivo: `docs/regras_de_negocio.md`**

Documente os novos benchmarks antes de atualizar o SQL — evita confusão.

### Passo 6: Ajustar o dashboard

**Arquivo: `dashboards/dashboard_credito_bba.html`**

Mude:
- Títulos e subtítulos
- Dados embutidos em JavaScript
- Labels dos eixos nos gráficos

---

## Quanto tempo leva a reutilização

| Situação                                         | Estimativa         |
|--------------------------------------------------|--------------------|
| Mesmo domínio de crédito, dados diferentes       | 2-4 horas          |
| Domínio diferente, estrutura similar (5 tabelas) | 1-2 dias           |
| Domínio completamente diferente                  | 2-3 dias + testes  |

---

## O que NÃO precisará ser reescrito

- A estrutura de 3 camadas (RAW/STAGE/DW)
- Os scripts de exportação (`04_export.py`)
- A lógica de window functions (`LAG`, `RANK`, `ROW_NUMBER`)
- O tratamento de nulos e deduplicação
- A separação SQL Server / Athena

---

## Checklist de conclusão do projeto

- [ ] Pipeline completo executado do Excel ao dashboard
- [ ] Todas as 6 queries analíticas rodando e interpretadas
- [ ] Dashboard funcional com os KPIs corretos
- [ ] Documentação completa (dicionário, regras, arquitetura)
- [ ] Repositório versionado no GitHub
- [ ] Pronto para adaptar a outro case de crédito
