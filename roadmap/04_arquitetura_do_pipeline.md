# 04 — Arquitetura do Pipeline

## Objetivo da etapa

Entender o desenho técnico do pipeline antes de executar qualquer script.
Saber por que cada camada existe e o que entra e sai de cada uma.

---

## Entradas

- Entendimento do case (etapas 02 e 03)

## Saídas

- Clareza sobre a arquitetura Medallion aplicada ao contexto de crédito
- Decisão de qual stack usar: SQL Server (local) ou Athena (AWS)

---

## A arquitetura Medallion no contexto deste projeto

O pipeline usa 3 camadas inspiradas na arquitetura Medallion (Bronze/Silver/Gold),
mapeadas para os nomes `raw`, `stage` e `dw`:

```text
FONTE       →   RAW (Bronze)    →   STAGE (Silver)   →   DW (Gold)
Excel           dado bruto          dado limpo            KPIs
                sem transformação   enriquecido           para consumo
```

### Por que 3 camadas e não uma query direta?

Com uma query direta do Excel para o dashboard, qualquer mudança na lógica exigiria
reescrever tudo. Com 3 camadas:

- A camada RAW é imutável — você sempre pode reprocessar a partir dela
- A camada STAGE concentra os joins e os campos calculados — fácil de manter
- A camada DW concentra a lógica de negócio — KPIs podem ser ajustados sem tocar no dado bruto

---

## O que cada camada faz neste projeto

### RAW

Dado bruto. Fiel à fonte. Apenas carga.

- No SQL Server: tabelas relacionais com PK, FK e índices
- No Athena: tabelas externas apontando para Parquet no S3
- **Regra:** nunca modifique a camada RAW após a carga

### STAGE

Dado enriquecido. Joins, campos calculados, filtros de snapshot.

Views criadas nesta camada:
- `vw_stage_escala_rating` — converte rating em nota numérica
- `vw_stage_exposicao_recente` — última posição de exposição por cliente
- `vw_stage_rating_recente` — último rating por cliente
- `vw_stage_limite_consolidado` — limite total com % de utilização
- `vw_stage_operacoes_ativas` — operações agregadas por cliente
- `vw_stage_cliente_enriquecido` — visão 360° unindo as 5 tabelas

### DW

KPIs prontos. Lógica de negócio. Camada semântica.

Views criadas nesta camada:
- `vw_kpi_exposicao` — posição total do portfólio
- `vw_kpi_por_segmento` — exposição e risco por segmento
- `vw_kpi_por_subsetor` — concentração com flag regulatório
- `vw_matriz_risco` — matriz de alerta combinado por cliente
- `vw_evolucao_rating_segmento` — série histórica de rating

---

## Qual stack usar: SQL Server ou Athena?

| Situação                           | Recomendação             |
|------------------------------------|--------------------------|
| Desenvolvimento local e portfólio  | SQL Server               |
| Produção em ambiente corporativo AWS| Athena                  |
| Dados < 10M linhas, sem AWS        | SQL Server               |
| Dados em S3, QuickSight como BI    | Athena                   |

Os dois caminhos produzem os mesmos KPIs. A diferença é o ambiente, não a lógica.

---

## Arquivos envolvidos

- `docs/arquitetura.md` — referência completa
- `sql/sqlserver/` — implementação SQL Server
- `sql/athena/` — implementação Athena

---

## Checklist de conclusão da etapa

- [ ] Entendi o papel das 3 camadas (RAW, STAGE, DW)
- [ ] Sei por que as camadas STAGE são views e não tabelas
- [ ] Escolhi qual stack usar (SQL Server ou Athena)
- [ ] Li `docs/arquitetura.md`
- [ ] Avancei para `05_etl_extracao.md`
