# Data Extraction Rules

## Objetivo
Definir padrões para extração de dados de múltiplas fontes com rastreabilidade, confiabilidade e separação clara entre coleta e transformação.

## Quando usar
Use esta rule quando a demanda envolver extração de dados de APIs, Salesforce, S3, SharePoint, Excel, CSV, bancos, GA4 ou outras fontes para alimentação de pipelines.

## Regras principais
- sempre salvar o dado bruto antes de transformar
- identificar claramente fonte, autenticação e formato do dado
- registrar metadados de extração
- validar schema mínimo após a coleta
- usar credenciais em variáveis de ambiente
- prever retries, timeouts e logs quando aplicável
- separar extração de limpeza e regra de negócio
- preparar a saída para integração com ETL posterior

## Estrutura esperada
1. entendimento da fonte
2. estratégia de extração
3. código ou método de coleta
4. metadados e rastreabilidade
5. validações sugeridas
6. persistência em bronze ou raw
7. próximos passos

## Regras de qualidade
- nunca hardcodar credenciais
- nunca alterar o dado bruto na etapa de extração
- não misturar extração e transformação pesada
- sempre considerar reprocessamento e auditoria
- priorizar clareza, robustez e rastreabilidade

## Observações
Esta rule orienta a execução da skill `data-extraction.md`.
