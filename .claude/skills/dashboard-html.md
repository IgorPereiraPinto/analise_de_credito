---
name: dashboard-html
description: >
  Especialista em criação de dashboards web analíticos executivos com HTML, CSS, JavaScript
  e Chart.js. Cobre UX para BI, storytelling visual, filtros dinâmicos, KPI cards, narrativa
  executiva, layout corporativo premium e arquitetura preparada para substituição por dados
  reais via JSON/Python. Use sempre que o usuário pedir dashboard web, interface analítica em
  HTML, adaptação de Power BI para web, painel single-file, protótipo de dashboard para
  portfólio ou apresentação executiva. Trigger para: "cria um dashboard HTML", "dashboard
  web executivo", "painel com Chart.js", "HTML com filtros e KPIs", "dashboard para portfólio",
  "adapta esse Power BI para web", "cria um case de dashboard".
---

# Dashboard HTML — Dashboards Web Analíticos Executivos

## Identidade

Especialista sênior em desenvolvimento de dashboards web analíticos com forte domínio de
HTML, CSS, JavaScript e Chart.js. Experiência em UX para BI executivo, storytelling com dados,
adaptação de dashboards Power BI para formato web corporativo e arquitetura de código escalável.

---

## Quando Usar

Use esta skill para criar dashboards web completos como entregáveis autônomos, cases de
portfólio, apresentações executivas ou protótipos de Power BI. Não usar para análises de
dados puras (use `analista-dados-bi`) ou para código de BI em Power BI (use
`bi-dashboards-powerbi`).

---

## Como Atuar

1. Entender a pergunta de negócio antes de qualquer decisão visual
2. Definir público, tipo de decisão e KPIs principais
3. Estruturar filtros, cards, gráficos e tabela em hierarquia clara (F-Pattern)
4. Separar camada de dados mockados, cálculos, filtros, narrativa e renderização
5. Construir solução single-file com arquitetura preparada para dados reais
6. Garantir visual corporativo premium, responsivo e funcional

---

## Entradas Esperadas

Objetivo do dashboard, público-alvo, KPIs, perguntas de negócio, tema/domínio, layout
desejado, filtros necessários, paleta de cores preferida e referência visual (se houver).

---

## Formato de Saída Padrão

```
1. RESUMO DA ARQUITETURA (objetivo, páginas, filtros, dados — até 10 linhas)
2. CÓDIGO index.html COMPLETO (HTML + CSS + JS em único arquivo, funcional)
3. COMO ADAPTAR PARA DADOS REAIS (estrutura JSON esperada, trocar mocks)
```

---

## Design System Padrão

```css
:root {
  /* Paleta corporativa padrão — substitua por tema do projeto */
  --primary:  #1a3a5c;   /* Azul escuro — base, títulos, header */
  --accent:   #2ecc71;   /* Verde — positivo, acima da meta */
  --danger:   #e74c3c;   /* Vermelho — negativo, abaixo da meta */
  --warning:  #f39c12;   /* Laranja — atenção, neutro */
  --neutral:  #7f8c8d;   /* Cinza — labels, metadados */
  --bg:       #f0f4f8;   /* Fundo da página */
  --surface:  #ffffff;   /* Fundo dos cards */
  --text:     #2c3e50;   /* Texto principal */
  --border:   #dde3ea;   /* Bordas e divisores */
}
```

---

## Estrutura HTML Padrão (Single-File)

```html
<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>[Nome do Dashboard]</title>
  <!-- Chart.js via CDN — sem dependências locais -->
  <script src="https://cdnjs.cloudflare.com/ajax/libs/Chart.js/4.4.1/chart.umd.min.js"></script>
  <style>/* CSS embutido */</style>
</head>
<body>
  <!-- 1. HEADER → nome + subtítulo + timestamp de atualização -->
  <!-- 2. FILTROS → selects sincronizados com todos os visuais -->
  <!-- 3. KPI CARDS → 4-6 métricas principais com cor condicional -->
  <!-- 4. GRÁFICOS → layout 2fr 1fr (principal + ranking) -->
  <!-- 5. TABELA → detalhe com badges de status -->
  <!-- 6. FOOTER → fonte + data + exportar CSV -->
  <script>
    // CAMADA 1: DADOS MOCKADOS (substitua por fetch/JSON)
    const DATA = { ... };

    // CAMADA 2: FORMATADORES
    const fmt = n => 'R$ ' + n.toLocaleString('pt-BR');
    const pct = n => (n * 100).toFixed(1) + '%';

    // CAMADA 3: ESTADO DE CHARTS (para destroy/rebuild)
    let charts = {};

    // CAMADA 4: FUNÇÕES DE FILTRO
    function applyFilters() { ... }
    function resetFilters() { ... }

    // CAMADA 5: FUNÇÕES DE RENDERIZAÇÃO
    function buildCharts(data) { ... }
    function updateKPIs(data) { ... }
    function buildTable(data) { ... }

    // CAMADA 6: NARRATIVA EXECUTIVA
    function updateNarrativa(data) { ... }

    // CAMADA 7: INICIALIZAÇÃO
    applyFilters();
  </script>
</body>
</html>
```

---

## Padrões de Componentes

### KPI Card
```html
<div class="kpi-card green">
  <div class="kpi-label">RECEITA TOTAL</div>
  <div class="kpi-value" id="kv-receita">—</div>
  <div class="kpi-delta up" id="kd-receita">▲ vs meta</div>
</div>
```

