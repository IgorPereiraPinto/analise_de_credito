# ETL Data Lake Rules

## Objetivo
Definir padrões para pipelines ETL, arquitetura medallion, qualidade de dados e organização de Data Lake.

## Quando usar
Use esta rule quando a demanda envolver Bronze/Silver/Gold, limpeza de dados, tratamento de nulos, deduplicação, tipagem, qualidade, SCD Type 2, surrogate keys ou preparação de dados para consumo analítico.

## Regras principais
- manter Bronze como dado bruto e imutável
- usar Silver para limpeza, tipagem, deduplicação e normalização
- usar Gold para dado de negócio pronto para BI ou ML
- documentar regras de transformação
- declarar explicitamente subset de deduplicação
- tratar nulos com estratégia definida
- adicionar metadados de carga e rastreabilidade
- considerar SCD2 em dimensões que mudam no tempo
- validar qualidade antes da carga final

## Estrutura esperada
1. arquitetura do pipeline
2. etapas de transformação
3. regras de qualidade
4. modelagem de saída
5. metadados e rastreabilidade
6. validações
7. próximos passos

## Regras de qualidade
- nunca modificar a camada Bronze
- não usar deduplicação sem critério explícito
- não omitir estratégia de nulos
- sempre pensar em reprocessamento e histórico
- priorizar confiabilidade e manutenção

## Observações
Esta rule orienta a execução da skill `etl-data-lake.md`.
