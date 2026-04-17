# 07 — Modelagem RAW

## Objetivo da etapa

Criar as tabelas RAW no banco e carregar os dados exportados pelo Python ETL.
Entender por que essa camada existe e como ela difere no SQL Server vs. Athena.

---

## Entradas

- CSVs em `data/processed/` (saída da etapa 06)
- `sql/sqlserver/00_ddl.sql` e `sql/sqlserver/01_raw_insert.sql`
- OU `sql/athena/00_ddl_external.sql`

## Saídas

- Banco `credito_ibba` criado com as 5 tabelas populadas

---

## O que é a camada RAW

A camada RAW é o registro imutável da fonte. Ela preserva o dado exatamente como chegou,
antes de qualquer enriquecimento de negócio. Ela existe por dois motivos:

1. **Reprocessamento:** se a lógica de negócio mudar, você pode reprocessar a partir
   do RAW sem precisar voltar à fonte original
2. **Auditoria:** o RAW documenta o que o banco tinha em um dado momento

**Nunca modifique a camada RAW após a carga.**

---

## SQL Server: criação das tabelas

Execute `sql/sqlserver/00_ddl.sql` no SSMS. O script:
- Cria o banco `credito_ibba`
- Cria as 5 tabelas com PKs, FKs e índices de performance
- Roda a verificação de estrutura ao final

### Carga dos dados

Execute `sql/sqlserver/01_raw_insert.sql`. Antes, ajuste o caminho absoluto no BULK INSERT:

```sql
BULK INSERT clientes
FROM 'C:\SEU_CAMINHO\data\processed\clientes.csv'  -- ← ajuste aqui
```

Verifique as contagens após a carga:

```sql
SELECT 'clientes', COUNT(*) FROM clientes UNION ALL ...
-- Esperado: 72 / 222 / 864 / 92 / 432
```

---

## Athena: tabelas externas

Execute `sql/athena/00_ddl_external.sql` no Athena Query Editor. O script:
- Cria o banco no Glue Data Catalog
- Registra as 5 tabelas externas apontando para o S3

> Substitua `s3://bucket-credito/` pelo nome real do seu bucket.

Para verificar, execute:

```sql
SELECT COUNT(*) FROM credito_ibba.clientes;
```

---

## Diferença fundamental entre SQL Server e Athena

No SQL Server, a carga é uma operação de escrita (INSERT).
No Athena, a carga é apenas o registro do schema — os dados ficam no S3.
A tabela no Athena é uma "janela" para o arquivo Parquet.

---

## Arquivos envolvidos

- `sql/sqlserver/00_ddl.sql`
- `sql/sqlserver/01_raw_insert.sql`
- `sql/athena/00_ddl_external.sql`

---

## Checklist de conclusão da etapa

- [ ] Banco `credito_ibba` criado com sucesso
- [ ] As 5 tabelas criadas e populadas
- [ ] Contagens de linhas conferidas
- [ ] Verificações de qualidade executadas (CHECK 1 a CHECK 5 em `01_raw_insert.sql`)
- [ ] Avancei para `08_modelagem_stage.md`
