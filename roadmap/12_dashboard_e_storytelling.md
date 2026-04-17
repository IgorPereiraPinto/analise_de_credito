# 12 — Dashboard e Storytelling

## Objetivo da etapa

Entender a estrutura do dashboard HTML, como ele se conecta aos KPIs e como contar
a história certa para o Comitê de Crédito.

---

## Entradas

- `dashboards/dashboard_credito_bba.html`
- Resultados das queries analíticas (etapa 11)

## Saídas

- Dashboard aberto e funcional no navegador
- Entendimento da narrativa visual e de como adaptá-la para outros cases

---

## Estrutura do dashboard

O dashboard é um arquivo HTML single-file com três abas:

### Aba 1 — Visão Geral

Responde: qual é o estado atual do portfólio?

- KPIs superiores: exposição total, % descoberta, score ponderado, utilização de limites
- Gráfico de barras: distribuição por segmento
- Tabela resumida: top clientes por exposição

### Aba 2 — Análise de Riscos

Responde: onde estão os riscos e como estão evoluindo?

- Distribuição de rating (pizza ou barras)
- Concentração por subsetor (barras horizontais com threshold visual)
- Matriz de risco: tabela com código de cores por classificação

### Aba 3 — Performance de Limites

Responde: os limites estão bem dimensionados?

- Utilização por cliente (barras com linha de alerta em 85%)
- Tendência de rating por segmento (linha do tempo)
- Drill-down por produto

---

## Princípios de storytelling para o Comitê de Crédito

1. **Comece pelo status geral** — o Comitê precisa saber em 10 segundos se o portfólio
   está em zona segura ou de alerta

2. **Destaque o que está fora dos benchmarks** — não mostre tudo igual.
   Use vermelho/amarelo/verde para guiar o olhar

3. **Concentração é o risco mais importante** — um subsetor que representa 15%+
   da carteira deve aparecer em destaque, não enterrado em uma tabela

4. **Nomeie os clientes em alerta** — o Comitê precisa tomar decisões sobre pessoas,
   não sobre percentuais

5. **Mostre tendência, não só snapshot** — um portfolio que melhorou tem uma história
   diferente de um que deteriorou, mesmo com o mesmo score atual

---

## Como adaptar o dashboard para dados reais

O dashboard usa dados embutidos em JavaScript. Para conectar a dados reais:

1. Gere um JSON com `04_export.py` (adicione `EXPORT_FORMAT=json` no `.env`)
2. Substitua os objetos `data` no HTML por um `fetch()` ao JSON
3. Para produção com Power BI ou QuickSight, use as views `vw_kpi_*` diretamente

---

## Checklist de conclusão da etapa

- [ ] Dashboard aberto no navegador sem erros
- [ ] As 3 abas navegáveis e com dados
- [ ] Entendi a narrativa de cada aba
- [ ] Identifiquei como o dashboard conecta com as views DW
- [ ] Avancei para `13_apresentacao_executiva.md`
