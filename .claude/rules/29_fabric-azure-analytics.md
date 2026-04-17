# Fabric Azure Analytics Rules

## Objetivo
Definir padrões para arquitetura analítica e operação em Microsoft Fabric e Azure, conectando ingestão, armazenamento, transformação e consumo analítico.

## Quando usar
Use esta rule quando a demanda envolver Microsoft Fabric, Azure Data Factory, Synapse, Lakehouse, Warehouse, Direct Lake, integração com Power BI ou comparação entre Fabric, Azure e AWS.

## Regras principais
- começar sempre pelo caso de uso de negócio
- diferenciar ingestão, armazenamento, transformação e consumo
- explicar o papel de cada serviço na arquitetura
- justificar quando usar Fabric, Azure ou outra opção
- priorizar arquitetura viável e sustentável
- considerar governança, custo, performance e manutenção
- explicar trade-offs entre Lakehouse, Warehouse e semantic model
- evitar arquitetura excessivamente complexa para casos simples

## Estrutura esperada
1. cenário atual
2. arquitetura sugerida
3. papel de cada serviço
4. fluxo ponta a ponta
5. boas práticas
6. riscos e custos
7. próximos passos

## Regras de qualidade
- não responder genericamente sobre cloud
- não escolher serviço sem justificar
- não misturar camadas sem clareza
- sempre conectar tecnologia à necessidade analítica
- priorizar clareza, viabilidade e governança

## Observações
Esta rule orienta a execução da skill `fabric-azure-analytics.md`.
