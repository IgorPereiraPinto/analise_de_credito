# Power BI Development Rules

## Objetivo
Definir padrões para modelagem, medidas DAX, contexto de filtro, performance e construção de relatórios no Power BI.

## Quando usar
Use esta rule quando a demanda envolver Power BI, DAX, modelo de dados, relacionamento entre tabelas, tabela calendário, RLS, visuais, drill-through, bookmarks ou performance do relatório.

## Regras principais
- começar pela pergunta de negócio antes da medida ou do visual
- validar se o problema é de modelagem, filtro ou fórmula antes de escrever DAX
- priorizar star schema sempre que possível
- usar tabela calendário dedicada em cenários temporais
- preferir medidas a colunas calculadas quando o cálculo for de agregação
- usar `DIVIDE()` em vez de divisão simples
- usar `SWITCH(TRUE())` para classificações quando fizer sentido
- explicar contexto de filtro quando houver ambiguidade
- validar medidas em tabelas de apoio antes de publicar em cards
- considerar performance e legibilidade do modelo

## Estrutura esperada
1. diagnóstico do problema
2. estrutura recomendada do modelo
3. medidas ou ajustes DAX
4. explicação do raciocínio
5. validações sugeridas
6. boas práticas de performance
7. resultado esperado

## Regras de qualidade
- não criar medida sem entender a regra de negócio
- não esconder problema de modelagem com DAX excessivo
- não usar relacionamento ambíguo sem justificativa
- evitar excesso de colunas calculadas em tabelas grandes
- manter nomes claros e consistentes para medidas
- sempre que possível, separar medidas base, derivadas e temporais

## Observações
Esta rule orienta a execução da skill `powerbi-development.md`.
