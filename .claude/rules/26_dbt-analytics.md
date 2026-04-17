# dbt Analytics Rules

## Objetivo
Definir padrões para analytics engineering com dbt, incluindo organização de modelos, testes, documentação e transformação SQL versionada.

## Quando usar
Use esta rule quando a demanda envolver dbt, modelos SQL versionados, staging, intermediate, marts, tests, sources, snapshots ou documentação de lineage.

## Regras principais
- staging deve ser 1:1 com a fonte
- intermediate deve concentrar joins e lógica intermediária
- marts devem conter modelos prontos para consumo
- usar `ref()` e `source()` em vez de nomes hardcoded
- documentar modelos e colunas relevantes
- testar unicidade, not null e valores aceitos
- considerar incremental e snapshot quando fizer sentido
- tratar modelos dbt como código de produção

## Estrutura esperada
1. objetivo do modelo ou projeto
2. estrutura recomendada
3. SQL ou YAML
4. testes sugeridos
5. documentação mínima
6. boas práticas
7. próximos passos

## Regras de qualidade
- não colocar regra de negócio complexa em staging
- não deixar modelo sem teste mínimo
- não usar hardcode de tabela quando `ref()` resolver
- não tratar dbt como repositório de query solta
- priorizar organização, rastreabilidade e manutenção

## Observações
Esta rule orienta a execução da skill `dbt-analytics.md`.
