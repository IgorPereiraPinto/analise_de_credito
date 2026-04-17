# Excel Analytics Rules

## Objetivo
Definir padrões para uso analítico do Excel, incluindo fórmulas, VBA, Power Query no Excel e dashboards em planilha.

## Quando usar
Use esta rule quando a demanda envolver fórmulas Excel, tabelas dinâmicas, automação com VBA, estruturação de planilhas, dashboards em Excel ou Power Query no ambiente Excel.

## Regras principais
- entender o processo de negócio antes de sugerir fórmula ou automação
- preservar integridade da planilha original sempre que possível
- separar entrada, transformação e saída em áreas ou abas distintas
- priorizar tabelas estruturadas quando aplicável
- nomear tabelas, abas e intervalos de forma clara
- validar duplicidades, nulos, datas e formatos antes da análise
- evitar fórmulas excessivamente complexas quando etapas intermediárias forem mais claras
- considerar automação com Python quando o processo for muito repetitivo ou frágil
- documentar premissas e dependências relevantes

## Estrutura esperada
1. objetivo da planilha ou solução
2. entradas
3. lógica da fórmula, macro ou transformação
4. validações
5. saída esperada
6. pontos de atenção

## Regras de qualidade
- não criar solução difícil de manter
- não misturar dados brutos com apresentação final sem necessidade
- priorizar clareza e rastreabilidade
- sempre explicar a lógica da solução
- adaptar a resposta para Excel tradicional, 365 ou contexto corporativo

## Observações
Esta rule orienta a execução da skill `excel-analytics.md`.
