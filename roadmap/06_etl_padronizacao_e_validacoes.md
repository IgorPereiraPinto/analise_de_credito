# 06 — ETL: Padronização, Limpeza e Validações

## Objetivo da etapa

Executar os scripts de limpeza e validação, entender as regras aplicadas e saber
como ajustá-las para um novo case.

---

## Entradas

- DataFrames brutos da etapa 05 (extração)

## Saídas

- DataFrames limpos e tipados
- DataFrames validados com regras de negócio aplicadas
- `data/processed/validation_report.csv`

---

## Script: `python/02_clean.py` — Limpeza e Padronização

### O que faz

1. Normaliza strings: strip + uppercase nos campos categóricos
2. Converte tipos: `str → date`, `str → decimal`, `str → int`
3. Trata nulos com estratégia explícita por campo
4. Remove linhas completamente duplicadas

### Estratégia de nulos

Definida no dicionário `NULL_STRATEGY` dentro do script:

- `drop`: linha inteira removida (campos de valor financeiro crítico)
- `fill_zero`: substitui por 0 (campos de valor opcional)
- `fill_unknown`: substitui por "DESCONHECIDO" (campos categóricos)
- `fill_value:X`: substitui por valor específico

### Para reutilização

1. Abra `02_clean.py`
2. Ajuste `DTYPE_MAP` com os tipos corretos dos campos do novo case
3. Ajuste `NULL_STRATEGY` com a estratégia correta para cada campo

---

## Script: `python/03_validate.py` — Validações de Negócio

### Validações aplicadas

| Nº | Regra                                              | Severidade |
|----|----------------------------------------------------|------------|
| 1  | `valor_utilizado` ≤ `valor_aprovado`               | warning    |
| 2  | `exposicao_descoberta` = `total` − `garantida`     | warning    |
| 3  | `pd_12m` entre 0 e 1                               | error      |
| 4  | `data_vencimento` ≥ `data_aprovacao`               | error      |
| 5  | `valor_limite` > 0                                 | error      |
| 6  | Unicidade de PK por tabela                         | warning    |

**error:** linha removida. **warning:** registrado, linha mantida.

### Relatório de validação

Após a execução, verifique `data/processed/validation_report.csv`:

```
tabela,regra,severidade,linhas_afetadas,detalhe
operacoes,valor_utilizado <= valor_aprovado,warning,3,...
```

### Para reutilização

Adicione ou remova regras do dicionário `VALIDATION_RULES` em `03_validate.py`.
Cada regra tem: nome, tabela, condição (como string ou função), e severidade.

---

## Como executar os dois scripts

```bash
python python/02_clean.py
python python/03_validate.py
```

---

## Script: `python/04_export.py` — Exportação

Exporta os DataFrames validados para `data/processed/`.

Para SQL Server: deixe `EXPORT_FORMAT=csv` (padrão)
Para Athena: altere para `EXPORT_FORMAT=parquet` no `.env`

```bash
python python/04_export.py
```

---

## Riscos e cuidados

- `02_clean.py` não tem ciência do domínio de crédito — não aplique regras de negócio aqui
- Se um campo crítico como `exposicao_total` vier nulo em muitas linhas, investigue a fonte
  antes de decidir entre `drop` e `fill_zero`
- O relatório de validação é auditoria — preserve-o ao longo das execuções

---

## Checklist de conclusão da etapa

- [ ] Executei `02_clean.py` sem erros
- [ ] Executei `03_validate.py` e li o relatório
- [ ] Executei `04_export.py` e confirmei os CSVs em `data/processed/`
- [ ] Nenhum erro severo inesperado no relatório de validação
- [ ] Avancei para `07_modelagem_raw.md`
