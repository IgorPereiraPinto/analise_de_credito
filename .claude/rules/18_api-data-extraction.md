# API Data Extraction Rules

## Objetivo
Definir padrões para extração de dados via API com confiabilidade, rastreabilidade e preparo para uso analítico.

## Quando usar
Use esta rule quando a demanda envolver APIs REST, autenticação, paginação, retries, rate limit, tratamento de JSON, integração com Python e ingestão de dados externos.

## Regras principais
- entender primeiro o objetivo da integração e o dado necessário
- identificar autenticação, endpoint, parâmetros, paginação e limites da API
- usar variáveis de ambiente para credenciais
- prever timeout, retry e tratamento de erro
- prever paginação e rate limit quando necessário
- validar o schema mínimo do retorno
- separar extração de transformação
- registrar metadados de extração sempre que possível

## Estrutura esperada
1. entendimento da integração
2. estratégia de extração
3. código Python
4. tratamento de paginação e erros
5. validações sugeridas
6. forma de persistência
7. próximos passos

## Regras de qualidade
- nunca hardcodar credenciais
- não assumir paginação inexistente sem validar
- não misturar regra de negócio complexa na etapa de extração
- sempre considerar rastreabilidade e reprocessamento
- priorizar código claro, robusto e reutilizável

## Observações
Esta rule orienta a execução da skill `api-data-extraction.md`.
