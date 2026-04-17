# FAQ — Reutilização em outros cases de crédito

---

**Q: Posso usar este projeto para um case de crédito diferente, com outras tabelas?**

A: Sim. O projeto foi construído para ser portável. Se o novo case tem as mesmas entidades
(clientes, operações, ratings, limites, exposições), basta trocar o Excel e ajustar os
schemas no Python. Se o novo case tem entidades diferentes, você precisará também revisar
as views STAGE e DW.

---

**Q: O que exatamente precisa ser alterado para um novo case?**

A:

1. `data/raw/` — substitua o Excel pela nova fonte
2. `python/01_extract.py` — atualize `EXPECTED_SHEETS` com as abas e colunas do novo arquivo
3. `python/02_clean.py` — atualize `DTYPE_MAP` e `NULL_STRATEGY` para os campos do novo domínio
4. `python/03_validate.py` — atualize `VALIDATION_RULES` com as regras de negócio do novo case
5. `docs/regras_de_negocio.md` — atualize os benchmarks
6. `sql/sqlserver/00_ddl.sql` — ajuste os tipos e campos se a estrutura for diferente

---

**Q: Posso adaptar para uma fonte que não seja Excel (CSV, API, banco)?**

A: Sim. Altere apenas `01_extract.py`. O restante do pipeline não depende da fonte.
Para CSV: use `pd.read_csv()`. Para API: use `requests` + `pd.json_normalize()`.
Para banco: use `pd.read_sql()` com `pyodbc` ou `sqlalchemy`.

---

**Q: Como faço para usar apenas o SQL Server, sem Python?**

A: Execute `sql/sqlserver/00_ddl.sql` e carregue os dados manualmente via Import Wizard
do SSMS ou `BULK INSERT` direto do Excel exportado como CSV. Os scripts Python são opcionais
— eles apenas automatizam e validam a carga.

---

**Q: Posso conectar o Power BI direto nas views do SQL Server?**

A: Sim. No Power BI Desktop, use a conexão SQL Server, selecione o banco `credito_ibba`
e importe as views do prefixo `vw_kpi_*`. Elas já entregam os campos calculados prontos.

---

**Q: Como substituir o QuickSight por Power BI no ambiente AWS?**

A: Conecte o Power BI ao Athena via ODBC (driver Simba). Instale o driver Athena ODBC,
configure a string de conexão com as credenciais AWS, selecione o banco `credito_ibba`
no Glue e importe as views como no SQL Server.

---

**Q: As validações do Python são obrigatórias?**

A: Não para dados confiáveis. Se a fonte já tiver qualidade garantida, você pode pular
`03_validate.py`. No entanto, o relatório `validation_report.csv` é útil para auditoria
e documentação — recomenda-se manter ao menos para o primeiro run.

---

**Q: Como escalar para um portfólio real com milhões de registros?**

A: Use a versão Athena. Para a extração, substitua o Excel por um Glue Job que lê
diretamente do sistema fonte (core bancário, CRM, etc.) e grava Parquet no S3.
As views DW no Athena funcionam para qualquer volume — o custo é por scan de dados,
não por volume de registros.

---

**Q: Como atualizar o dashboard HTML com novos dados?**

A: O dashboard usa dados embutidos (JavaScript hardcoded). Para conectar a dados reais,
substitua os objetos `data` no JavaScript por chamadas a uma API ou por leitura de
um JSON gerado pelo Python. O script `04_export.py` pode ser facilmente estendido
para exportar um JSON além dos CSVs.
