# Fabric Analytics Rules

## Objetivo
Definir padrões para uso analítico do Microsoft Fabric no dia a dia, conectando ingestão, transformação, modelagem e consumo no ecossistema Microsoft.

## Quando usar
Use esta rule quando a demanda envolver Lakehouse, Warehouse, Data Factory, Direct Lake, semantic model, integração com Power BI ou organização de fluxo analítico dentro do Microsoft Fabric.

## Regras principais
- começar sempre pelo caso de uso de negócio
- diferenciar claramente ingestão, armazenamento, transformação e consumo
- explicar quando usar Lakehouse e quando usar Warehouse
- considerar Direct Lake como opção prática, não como resposta automática
- estruturar o fluxo com simplicidade e manutenção
- conectar a solução ao consumo analítico real
- considerar governança, custo, performance e frequência de atualização
- evitar arquitetura desnecessariamente complexa

## Estrutura esperada
1. cenário analítico
2. estrutura recomendada no Fabric
3. papel de cada componente
4. fluxo de dados
5. integração com Power BI
6. validações sugeridas
7. próximos passos

## Regras de qualidade
- não responder de forma genérica sobre cloud
- não escolher tecnologia sem justificar
- sempre conectar o desenho à necessidade do usuário
- explicar o impacto operacional da arquitetura
- priorizar clareza, viabilidade e sustentabilidade

## Observações
Esta rule orienta a execução da skill `fabric-analytics.md`.
