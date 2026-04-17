# Power BI DAX — credito_bba

Medidas DAX organizadas por pasta de exibição (Display Folder) para o relatório de
análise de portfólio de crédito corporativo.

---

## Como usar

1. No Power BI Desktop, conecte ao banco `credito_ibba` (SQL Server) ou ao Athena
2. Importe as views das camadas STAGE e DW (`vw_stage_*` e `vw_kpi_*`)
3. Crie uma tabela vazia chamada `_Medidas` para organizar as medidas DAX
4. Copie cada bloco de medidas do arquivo `medidas_credito_bba.dax` para a tabela `_Medidas`
5. Defina o `Display Folder` de cada medida conforme indicado nos comentários

## Estrutura de pastas no modelo

```
_Medidas/
├── 0. Base/               → contadores e totalizadores fundamentais
├── 1. Exposição/          → exposição total, garantida, descoberta, provisão
├── 2. Ratings/            → score ponderado, PD, distribuição de rating
├── 3. Limites/            → limite total, utilização, alertas
├── 4. Operações/          → operações ativas, aprovado, taxa média
├── 5. Risco/              → matriz de risco, flags de alerta
├── 6. Concentração/       → concentração por subsetor e setor
├── 7. Tempo/              → variações MoM, YoY, médias móveis
└── 8. KPI Status/         → semáforos e classificações para formatação condicional
```

## Pré-requisitos no modelo

- Tabela `dCalendario` conectada às colunas de data (obrigatório para medidas de tempo)
- Relacionamentos ativos entre as tabelas via `cliente_id`
- Views importadas: `vw_stage_cliente_enriquecido`, `vw_kpi_exposicao`, `vw_matriz_risco`,
  `vw_evolucao_rating_segmento`, `vw_kpi_por_subsetor`

## Tabela Calendário

Use o arquivo `tabela_calendario.dax` para criar a `dCalendario` diretamente no Power BI.

---

## Benchmarks aplicados nas medidas

| KPI                      | Meta / Faixa ideal    | Alerta        | Crítico       |
|--------------------------|-----------------------|---------------|---------------|
| Score ponderado          | ≥ 800                 | 750–799        | < 650         |
| % Exposição descoberta   | < 30%                 | 30–40%        | > 40%         |
| % Utilização de limite   | 60–75%                | 75–85%        | > 85%         |
| Concentração subsetor    | < 10%                 | 10–15%        | > 15%         |
| PD 12m média             | < 1%                  | 1–3%          | > 3%          |