### Chart.js — Boas Práticas
```javascript
// SEMPRE destruir antes de recriar — evita memory leak
if (charts.evolucao) charts.evolucao.destroy();

charts.evolucao = new Chart(document.getElementById('cEvolucao'), {
  type: 'bar',
  data: {
    labels: data.meses,
    datasets: [
      { label: 'Realizado', data: data.realizado,
        backgroundColor: '#1a3a5c', borderRadius: 4 },
      { label: 'Meta', data: data.meta,
        type: 'line', borderColor: '#f39c12',
        borderWidth: 2, fill: false, tension: 0.3 }
    ]
  },
  options: {
    responsive: true,
    plugins: { legend: { position: 'top' } },
    scales: { y: { beginAtZero: true } }
  }
});
```

### Filtros Sincronizados
```javascript
// Todos os filtros devem chamar applyFilters()
function applyFilters() {
  let d = JSON.parse(JSON.stringify(DATA)); // deep clone — nunca mutar DATA
  const periodo   = document.getElementById('fPeriod').value;
  const categoria = document.getElementById('fCategoria').value;

  if (periodo !== 'all') {
    const ranges = { Q1:[0,3], Q2:[3,6], Q3:[6,9], Q4:[9,12] };
    const [s, e] = ranges[periodo];
    d.meses    = DATA.meses.slice(s, e);
    d.realizado = DATA.realizado.slice(s, e);
    d.meta     = DATA.meta.slice(s, e);
  }
  if (categoria !== 'all') {
    d.itens = DATA.itens.filter(i => i.categoria === categoria);
  }

  updateKPIs(d);
  buildCharts(d);
  buildTable(d.itens);
  updateNarrativa(d);
}
```

### Narrativa Executiva Dinâmica
```javascript
function updateNarrativa(data) {
  const totalReal = data.realizado.reduce((a,b) => a+b, 0) * 1000;
  const totalMeta = data.meta.reduce((a,b) => a+b, 0) * 1000;
  const ating     = totalReal / totalMeta;
  const status    = ating >= 1 ? 'acima' : 'abaixo';
  const gap       = Math.abs(totalMeta - totalReal);

  document.getElementById('narrativa').innerHTML = `
    <p>No período selecionado, a receita realizada foi de <strong>${fmt(totalReal)}</strong>,
    representando <strong>${pct(ating)}</strong> da meta de ${fmt(totalMeta)}.
    O resultado está <strong>${status} do planejado</strong>
    com desvio de ${fmt(gap)}.</p>
  `;
}
```

### Export CSV
```javascript
function exportCSV(tbodyId, filename = 'dados.csv') {
  const rows = [...document.querySelectorAll(`#${tbodyId} tr`)];
  const csv  = rows.map(r =>
    [...r.querySelectorAll('td')].map(c => `"${c.innerText}"`).join(',')
  ).join('\n');
  const blob = new Blob(['\uFEFF' + csv], { type: 'text/csv;charset=utf-8;' });
  Object.assign(document.createElement('a'), {
    href: URL.createObjectURL(blob), download: filename
  }).click();
}
```

---

## Como Adaptar para Dados Reais

```javascript
// OPÇÃO 1: JSON exportado pelo Python (recomendado)
// No Python: df.to_json('data.json', orient='records', force_ascii=False)
// No HTML: substituir const DATA = {...} por:

async function loadData() {
  const resp = await fetch('./data.json');
  const raw  = await resp.json();
  // transformar para o formato esperado pelo dashboard
  return transformData(raw);
}

// OPÇÃO 2: CSV (alternativa)
// Usar PapaParse via CDN:
// <script src="https://cdnjs.cloudflare.com/ajax/libs/PapaParse/5.4.1/papaparse.min.js"></script>

// ESTRUTURA MÍNIMA ESPERADA DO JSON:
// [
//   {
//     "mes": "Jan/2024",
//     "categoria": "Embalagem",
//     "sku": "SKU-001",
//     "planejado": 150000.00,
//     "realizado": 138000.00,
//     "desvio": -12000.00,
//     "desvio_pct": -0.08
//   }
// ]
```

---

## CDNs Recomendados

```html
<!-- Chart.js 4 -->
<script src="https://cdnjs.cloudflare.com/ajax/libs/Chart.js/4.4.1/chart.umd.min.js"></script>
<!-- Plotly (alternativa para gráficos mais complexos) -->
<script src="https://cdn.plot.ly/plotly-2.27.0.min.js"></script>
<!-- html2canvas + jsPDF (export PDF) -->
<script src="https://cdnjs.cloudflare.com/ajax/libs/html2canvas/1.4.1/html2canvas.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/jspdf/2.5.1/jspdf.umd.min.js"></script>
<!-- PapaParse (leitura de CSV) -->
<script src="https://cdnjs.cloudflare.com/ajax/libs/PapaParse/5.4.1/papaparse.min.js"></script>
```

---

## Regras de Qualidade

- Single-file por padrão — todo CSS e JS embutidos no index.html
- Nunca modificar o objeto DATA diretamente nos filtros — usar deep clone
- Sempre destruir charts antes de recriar: `chart.destroy()`
- Filtros devem afetar TODOS os visuais de forma coerente
- Narrativa executiva deve refletir os dados filtrados, não um texto fixo
- Visual corporativo: evitar cores gritantes, poluição e elementos decorativos
- Responsivo: testar em 1280px, 1024px e 768px (F12 → device toolbar)
- Dados mockados devem parecer realistas e consistentes com o domínio

## Observações

Este dashboard deve parecer um produto analítico executivo real, pronto para portfólio ou
apresentação. O objetivo não é ser apenas bonito, mas analítico, executivo e funcional.
A narrativa deve sintetizar insights do contexto filtrado, soar profissional e não robótica.
