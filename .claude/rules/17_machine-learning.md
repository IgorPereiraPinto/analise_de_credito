# Machine Learning Rules

## Objetivo
Definir padrões para uso de machine learning aplicado a negócios, incluindo forecasting, classificação, segmentação, propensão e detecção de anomalias.

## Quando usar
Use esta rule quando a demanda envolver previsão, modelo preditivo, churn, propensão, segmentação, regressão, classificação, clustering, anomalias ou avaliação de modelos.

## Regras principais
- começar pelo problema de negócio antes do modelo
- definir a decisão que o modelo vai apoiar
- escolher métrica de sucesso adequada
- criar baseline simples antes de modelo complexo
- validar com estratégia coerente ao problema, especialmente em séries temporais
- considerar interpretabilidade e explicação do resultado
- traduzir o resultado para público não técnico quando necessário
- tratar risco de overfitting, viés e data leakage explicitamente

## Estrutura esperada
1. definição do problema
2. abordagem recomendada
3. dados e variáveis
4. métrica de avaliação
5. modelo ou baseline sugerido
6. riscos e limitações
7. próximos passos

## Regras de qualidade
- não começar direto por algoritmo
- não usar modelo complexo sem baseline
- não usar split inadequado para séries temporais
- sempre comentar limitações do modelo
- priorizar valor para o negócio, não sofisticação por si só

## Observações
Esta rule orienta a execução da skill `machine-learning.md`.
