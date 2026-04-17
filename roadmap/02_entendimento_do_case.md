# 02 — Entendimento do Case

## Objetivo da etapa

Entender o problema de negócio antes de tocar em qualquer dado ou código.
A análise de crédito tem vocabulário e lógica específicos — sem entender isso,
você corre o risco de construir algo tecnicamente correto mas analiticamente vazio.

---

## Entradas

- `case_analista_credito_ibba.md` — enunciado completo do case

---

## Saídas

- Clareza sobre o que o Comitê de Crédito precisa monitorar
- Lista dos KPIs prioritários antes de ver os dados
- Mapeamento das 5 tabelas e seus relacionamentos

---

## O problema de negócio

O banco precisa monitorar a saúde do seu portfólio de crédito corporativo. Isso envolve:

1. **Saber quanto está exposto por cliente** — e se essa exposição tem cobertura (garantia)
2. **Entender a qualidade de crédito** — via rating e PD (probabilidade de default)
3. **Controlar o uso dos limites** — para não ultrapassar o apetite de risco aprovado
4. **Identificar concentrações** — subsetores que representam risco sistêmico
5. **Agir preventivamente** — detectar clientes com múltiplos sinais de deterioração

---

## As 5 tabelas e seus papéis

| Tabela        | Papel no negócio                                          | Granularidade          |
|---------------|-----------------------------------------------------------|------------------------|
| `clientes`    | Quem são os clientes e como estão segmentados             | 1 linha por cliente    |
| `operacoes`   | Quais créditos foram aprovados e quanto foi usado         | 1 linha por operação   |
| `ratings`     | Como a qualidade de crédito evoluiu ao longo do tempo     | 1 linha por cliente/mês|
| `limites`     | Qual o teto de crédito aprovado por tipo de produto       | 1 linha por cliente/tipo|
| `exposicoes`  | Qual o risco total consolidado mensal por cliente         | 1 linha por cliente/mês|

---

## Conceitos de crédito que aparecem no projeto

**Exposição total:** soma de todos os créditos concedidos a um cliente. Pode ser maior
que a soma das operações porque inclui garantias prestadas, fianças e outros instrumentos.

**Exposição descoberta:** parcela da exposição que não tem garantia cobrindo. É o risco
líquido do banco — quanto ele perderia se o cliente não pagasse e não houvesse garantia.

**PD 12m (Probability of Default):** probabilidade de o cliente não honrar suas dívidas
nos próximos 12 meses. Vai de 0 (risco zero) a 1 (default certo).

**Rating interno:** classificação de risco do banco (AAA a C). Baseado em análise
financeira, comportamental e setorial.

**Limite de crédito:** teto aprovado para exposição com um cliente. Diferente de operação:
o limite é o teto total aprovado; a operação é o crédito específico contratado.

**Concentração:** quando um subsetor representa mais de 10-15% do portfólio, o banco
fica exposto a choques setoriais. A regulação (CMN) estabelece limites.

---

## O que o Comitê de Crédito precisa ver

1. Posição total do portfólio (exposição, garantias, provisão)
2. Qualidade de crédito (score médio ponderado, distribuição de rating)
3. Uso de limites (utilização média, clientes acima do threshold)
4. Concentração (subsetores críticos, risco sistêmico)
5. Alertas (clientes com deterioração e múltiplos fatores de risco)

---

## Arquivos envolvidos nesta etapa

- `case_analista_credito_ibba.md`
- `docs/dicionario_de_dados.md`
- `docs/regras_de_negocio.md`

---

## Checklist de conclusão da etapa

- [ ] Entendi o que é exposição total vs. descoberta
- [ ] Sei a diferença entre limite e operação
- [ ] Conheço o papel de cada uma das 5 tabelas
- [ ] Sei o que o Comitê de Crédito precisa monitorar
- [ ] Avancei para `03_analise_da_base_excel.md`
