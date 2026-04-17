# 05 — ETL: Extração

## Objetivo da etapa

Executar a extração do Excel, entender o que o script faz e saber como adaptá-lo.

---

## Entradas

- `data/raw/dados_sinteticos_case.xlsx`
- `.env` configurado com `DATA_RAW_PATH`

## Saídas

- Dicionário de DataFrames em memória, pronto para a etapa de limpeza
- Log de confirmação de abas e schemas

---

## Script: `python/01_extract.py`

### O que o script faz

1. Lê o `.env` para encontrar o caminho do Excel
2. Para cada aba em `EXPECTED_SHEETS`:
   - Lê a aba com `pd.read_excel()`
   - Normaliza nomes de coluna (lowercase + strip)
   - Valida se todas as colunas obrigatórias estão presentes
   - Aborta com `sys.exit(1)` se uma aba ou coluna estiver faltando
3. Retorna um dicionário `{nome_aba: DataFrame}`

### Por que abortar e não apenas avisar?

Se uma coluna obrigatória está ausente, todo o pipeline downstream está comprometido.
Avisar e continuar geraria erros silenciosos nas etapas seguintes — mais difíceis de
diagnosticar. Abortar cedo é mais seguro.

---

## Como executar

```bash
python python/01_extract.py
```

Log esperado:

```
INFO  | 01_extract.py — Iniciando extração
INFO  | Lendo arquivo: data/raw/dados_sinteticos_case.xlsx
INFO  | [clientes]   75 linhas lidas
INFO  | [clientes]   Schema validado — 8 colunas OK
...
SUCCESS | Extração concluída — 5 tabelas carregadas
```

---

## O que editar para reutilização

```python
# Em 01_extract.py, ajuste este dicionário:
EXPECTED_SHEETS: dict[str, list[str]] = {
    "nome_da_aba_no_excel": ["coluna_obrigatoria_1", "coluna_2", ...],
    ...
}
```

Se o novo case tem uma aba chamada `carteira` com colunas `id_cliente`, `saldo`, `produto`:

```python
EXPECTED_SHEETS = {
    "carteira": ["id_cliente", "saldo", "produto"],
}
```

---

## Riscos e cuidados

- O Excel pode ter o nome da aba com espaço ou acento — verifique exatamente
- Colunas com cabeçalho mesclado no Excel não são lidas corretamente — exporte como CSV antes
- Se a aba tiver linhas de cabeçalho extras (ex: títulos acima da tabela), use `header=N`
  no `pd.read_excel()`

---

## Checklist de conclusão da etapa

- [ ] Executei `01_extract.py` sem erros
- [ ] Confirmei que todas as 5 tabelas foram carregadas
- [ ] Confirmei as contagens de linhas por tabela
- [ ] Avancei para `06_etl_padronizacao_e_validacoes.md`
