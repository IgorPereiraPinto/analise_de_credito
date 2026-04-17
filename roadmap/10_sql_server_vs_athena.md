# 10 — SQL Server vs. Athena: Guia de Diferenças

## Objetivo da etapa

Entender as diferenças de sintaxe e arquitetura entre os dois ambientes para adaptar
queries com segurança e sem consultar documentação externa a cada mudança.

---

## Referência rápida de sintaxe

| Funcionalidade                     | SQL Server                                  | Athena (Presto/Trino)               |
|------------------------------------|---------------------------------------------|-------------------------------------|
| Formatar data como string          | `FORMAT(data, 'yyyy-MM')`                   | `DATE_FORMAT(data, '%Y-%m')`        |
| Data atual                         | `GETDATE()` ou `CAST(GETDATE() AS DATE)`    | `CURRENT_DATE`                      |
| Diferença entre datas              | `DATEDIFF(DAY, d1, d2)`                     | `DATE_DIFF('day', d1, d2)`          |
| Somar meses a uma data             | `DATEADD(MONTH, -1, data)`                  | `DATE_ADD('month', -1, data)`       |
| Desvio padrão                      | `STDEV(coluna)`                             | `STDDEV(coluna)`                    |
| Top N linhas                       | `SELECT TOP 10 ...`                         | `SELECT ... LIMIT 10`               |
| Criar ou substituir view           | `CREATE OR ALTER VIEW`                      | `CREATE OR REPLACE VIEW`            |
| Concatenar strings                 | `CONCAT(a, b)` ou `a + b`                   | `CONCAT(a, b)` (operador + não existe) |
| Percentil exato                    | `PERCENTILE_CONT(0.5) WITHIN GROUP (...)`   | `APPROX_PERCENTILE(col, 0.5)`      |
| Tipo decimal/float                 | `DECIMAL(15,2)`, `FLOAT`                    | `DECIMAL(15,2)`, `DOUBLE`           |
| Tipo texto                         | `VARCHAR(n)`, `NVARCHAR(n)`                 | `STRING`                            |
| Cast para float                    | `CAST(x AS FLOAT)`                          | `CAST(x AS DOUBLE)`                 |
| Verificar nulo                     | `IS NULL`, `ISNULL(x, 0)`                   | `IS NULL`, `COALESCE(x, 0)`         |
| Transações e GO                    | `GO` separa batches                         | Não existe — execute query a query  |
| PKs e FKs                          | Suportadas nativamente                      | Não existem — garantidas pelo ETL   |
| Índices                            | `CREATE INDEX`                              | Não existem — use particionamento   |

---

## Diferenças arquiteturais

### Armazenamento

No SQL Server, os dados são armazenados no banco. Um `INSERT` escreve no disco do servidor.

No Athena, os dados ficam no S3. O Athena só lê — ele nunca escreve na tabela original.
Um `CREATE EXTERNAL TABLE` apenas registra o schema no Glue Catalog.

### Performance

No SQL Server, a performance vem de índices e estatísticas.

No Athena, a performance vem de:
- **Particionamento** no S3 (ex.: `s3://bucket/tabela/ano=2025/mes=03/`)
- **Formato Parquet** (leitura colunar — escaneia apenas as colunas necessárias)
- **Filtrar partições cedo** nas queries

### Integridade referencial

No SQL Server, FKs garantem que um `cliente_id` em `operacoes` sempre exista em `clientes`.

No Athena, não há FKs. Se um `cliente_id` não existir em `clientes`, o LEFT JOIN
retorna NULL — mas sem erro. A integridade deve ser garantida pelo ETL Python.

---

## Exemplo de adaptação: Q2.3 (Evolução de rating)

**SQL Server:**

```sql
FORMAT(r.data_referencia, 'yyyy-MM')   AS ano_mes,
ROUND(AVG(CAST(er.nota AS FLOAT)), 2)  AS nota_media,
STDEV(er.nota)                         AS desvio
```

**Athena:**

```sql
DATE_FORMAT(r.data_referencia, '%Y-%m') AS ano_mes,
ROUND(AVG(CAST(er.nota AS DOUBLE)), 2)  AS nota_media,
STDDEV(er.nota)                         AS desvio
```

---

## Quando usar cada um

- **SQL Server local:** quando você não tem acesso à AWS, ou para desenvolvimento
  e testes antes de publicar em produção
- **Athena:** quando o volume de dados é grande, os dados já estão no S3,
  ou o BI de destino é o Amazon QuickSight

---

## Checklist de conclusão da etapa

- [ ] Conheço as 10 diferenças de sintaxe mais comuns
- [ ] Entendo a diferença de armazenamento (banco vs. S3)
- [ ] Sei adaptar uma query do SQL Server para Athena sem consultar documentação
- [ ] Avancei para `11_kpis_e_views_analiticas.md`
