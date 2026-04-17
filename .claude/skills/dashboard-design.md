---
name: visualizacao-storytelling-dashboards
description: >
  Especialista em visualização de dados, storytelling executivo e construção de dashboards
  interativos em HTML/CSS/JavaScript com Chart.js, Plotly e D3.js. Cobre design de layout,
  escolha de gráficos, hierarquia visual, narrativa executiva, KPI cards, filtros dinâmicos
  e export. Use sempre que o usuário pedir um dashboard HTML, gráfico interativo, layout de
  painel, estrutura visual para apresentação, wireframe de dashboard, Chart.js, storytelling
  de dados, ou qualquer tarefa de comunicação visual de dados. Trigger para: "cria um dashboard",
  "qual gráfico usar", "como estruturo essa apresentação", "faz um HTML com esses dados",
  "transforma essa análise em visual", "storytelling executivo".
---

# Visualização, Storytelling e HTML Dashboards

## Como Atuar
Organizar a informação com lógica visual, hierarquia, clareza e foco em decisão. Indicar
quais gráficos usar e por quê, como estruturar o layout, quais destaques aplicar e como
transformar dados em mensagem executiva. Construir código HTML completo quando solicitado.

---

## Formato de Saída Padrão

```
1. OBJETIVO DO PAINEL (o que precisa ser comunicado)
2. PÚBLICO E DECISÃO (para quem e qual ação espera-se)
3. ESTRUTURA VISUAL SUGERIDA (layout, hierarquia)
4. VISUAIS RECOMENDADOS (gráfico + justificativa)
5. SEQUÊNCIA NARRATIVA (começo, meio, fim)
6. CÓDIGO HTML (quando solicitado)
7. TEXTO EXECUTIVO (frases prontas para slides/cards)
```

---

## 1. Guia de Escolha de Gráfico

| Pergunta | Gráfico Ideal | Evitar |
|---|---|---|
| Evolução no tempo | Linha + área | Pizza para série temporal |
| Comparar categorias | Barras horizontais | Linha para categorias |
| Atingimento vs meta | Barras agrupadas + linha meta | Gauge isolado |
| Participação (poucos itens) | Donut (≤5 fatias) | Pizza com muitas fatias |
| Distribuição de valores | Histograma / Boxplot | Barras simples |
| Correlação entre variáveis | Scatter plot | Barras para correlação |
| Ranking | Barras horizontais ordenadas | Colunas para rankings longos |
| Variação positiva/negativa | Waterfall / Barras divergentes | Área para waterfall |
| KPI único | Card com variação e sparkline | Tabela para KPI único |
| Dados geográficos | Mapa coroplético | Barras para dado regional |

---

## 2. Template HTML Dashboard Executivo

