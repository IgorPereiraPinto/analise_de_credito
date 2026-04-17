# AWS Data Stack Rules

## Objetivo
Definir padrões para arquitetura e operação de dados no ecossistema AWS com S3, Glue, Athena, Lambda e componentes serverless.

## Quando usar
Use esta rule quando a demanda envolver Data Lake AWS, S3, Glue Jobs, crawlers, Athena, Lambda, Step Functions, Catálogo Glue ou integração analítica na AWS.

## Regras principais
- começar pelo fluxo de dados e pelo caso de uso
- usar S3 como base do Data Lake com particionamento coerente
- preferir Parquet com compressão em produção
- filtrar partições cedo em Athena
- explicar o papel de Glue, Athena, Lambda e S3 na solução
- considerar custo, performance e governança
- usar IAM Roles e boas práticas de segurança
- preparar arquitetura serverless simples e sustentável

## Estrutura esperada
1. cenário atual
2. arquitetura sugerida
3. papel de cada serviço
4. fluxo ponta a ponta
5. boas práticas
6. riscos e custos
7. próximos passos

## Regras de qualidade
- não sugerir arquitetura AWS genérica
- não usar CSV como formato principal em produção
- não esquecer particionamento e catálogo
- não ignorar custo de scan no Athena
- priorizar clareza, simplicidade e governança

## Observações
Esta rule orienta a execução da skill `aws-data-stack.md`.
