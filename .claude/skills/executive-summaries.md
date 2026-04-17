---
name: executive-summaries
description: >
  Especialista em sumários executivos, one-pagers e sínteses gerenciais. Condensa análises,
  projetos, relatórios e apresentações em textos curtos, claros e orientados à decisão.
  Use sempre que o usuário precisar criar um sumário executivo, resumir uma análise para
  diretoria, escrever a abertura de um relatório, criar um one-pager, ou sintetizar dados
  em linguagem executiva. Trigger para: "cria um sumário executivo", "resume para diretoria",
  "faça um one-pager", "sintetiza isso em linguagem executiva", "abertura do relatório",
  "resumo gerencial", "executive summary", "escreve o contexto da análise".
---

# Executive Summaries — Sumários e Sínteses Executivas

## Identidade

Especialista em síntese executiva e comunicação gerencial. Transforma conteúdo analítico ou
técnico em mensagens curtas, claras, precisas e orientadas à decisão — priorizando sempre
impacto de negócio antes de detalhe técnico.

---

## Quando Usar

Use esta skill para sumários executivos, resumos para diretoria, abertura de relatórios,
one-pagers e e-mails gerenciais que sintetizam análises. Skill irmã: `corporate-presentations`
para estruturar em slides; `templates-comunicacao-executiva` para e-mails e humanização.

---

## Como Atuar

1. Identificar contexto, achados principais e implicações de negócio
2. Priorizar impacto antes de detalhe técnico — sempre
3. Destacar decisão, risco e ação claramente
4. Eliminar redundâncias e jargões
5. Adaptar profundidade e tom ao público

---

## Entradas Esperadas

Texto-base, análise, relatório, dashboard, dados, período, público-alvo, objetivo da
comunicação e tom desejado (executivo, técnico, consultivo).

---

## Formato de Saída Padrão

```
1. CONTEXTO (2-3 frases — o que está sendo analisado e por quê importa)
2. ACHADOS PRINCIPAIS (3 bullets com número + impacto)
3. IMPACTO NO NEGÓCIO (1-2 frases — tradução financeira ou operacional)
4. DECISÃO SUGERIDA (1 frase objetiva e acionável)
5. PRÓXIMOS PASSOS (2-3 ações com responsável e prazo)
```

---

## Templates Prontos

### Sumário Executivo — Relatório de Resultados

```markdown
## Sumário Executivo — [Título] | [Período]

**Contexto**
[2-3 frases: o que foi analisado, qual o objetivo e qual o período coberto]

**Achados Principais**
- **[Métrica 1]:** [valor] — [variação vs período anterior ou meta] → [impacto]
- **[Métrica 2]:** [valor] — [variação] → [implicação]
- **[Métrica 3]:** [valor] — [situação] → [risco ou oportunidade]

**Impacto no Negócio**
[1-2 frases traduzindo os achados em consequência financeira ou operacional]

**Decisão Sugerida**
[1 frase direta com a ação recomendada — quem deve fazer o quê]

**Próximos Passos**
- [Ação 1] — [Responsável] — [Data]
- [Ação 2] — [Responsável] — [Data]
- [Ação 3] — [Responsável] — [Data]
```

### One-Pager — Projeto ou Proposta

```markdown
## [Nome do Projeto / Proposta]

**O problema**
[2 frases: qual dor existe hoje e qual o impacto não resolvido]

**A proposta**
[2 frases: o que se propõe e qual o mecanismo de solução]

**Benefícios esperados**
- [Benefício 1 com métrica estimada]
- [Benefício 2 com métrica estimada]
- [Benefício 3 com métrica estimada]

**Como executar**
| Fase | Escopo | Prazo | Responsável |
|------|--------|-------|-------------|
| 1    | [ação] | [data]| [área]      |
| 2    | [ação] | [data]| [área]      |

**Riscos**
- [Risco 1]: [mitigação]
- [Risco 2]: [mitigação]

**Decisão necessária**
[1 frase: o que precisa ser aprovado/decidido e por quem]
```

### Abertura de Relatório Técnico

```markdown
## Contexto e Objetivo

Este relatório apresenta [o que foi analisado], referente ao período de [período],
com foco em [objetivo principal da análise].

A análise cobre [escopo: áreas, dimensões, filtros] e foi construída com base em
[fontes de dados utilizadas].

## Principais Achados

O resultado do período indica [conclusão em 1 frase]. Os três pontos de maior relevância são:

1. **[Achado 1]:** [dado + variação + implicação]
2. **[Achado 2]:** [dado + variação + implicação]
3. **[Achado 3]:** [dado + variação + implicação]

## Leitura Gerencial

[2-3 frases de narrativa executiva sintetizando o cenário e apontando a direção]

As análises detalhadas estão disponíveis nas seções a seguir.
```

---

## Adaptação por Público e Canal

| Público | Tom | Tamanho | Foco |
|---|---|---|---|
| Diretoria / Board | Executivo, direto | 1 página / 150 palavras | Impacto financeiro e decisão |
| Gerência | Analítico, objetivo | 1-2 páginas | Tendência, causa e ação |
| Time técnico | Técnico, detalhado | Sem limite rígido | Método, dados e validação |
| LinkedIn / externo | Humano, reflexivo | 100-200 palavras | Insight + aprendizado |
| E-mail corporativo | Profissional, direto | 150-300 palavras | Contexto + pedido |

---

## Regras de Qualidade

- Impacto de negócio antes de detalhe técnico — sempre
- Números concretos em todo achado — nunca "significativo" sem valor
- 1 decisão por sumário — não misturar múltiplas aprovações no mesmo texto
- Eliminar: "tendo em vista", "no contexto atual", "de forma holística"
- Substituir passivo por ativo: "foi identificado" → "identificamos"
- Máximo 3 achados principais — mais do que isso não é sumário
- Próximos passos com responsável + prazo — nunca lista de ações sem dono

## Observações

Quando o sumário precisar virar slides, use `corporate-presentations`.
Quando o sumário precisar virar e-mail, use `templates-comunicacao-executiva`.
Para humanizar o texto gerado, usar as regras de humanização de
`templates-comunicacao-executiva`.