```html
<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Dashboard — [Nome]</title>
<script src="https://cdnjs.cloudflare.com/ajax/libs/Chart.js/4.4.1/chart.umd.min.js"></script>
<style>
:root {
  --primary: #1a3a5c; --accent: #2ecc71; --danger: #e74c3c;
  --warning: #f39c12; --bg: #f0f4f8; --surface: #fff;
  --text: #2c3e50; --border: #dde3ea; --neutral: #7f8c8d;
}
* { box-sizing: border-box; margin: 0; padding: 0; }
body { font-family: 'Segoe UI', sans-serif; background: var(--bg); color: var(--text); }

.header { background: var(--primary); color: #fff; padding: 16px 28px;
  display: flex; justify-content: space-between; align-items: center; }
.header h1 { font-size: 1.15rem; font-weight: 600; }
.header .sub { font-size: 0.78rem; opacity: 0.7; }

.filters { background: var(--surface); padding: 10px 28px; display: flex;
  gap: 14px; align-items: center; border-bottom: 1px solid var(--border); flex-wrap: wrap; }
.filters select { padding: 6px 10px; border: 1px solid var(--border);
  border-radius: 6px; font-size: 0.83rem; cursor: pointer; }
.filters label { font-size: 0.8rem; color: var(--neutral); font-weight: 500; }

.kpi-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
  gap: 14px; padding: 18px 28px; }
.kpi-card { background: var(--surface); border-radius: 10px; padding: 18px;
  border-left: 4px solid var(--primary); box-shadow: 0 1px 4px rgba(0,0,0,.07); }
.kpi-card.green  { border-left-color: var(--accent); }
.kpi-card.red    { border-left-color: var(--danger); }
.kpi-card.orange { border-left-color: var(--warning); }
.kpi-label { font-size: 0.72rem; color: var(--neutral); text-transform: uppercase;
  letter-spacing: .04em; margin-bottom: 5px; }
.kpi-value { font-size: 1.7rem; font-weight: 700; color: var(--primary); }
.kpi-delta { font-size: 0.76rem; margin-top: 3px; }
.kpi-delta.up { color: var(--accent); } .kpi-delta.down { color: var(--danger); }

.charts-grid { display: grid; grid-template-columns: 2fr 1fr;
  gap: 14px; padding: 0 28px 18px; }
.chart-card { background: var(--surface); border-radius: 10px;
  padding: 18px; box-shadow: 0 1px 4px rgba(0,0,0,.07); }
.chart-title { font-size: 0.88rem; font-weight: 600; color: var(--primary);
  margin-bottom: 14px; padding-bottom: 8px; border-bottom: 1px solid var(--border); }
canvas { max-height: 260px; }

table { width: 100%; border-collapse: collapse; font-size: 0.83rem; }
th { background: var(--primary); color: #fff; padding: 9px 11px; text-align: left; font-weight: 500; }
td { padding: 8px 11px; border-bottom: 1px solid var(--border); }
tr:nth-child(even) td { background: #f7f9fc; }
tr:hover td { background: #eef2f7; }
.badge { padding: 2px 9px; border-radius: 12px; font-size: 0.72rem; font-weight: 600; }
.badge.green  { background: #d5f5e3; color: #1e8449; }
.badge.red    { background: #fde8e8; color: #c0392b; }
.badge.orange { background: #fef3cd; color: #b7770d; }

.table-card { background: var(--surface); border-radius: 10px;
  padding: 18px; margin: 0 28px 22px; box-shadow: 0 1px 4px rgba(0,0,0,.07); }
.footer { text-align: center; padding: 12px; font-size: 0.73rem;
  color: var(--neutral); border-top: 1px solid var(--border); }
@media (max-width: 768px) {
  .charts-grid { grid-template-columns: 1fr; }
  .kpi-grid    { grid-template-columns: 1fr 1fr; }
}
</style>
</head>
<body>

<header class="header">
  <div>
    <div class="sub">[Subtítulo / Área]</div>
    <h1>[Título do Dashboard]</h1>
  </div>
  <div style="font-size:.78rem;opacity:.7">Atualizado: <span id="ts"></span></div>
</header>

<div class="filters">
  <label>Período:</label>
  <select id="fPeriod" onchange="applyFilters()">
    <option value="all">Todos</option>
    <option value="Q1">Q1</option><option value="Q2">Q2</option>
    <option value="Q3">Q3</option><option value="Q4">Q4</option>
  </select>
  <label>Regional:</label>
  <select id="fRegional" onchange="applyFilters()">
    <option value="all">Todas</option>
    <option value="Sudeste">Sudeste</option>
    <option value="Sul">Sul</option>
  </select>
  <button onclick="resetFilters()"
    style="background:var(--primary);color:#fff;border:none;padding:6px 14px;border-radius:6px;cursor:pointer;font-size:.82rem">
    ↺ Resetar
  </button>
</div>

<div class="kpi-grid">
  <div class="kpi-card green">
    <div class="kpi-label">Receita Total</div>
    <div class="kpi-value" id="kv1">—</div>
    <div class="kpi-delta up" id="kd1">vs meta</div>
  </div>
  <div class="kpi-card">
    <div class="kpi-label">Meta</div>
    <div class="kpi-value" id="kv2">—</div>
    <div class="kpi-delta" id="kd2">atingimento</div>
  </div>
  <div class="kpi-card orange">
    <div class="kpi-label">Ticket Médio</div>
    <div class="kpi-value" id="kv3">—</div>
    <div class="kpi-delta" id="kd3">por pedido</div>
  </div>
  <div class="kpi-card">
    <div class="kpi-label">Pedidos</div>
    <div class="kpi-value" id="kv4">—</div>
    <div class="kpi-delta up" id="kd4">no período</div>
  </div>
</div>

<div class="charts-grid">
  <div class="chart-card">
    <div class="chart-title">📈 Evolução Mensal — Receita vs Meta</div>
    <canvas id="cEvolucao"></canvas>
  </div>
  <div class="chart-card">
    <div class="chart-title">🏆 Top Vendedores</div>
    <canvas id="cRanking"></canvas>
  </div>
</div>

<div class="charts-grid">
  <div class="chart-card">
    <div class="chart-title">🍩 Por Regional</div>
    <canvas id="cRegional"></canvas>
  </div>
  <div class="chart-card">
    <div class="chart-title">📊 Por Categoria</div>
    <canvas id="cCategoria"></canvas>
  </div>
</div>

<div class="table-card">
  <div class="chart-title">📋 Detalhe por Vendedor</div>
  <table>
    <thead><tr>
      <th>Vendedor</th><th>Regional</th><th>Receita</th>
      <th>Meta</th><th>Ating%</th><th>Status</th>
    </tr></thead>
    <tbody id="tBody"></tbody>
  </table>
</div>

<div class="footer">
  Dashboard — <span id="fdDate"></span> |
  <button onclick="exportCSV('tBody')"
    style="background:none;border:1px solid var(--border);padding:3px 10px;border-radius:4px;cursor:pointer;font-size:.72rem">
    ⬇ CSV
  </button>
</div>

<script>
// ── DADOS (substitua por fetch/API) ─────────────────────────────────────
const DATA = {
  meses: ['Jan','Fev','Mar','Abr','Mai','Jun','Jul','Ago','Set','Out','Nov','Dez'],
  receita: [480,520,610,590,680,720,650,700,760,810,870,920],
  meta:    [500,550,600,600,650,700,700,750,800,850,900,950],
  vendedores: [
    {nome:'Ana Silva',    regional:'Sudeste', receita:320000, meta:300000},
    {nome:'Carlos Lima',  regional:'Sul',     receita:280000, meta:290000},
    {nome:'Maria Santos', regional:'Norte',   receita:260000, meta:250000},
  ],
  regionais: ['Sudeste','Sul','Norte'], receitaRegional: [540,380,260],
  categorias: ['Produto A','Produto B','Produto C'], receitaCategoria: [40,35,25]
};

const COLORS = ['#1a3a5c','#2ecc71','#e74c3c','#f39c12','#9b59b6','#1abc9c'];
const fmt    = n => 'R$ ' + n.toLocaleString('pt-BR');
const pct    = n => (n*100).toFixed(1)+'%';
let charts   = {};

function buildCharts(d) {
  Object.values(charts).forEach(c => c.destroy());

  charts.ev = new Chart(document.getElementById('cEvolucao'), {
    type: 'bar',
    data: { labels: d.meses, datasets: [
      {label:'Receita (k)', data: d.receita, backgroundColor:'#1a3a5c', borderRadius:4},
      {label:'Meta (k)', data: d.meta, type:'line', borderColor:'#f39c12',
       borderWidth:2, pointRadius:3, fill:false, tension:0.3}
    ]},
    options: {responsive:true, plugins:{legend:{position:'top'}}, scales:{y:{beginAtZero:true}}}
  });

  const top = [...d.vendedores].sort((a,b) => b.receita - a.receita).slice(0,5);
  charts.rk = new Chart(document.getElementById('cRanking'), {
    type:'bar',
    data:{labels: top.map(v=>v.nome.split(' ')[0]),
          datasets:[{label:'Receita', data:top.map(v=>v.receita),
                     backgroundColor:COLORS, borderRadius:5}]},
    options:{indexAxis:'y', responsive:true, plugins:{legend:{display:false}}}
  });

  charts.re = new Chart(document.getElementById('cRegional'), {
    type:'doughnut',
    data:{labels:d.regionais, datasets:[{data:d.receitaRegional,
          backgroundColor:COLORS, borderWidth:2}]},
    options:{responsive:true, plugins:{legend:{position:'bottom'}}}
  });

  charts.ca = new Chart(document.getElementById('cCategoria'), {
    type:'bar',
    data:{labels:d.categorias, datasets:[{label:'%', data:d.receitaCategoria,
          backgroundColor:COLORS, borderRadius:4}]},
    options:{responsive:true, plugins:{legend:{display:false}}, scales:{y:{beginAtZero:true}}}
  });
}

function updateKPIs(d) {
  const r = d.receita.reduce((a,b)=>a+b,0)*1000;
  const m = d.meta.reduce((a,b)=>a+b,0)*1000;
  const a = r/m;
  document.getElementById('kv1').textContent = fmt(r);
  document.getElementById('kd1').textContent = pct(a)+' atingido';
  document.getElementById('kd1').className   = 'kpi-delta '+(a>=1?'up':'down');
  document.getElementById('kv2').textContent = fmt(m);
  document.getElementById('kd2').textContent = pct(a)+' de atingimento';
  document.getElementById('kv3').textContent = fmt(Math.round(r/d.receita.length/48));
  document.getElementById('kv4').textContent = (d.receita.length*48).toLocaleString('pt-BR');
}

function buildTable(v) {
  document.getElementById('tBody').innerHTML = v.map(x => {
    const a = x.receita/x.meta;
    const b = a>=1?'green':a>=0.8?'orange':'red';
    const s = a>=1?'Acima':a>=0.8?'No Prazo':'Abaixo';
    return `<tr><td><b>${x.nome}</b></td><td>${x.regional}</td>
      <td>${fmt(x.receita)}</td><td>${fmt(x.meta)}</td>
      <td>${pct(a)}</td><td><span class="badge ${b}">${s}</span></td></tr>`;
  }).join('');
}

function applyFilters() {
  let d = JSON.parse(JSON.stringify(DATA));
  const p = document.getElementById('fPeriod').value;
  const r = document.getElementById('fRegional').value;
  if (p !== 'all') {
    const rng = {Q1:[0,3],Q2:[3,6],Q3:[6,9],Q4:[9,12]};
    const [s,e] = rng[p];
    d.meses = DATA.meses.slice(s,e);
    d.receita = DATA.receita.slice(s,e);
    d.meta    = DATA.meta.slice(s,e);
  }
  if (r !== 'all') d.vendedores = DATA.vendedores.filter(v=>v.regional===r);
  updateKPIs(d); buildCharts(d); buildTable(d.vendedores);
}

function resetFilters() {
  document.getElementById('fPeriod').value = 'all';
  document.getElementById('fRegional').value = 'all';
  applyFilters();
}

function exportCSV(tbodyId) {
  const rows = [...document.querySelectorAll(`#${tbodyId} tr`)];
  const csv  = rows.map(r =>
    [...r.querySelectorAll('td')].map(c=>`"${c.innerText}"`).join(',')
  ).join('\n');
  const a = Object.assign(document.createElement('a'), {
    href: URL.createObjectURL(new Blob(['\uFEFF'+csv],{type:'text/csv'})),
    download: 'dados.csv'
  });
  a.click();
}

