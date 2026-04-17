# Prompt Engineering Rules

## Objetivo
Definir padrões para criação, revisão e otimização de prompts e instruções para LLMs.

## Quando usar
Use esta rule quando a demanda envolver criação de prompt, melhoria de prompt existente, estruturação de instruções para Claude, ChatGPT, Copilot, Gemini ou organização de input e output para IA.

## Regras principais
- entender primeiro o objetivo real do prompt
- identificar ambiguidades, lacunas de contexto e saída mal definida
- estruturar o prompt com papel, contexto, tarefa, restrições e formato de resposta
- preferir instruções específicas e acionáveis
- adaptar o prompt ao tipo de tarefa: análise, SQL, escrita, extração, classificação, apresentação
- considerar o modelo e o ambiente onde o prompt será usado
- prever grounding quando o risco de alucinação for relevante
- prever formato de saída claro quando a consistência for importante

## Estrutura esperada
1. diagnóstico do prompt atual
2. objetivo real
3. prompt otimizado
4. explicação das melhorias
5. variante alternativa, quando útil

## Regras de qualidade
- não mudar o objetivo do usuário
- não deixar o prompt vago
- não exagerar no tamanho sem necessidade
- não usar instruções conflitantes
- sempre definir formato de saída quando isso aumentar a previsibilidade

## Observações
Esta rule orienta a execução da skill `prompt-engineering.md`.
