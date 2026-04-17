# 03 — Análise da Base Excel

## Objetivo da etapa

Entender a estrutura e a qualidade dos dados antes de escrever qualquer código.
Analisar o Excel manualmente (ou com Python de forma exploratória) antes de construir o ETL.

---

## Entradas

- `data/raw/dados_sinteticos_case.xlsx`

## Saídas

- Mapeamento de abas, colunas e tipos
- Lista de problemas de qualidade identificados
- Premissas para o script de limpeza

---

## O que verificar no Excel antes do ETL

### 1. Estrutura das abas

Confirme que existem as 5 abas esperadas: `clientes`, `operacoes`, `ratings`, `limites`, `exposicoes`.

### 2. Contagem de linhas por aba (referência com dados sintéticos)

| Aba        | Linhas brutas | Após deduplicação |
|------------|---------------|-------------------|
| clientes   | ~75           | 72                |
| operacoes  | ~223          | 222               |
| ratings    | ~900          | 864               |
| limites    | ~95           | 92                |
| exposicoes | ~432          | 432               |

Diferenças entre bruto e deduplicado indicam registros duplicados na PK.

### 3. Qualidade esperada

Com os dados sintéticos, os problemas identificados foram:

- Duplicatas de PK em `clientes`, `operacoes`, `ratings` e `limites`
- Nulos em campos opcionais (`observacao`, `aprovador`, `rating_externo`)
- Inconsistências menores na aritmética de `exposicao_descoberta` (diferença de centavos)
- Nenhum registro com `pd_12m` fora do intervalo [0,1]
- Nenhuma operação com `data_vencimento` anterior a `data_aprovacao`

### 4. Relacionamentos a validar

- Todo `cliente_id` em `operacoes` deve existir em `clientes`
- Todo `cliente_id` em `ratings` deve existir em `clientes`
- Todo `cliente_id` em `limites` deve existir em `clientes`
- Todo `cliente_id` em `exposicoes` deve existir em `clientes`

---

## Exploração rápida com Python

```python
import pandas as pd

xl = pd.ExcelFile("data/raw/dados_sinteticos_case.xlsx")
print(xl.sheet_names)

for sheet in xl.sheet_names:
    df = xl.parse(sheet)
    print(f"\n{sheet}: {df.shape}")
    print(df.dtypes)
    print(df.isnull().sum())
```

---

## Arquivos envolvidos

- `data/raw/dados_sinteticos_case.xlsx`
- `python/01_extract.py` (referência para os schemas esperados)

---

## O que editar para reutilização

Se o novo case tem abas com nomes ou colunas diferentes:
- Abra o Excel e mapeie os nomes reais
- Atualize `EXPECTED_SHEETS` em `python/01_extract.py`
- Verifique se os tipos são compatíveis com `DTYPE_MAP` em `02_clean.py`

---

## Riscos e cuidados

- Não confie que o Excel está limpo porque parece organizado
- Sempre valide a contagem de linhas antes e depois da deduplicação
- Campos de valor financeiro nulos são um erro severo — documente como tratar
- Datas no Excel podem vir como `float` (número serial) — o pandas trata, mas fique atento

---

## Checklist de conclusão da etapa

- [ ] Confirmei que o Excel tem as 5 abas esperadas
- [ ] Conferi a contagem de linhas por aba
- [ ] Identifiquei campos com nulos
- [ ] Identifiquei duplicatas na PK
- [ ] Verifiquei a integridade referencial manualmente
- [ ] Documentei as premissas para o script de limpeza
- [ ] Avancei para `04_arquitetura_do_pipeline.md`