// Init
const now = new Date();
document.getElementById('ts').textContent    = now.toLocaleString('pt-BR');
document.getElementById('fdDate').textContent = now.toLocaleDateString('pt-BR');
applyFilters();
</script>
</body>
</html>
```

---

## 3. Princípios de Storytelling Executivo

```
ESTRUTURA NARRATIVA:
┌─ 1. SITUAÇÃO    → O que está acontecendo? (contexto, números-chave)
├─ 2. COMPLICAÇÃO → O que mudou ou preocupa? (desvio, problema, queda)
├─ 3. RESOLUÇÃO   → O que fazer? (recomendação, próximo passo)
└─ 4. EVIDÊNCIA   → Por quê? (gráfico, tabela, dado)

HIERARQUIA VISUAL:
  Nível 1 → Título e KPIs (responde "o que")
  Nível 2 → Gráficos principais (responde "onde" e "quanto")
  Nível 3 → Tabela de detalhe (responde "quem" e "por quê")
  Nível 4 → Filtros (responde "quando" e "qual contexto")
```

## Regras de Qualidade
- Nunca sugerir gráfico por estética — sempre ligar ao negócio
- Priorizar simplicidade, contraste e hierarquia
- Destruir charts antes de recriar: `chart.destroy()` evita memory leak
- Separar `const DATA = {...}` da lógica — facilita troca por API
- Testar responsividade (F12 → toggle device toolbar)
- Transformar visual em narrativa: começo (contexto), meio (desvio), fim (ação)
