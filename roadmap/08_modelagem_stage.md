# 08 — Modelagem STAGE

## Objetivo da etapa

Criar as views STAGE que enriquecem o dado bruto e preparam a base para os KPIs da camada DW.

---

## Entradas

- Camada RAW populada (etapa 07)
- `sql/sqlserver/02_stage_views.sql`

## Saídas

- 6 views STAGE funcionais, reutilizadas por todas as queries analíticas

---

## O que acontece na camada STAGE

A STAGE resolve os problemas que o RAW não trata:

1. Selecionar o snapshot mais recente (exposição e rating são históricos — o dashboard precisa do último)
2. Consolidar limites por cliente (há múltiplos tipos por cliente)
3. Converter rating alfanumérico em escala numérica (para poder calcular médias e variações)
4. Unir as 5 tabelas em uma visão 360° do cliente

---

## As 6 views STAGE e seus papéis

### vw_stage_escala_rating

Converte `AAA` → 17, `BB` → 6, etc. Sem essa conversão, não é possível calcular
médias, variações ou rankings de rating.

```sql
-- Exemplo de uso
SELECT AVG(nota) FROM vw_stage_escala_rating
JOIN ratings ON rating_interno = rating
```

### vw_stage_exposicao_recente

Filtra apenas a última posição de exposição por cliente (MAX de `data_referencia`).
Usado em todos os KPIs de snapshot de carteira.

### vw_stage_rating_recente

Último rating de cada cliente + nota numérica. Base para o score ponderado da carteira.

### vw_stage_limite_consolidado

Soma todos os limites ativos de um cliente e calcula a % de utilização.
Um cliente pode ter limite Global, Curto Prazo e Trade — a view consolida tudo.

### vw_stage_operacoes_ativas

Agrega operações ativas por cliente: quantidade, aprovado total, utilizado, taxa média.

### vw_stage_cliente_enriquecido

A view mais importante do pipeline. Une as 5 tabelas em uma linha por cliente,
com todos os campos necessários para qualquer análise. É a base da matriz de risco.

---

## Como executar

```sql
-- No SSMS, execute:
sql/sqlserver/02_stage_views.sql

-- Verifique se as views foram criadas:
SELECT name FROM sys.views WHERE name LIKE 'vw_stage%';
```

---

## Para reutilização

Se o novo case tem lógica temporal diferente (ex: exposição diária em vez de mensal),
ajuste a CTE `ultima_data` em `vw_stage_exposicao_recente`:

```sql
-- Ajuste conforme a granularidade do snapshot no seu case:
SELECT cliente_id, MAX(data_referencia) AS data_ref_max ...
```

---

## Checklist de conclusão da etapa

- [ ] As 6 views STAGE criadas sem erro
- [ ] `SELECT TOP 5 * FROM vw_stage_cliente_enriquecido` retorna dados coerentes
- [ ] Campos de % de utilização e % de descoberta com valores razoáveis
- [ ] Avancei para `09_modelagem_dw.md`
