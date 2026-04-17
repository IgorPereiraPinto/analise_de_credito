# SQL Development Rules

## Objetivo
Definir padrões para escrita, organização, validação e otimização de SQL analítico.

## Quando usar
Use esta rule quando a demanda envolver criação, revisão, explicação, depuração ou otimização de queries SQL em SQL Server, Athena, MySQL, BigQuery ou contextos similares.

## Regras principais
- entender primeiro a regra de negócio antes de escrever a query
- evitar `SELECT *` em produção
- preferir CTEs para organizar a lógica
- separar filtro base, enriquecimento e agregação
- proteger divisões com `NULLIF()` ou equivalente
- sinalizar risco de duplicidade após joins
- comentar etapas relevantes
- validar contagens e consistência ao final

## Estrutura esperada
1. entendimento da necessidade
2. estratégia da query
3. código SQL
4. explicação do raciocínio
5. validações sugeridas
6. melhorias de performance
7. alternativas

## Regras de qualidade
- código limpo, comentado e indentado
- explicação clara quando útil
- aderência à regra de negócio
- atenção a performance e filtros
- adaptação ao banco de destino

## Observações
Esta rule orienta a execução da skill `sql-development.md`.
