# 13 — Apresentação Executiva

## Objetivo da etapa

Entender como o plano de implementação foi estruturado e como transformar os achados
analíticos em uma narrativa para tomada de decisão.

---

## Entradas

- `presentations/plano_implementacao_credito_bba.pptx`
- Resultados das queries e KPIs (etapas 11 e 12)

## Saídas

- Apresentação estruturada para o Comitê de Crédito
- Capacidade de adaptar o deck para outros cenários

---

## Estrutura do plano de implementação

O deck segue a estrutura de apresentação executiva com 5 blocos:

### Bloco 1 — Contexto e diagnóstico

Apresenta o portfólio atual com os KPIs principais.
Mensagem central: onde estamos hoje e qual é o tamanho da carteira.

### Bloco 2 — Análise de risco

Apresenta a matriz de risco, concentração por subsetor e evolução de rating.
Mensagem central: quais são os riscos identificados e qual é a severidade.

### Bloco 3 — Achados principais

3-5 insights concretos com números e impacto de negócio.
Ex.: "CLI862 está com utilização de 89% — acima do threshold de alerta de 85%"

### Bloco 4 — Recomendações

Ações concretas por categoria de risco.
Formato: ação → responsável → prazo → métrica de sucesso.

### Bloco 5 — Plano de monitoramento

Frequência de revisão por indicador, alertas automáticos propostos e roadmap de melhoria.

---

## Princípios para apresentação ao Comitê de Crédito

1. **Uma mensagem por slide** — o Comitê toma decisão rápida. Um slide com 4 mensagens
   dilui a prioridade

2. **Título conclusivo, não descritivo** — "Rating do Corporate deteriorou 3% no trimestre"
   é melhor que "Análise de Rating por Segmento"

3. **Número grande + contexto** — R$ 7,2 bilhões de exposição só tem significado se
   comparado ao limite aprovado ou ao período anterior

4. **Destaque o que precisa de decisão** — o Comitê não se reúne para ver dados bonitos.
   Se não há decisão, o slide não precisa existir

5. **Proponha, não apenas descreva** — cada achado deve ter uma recomendação associada

---

## Estrutura de narrativa para análise de crédito

```
CONTEXTO         → "O portfólio cresceu X% em 12 meses..."
ACHADO PRINCIPAL → "...mas 3 subsetores concentram 45% da exposição"
EVIDÊNCIA        → "Farmacêutico: R$1,07B | Software: R$821M | Varejo: R$700M"
RISCO            → "Choques setoriais simultâneos impactariam 45% da carteira"
RECOMENDAÇÃO     → "Revisão de limite para os 3 subsetores no próximo Comitê"
MÉTRICA          → "Meta: reduzir concentração para <40% em 2 trimestres"
```

---

## Checklist de conclusão da etapa

- [ ] Deck aberto e revisei a estrutura dos 5 blocos
- [ ] Cada slide tem uma mensagem clara e um número concreto
- [ ] As recomendações têm responsável e prazo
- [ ] Entendi como conectar achados analíticos a decisões executivas
- [ ] Avancei para `14_como_reutilizar_o_projeto.md`
