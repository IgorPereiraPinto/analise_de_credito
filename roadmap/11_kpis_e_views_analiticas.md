# 11 — KPIs e Views Analíticas

## Objetivo da etapa

Executar e interpretar as queries analíticas do case e entender como cada KPI
se conecta a uma decisão de negócio do Comitê de Crédito.

---

## Entradas

- Camada DW funcionando (etapa 09)
- `sql/sqlserver/04_queries_analiticas.sql`

## Saídas

- 6 queries executadas com resultados interpretados
- Entendimento de como cada KPI alimenta o dashboard

---

## As 6 queries e o que cada uma responde

### Q2.1 — Quem tem mais crédito aprovado e quanto usa?

Responde: quais clientes concentram mais exposição e estão mais próximos do alerta.

**KPI gerado:** `pct_utilizacao` por cliente.
**Alerta:** CLI862 com 89,4% de utilização — acima do threshold de 85%.

### Q2.2 — Qual subsetor concentra mais risco?

Responde: onde está a concentração que pode virar problema sistêmico.

**KPI gerado:** `pct_concentracao` e `pct_descoberta` por subsetor.
**Alerta:** subsetores com >10% de concentração entram em monitoramento.

### Q2.3 — Como a qualidade de crédito evoluiu ao longo do tempo?

Responde: qual segmento está melhorando ou piorando.

**KPIs gerados:** `nota_media`, `variacao_pct_mom`, `ranking_segmento_mes`.
**Insight:** Corporate ficou em 3º lugar em todos os 12 meses.

### Q2.4 — Quais clientes acumulam múltiplos fatores de risco?

Responde: quem precisa de atenção imediata.

**KPIs gerados:** `flag_deterioracao_rating`, `flag_utilizacao_alta`, `flag_descoberta_alta`,
`classificacao_risco`.
**Ação:** clientes ALTO_RISCO entram em revisão no Comitê.

### Q2.5 — Há exposições estatisticamente anômalas?

Responde: qual cliente está tão acima da média que distorce o portfólio.

**KPI gerado:** `zscore_exposicao` — clientes com Z > 2 são outliers.

### Q2.6 — O que os dados revelam além do enunciado?

Análises adicionais não pedidas no case:
- Concentração por setor (nível acima de subsetor)
- Operações vencidas — risco já materializado
- Score por segmento e porte — qualidade relativa

---

## Como conectar KPIs ao dashboard

| View / Query          | Visual no dashboard       | Decisão suportada                        |
|-----------------------|---------------------------|------------------------------------------|
| `vw_kpi_exposicao`    | Cards superiores          | Posição atual do portfólio               |
| `vw_kpi_ratings`      | Gauge / KPI card          | Qualidade de crédito da carteira         |
| `vw_kpi_por_subsetor` | Treemap / barras          | Concentração e diversificação            |
| `vw_matriz_risco`     | Tabela com cores          | Clientes que precisam de ação imediata   |
| `vw_evolucao_rating_segmento` | Linha do tempo  | Tendência de qualidade por segmento      |

---

## Checklist de conclusão da etapa

- [ ] Executei todas as 6 queries e obtive resultados
- [ ] Interpretei o resultado de cada query em termos de negócio
- [ ] Sei qual view alimenta qual visual no dashboard
- [ ] Avancei para `12_dashboard_e_storytelling.md`
