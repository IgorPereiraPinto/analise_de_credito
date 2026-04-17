---
name: python-analytics
description: >
  Especialista em análise de dados e automação com Python. Cobre pandas, polars, numpy,
  matplotlib, seaborn, plotly, scipy, statsmodels, openpyxl, duckdb e automação de pipelines.
  Use sempre que o usuário pedir código Python para análise de dados, manipulação de
  DataFrames, visualizações, EDA, automação de planilhas, consolidação de arquivos,
  leitura de bases ou qualquer tarefa de data science com Python. Trigger para: "escreve
  um script Python", "analisa esse DataFrame", "cria um gráfico com plotly", "faz uma EDA",
  "automatiza essa planilha", "consolida esses arquivos", "manipula esse CSV", "pandas",
  "polars", "matplotlib", "seaborn".
---

# Python Analytics — Análise de Dados com Python

## Identidade

Especialista sênior em análise de dados com Python. Domina o ecossistema científico completo,
desde manipulação de DataFrames até visualização e automação de pipelines. Código sempre
funcional, comentado, tipado e pronto para produção.

---

## Quando Usar

Use esta skill para qualquer código Python voltado a dados: EDA, transformação, visualização,
automação de Excel, consolidação de arquivos, análise estatística descritiva e pipelines batch.
Para ML e forecasting, use `ml-forecasting`. Para ETL completo, use `etl-data-lake`.

---

## Stack Padrão

```python
# Core
import pandas as pd
import polars as pl
import numpy as np

# Visualização
import matplotlib.pyplot as plt
import seaborn as sns
import plotly.express as px
import plotly.graph_objects as go

# Estatística
from scipy import stats
import statsmodels.api as sm

# Performance e SQL in-process
import duckdb

# Automação de planilhas
import openpyxl
from openpyxl.styles import Font, PatternFill, Alignment
from openpyxl.utils.dataframe import dataframe_to_rows

# Utilitários
from pathlib import Path
from datetime import datetime
import warnings
warnings.filterwarnings('ignore')

# Configuração padrão de plots
plt.rcParams['figure.figsize'] = (12, 6)
plt.rcParams['font.size'] = 11
sns.set_theme(style='whitegrid', palette='muted')
```

---

## 1. EDA — Análise Exploratória Padrão

```python
def eda_completa(df: pd.DataFrame, target_col: str = None) -> pd.DataFrame:
    """
    EDA completa: qualidade, estatísticas descritivas e correlações.

    Args:
        df: DataFrame a ser analisado
        target_col: coluna alvo para análise de correlação (opcional)

    Returns:
        DataFrame com relatório de qualidade dos dados
    """
    print(f"{'='*60}")
    print(f"SHAPE: {df.shape[0]:,} linhas x {df.shape[1]} colunas")
    print(f"{'='*60}\n")

    # Relatório de qualidade
    quality = pd.DataFrame({
        'dtype':     df.dtypes,
        'nulos':     df.isna().sum(),
        'pct_nulos': (df.isna().mean() * 100).round(2),
        'unicos':    df.nunique(),
        'pct_unicos': (df.nunique() / len(df) * 100).round(2),
        'exemplo':   [df[c].dropna().iloc[0] if df[c].notna().any() else None
                      for c in df.columns]
    })
    print("📋 QUALIDADE DOS DADOS:")
    print(quality.to_string())

    # Estatísticas numéricas
    print("\n📊 ESTATÍSTICAS NUMÉRICAS:")
    print(df.describe(percentiles=[.05, .25, .5, .75, .95]).round(2).to_string())

    # Correlações com target
    if target_col and target_col in df.columns:
        print(f"\n🎯 CORRELAÇÕES COM '{target_col}':")
        corr = df.select_dtypes(include='number').corr()[target_col]
        print(corr.sort_values(ascending=False).to_string())

    return quality


def detectar_outliers(df: pd.DataFrame, col: str,
                      method: str = 'iqr') -> pd.DataFrame:
    """Detecta outliers via IQR ou Z-score."""
    if method == 'iqr':
        Q1, Q3 = df[col].quantile([0.25, 0.75])
        IQR = Q3 - Q1
        mask = (df[col] < Q1 - 1.5 * IQR) | (df[col] > Q3 + 1.5 * IQR)
    elif method == 'zscore':
        z = np.abs(stats.zscore(df[col].dropna()))
        mask = pd.Series(z > 3, index=df[col].dropna().index).reindex(df.index, fill_value=False)
    n = mask.sum()
    pct = n / len(df) * 100
    print(f"[{col}] {n} outliers ({pct:.1f}%) via {method.upper()}")
    return df[mask]
```

---

## 2. Manipulação de DataFrames — Padrões

```python
def add_time_features(df: pd.DataFrame, date_col: str) -> pd.DataFrame:
    """Adiciona features temporais derivadas de uma coluna de data."""
    df = df.copy()
    df[date_col] = pd.to_datetime(df[date_col])
    df['ano']         = df[date_col].dt.year
    df['mes']         = df[date_col].dt.month
    df['nome_mes']    = df[date_col].dt.month_name(locale='pt_BR.UTF-8')
    df['trimestre']   = df[date_col].dt.quarter
    df['semana_ano']  = df[date_col].dt.isocalendar().week.astype(int)
    df['dia_semana']  = df[date_col].dt.day_name()
    df['is_fds']      = df[date_col].dt.dayofweek >= 5
    df['ano_mes']     = df[date_col].dt.to_period('M').astype(str)
    return df


def safe_divide(numerator: pd.Series, denominator: pd.Series,
                fill: float = 0.0) -> pd.Series:
    """Divisão segura evitando ZeroDivisionError."""
    return numerator.div(denominator.replace(0, np.nan)).fillna(fill)


def normalizar_texto(series: pd.Series) -> pd.Series:
    """Normaliza strings: strip, upper, remove acentos."""
    return (series
        .astype(str)
        .str.strip()
        .str.upper()
        .str.normalize('NFKD')
        .str.encode('ascii', errors='ignore')
        .str.decode('ascii')
        .replace('NAN', np.nan))


def calcular_kpis_agrupados(df: pd.DataFrame, group_cols: list,
                             value_col: str, meta_col: str = None) -> pd.DataFrame:
    """KPIs comerciais agrupados por dimensões."""
    agg = df.groupby(group_cols).agg(
        total        = (value_col, 'sum'),
        media        = (value_col, 'mean'),
        mediana      = (value_col, 'median'),
        qtd          = (value_col, 'count'),
        desvio       = (value_col, 'std'),
    ).reset_index()

    agg['pct_total'] = safe_divide(agg['total'], agg['total'].sum()) * 100
    agg['pct_acum']  = agg['pct_total'].cumsum()

    if meta_col and meta_col in df.columns:
        meta = df.groupby(group_cols)[meta_col].sum().reset_index()
        agg  = agg.merge(meta, on=group_cols, how='left')
        agg['atingimento'] = safe_divide(agg['total'], agg[meta_col]) * 100

    return agg.sort_values('total', ascending=False).reset_index(drop=True)
```

---

## 3. Polars — Alta Performance em Grandes Volumes

```python
import polars as pl

def analise_polars(path: str, group_cols: list, value_col: str) -> pl.DataFrame:
    """
    Análise de alta performance com Polars (lazy evaluation).
    Ideal para arquivos > 500MB onde pandas fica lento.
    """
    return (
        pl.scan_parquet(path)          # lazy: não carrega tudo em memória
        .filter(pl.col('status') != 'CANCELADO')
        .filter(pl.col(value_col) > 0)
        .group_by(group_cols)
        .agg([
            pl.col(value_col).sum().alias('total'),
            pl.col(value_col).mean().alias('media'),
            pl.col(value_col).count().alias('qtd'),
            pl.col(value_col).std().alias('desvio'),
            pl.col('id_cliente').n_unique().alias('clientes_unicos'),
        ])
        .with_columns([
            (pl.col('total') / pl.col('total').sum().over(group_cols[0]) * 100)
                .alias('pct_grupo')
        ])
        .sort('total', descending=True)
        .collect()
    )
```

---

## 4. DuckDB — SQL Direto em DataFrames e Arquivos

```python
import duckdb

def query_df(df: pd.DataFrame, sql: str) -> pd.DataFrame:
    """Executa SQL diretamente em um DataFrame pandas — sem banco de dados."""
    return duckdb.execute(sql.replace('{df}', 'df')).df()

# Exemplos de uso:
# df_resultado = query_df(df_vendas, """
#     SELECT regional, SUM(valor_liquido) AS receita, COUNT(*) AS pedidos
#     FROM {df}
#     WHERE status <> 'CANCELADO'
#     GROUP BY regional
#     ORDER BY receita DESC
# """)

def query_parquet(path: str, sql: str) -> pd.DataFrame:
    """SQL direto em arquivos Parquet — ideal para análise de Data Lake local."""
    return duckdb.execute(
        sql.replace('{arquivo}', f"read_parquet('{path}')")
    ).df()
```

---

## 5. Visualizações Padrão

```python
def plot_evolucao(df: pd.DataFrame, x: str, y: str,
                  grupo: str = None, titulo: str = 'Evolução') -> None:
    """Gráfico de linha interativo com Plotly."""
    fig = px.line(df, x=x, y=y, color=grupo, title=titulo,
                  markers=True, template='plotly_white')
    fig.update_layout(hovermode='x unified', legend_title_text='')
    fig.show()


def plot_barras_meta(df: pd.DataFrame, categoria: str,
                     realizado: str, meta: str) -> None:
    """Barras agrupadas: Realizado vs Meta."""
    fig = go.Figure()
    fig.add_bar(x=df[categoria], y=df[realizado],
                name='Realizado', marker_color='#1a3a5c', marker_cornerradius=4)
    fig.add_bar(x=df[categoria], y=df[meta],
                name='Meta', marker_color='#f39c12', opacity=0.7)
    fig.update_layout(barmode='group', template='plotly_white',
                      title='Realizado vs Meta')
    fig.show()


def plot_heatmap_correlacao(df: pd.DataFrame, titulo: str = 'Correlações') -> None:
    """Heatmap de correlação com anotações."""
    corr = df.select_dtypes(include='number').corr()
    mask = np.triu(np.ones_like(corr, dtype=bool))
    fig, ax = plt.subplots(figsize=(10, 8))
    sns.heatmap(corr, mask=mask, annot=True, fmt='.2f',
                cmap='RdYlGn', center=0, vmin=-1, vmax=1,
                square=True, linewidths=0.5, ax=ax,
                cbar_kws={'shrink': 0.8})
    ax.set_title(titulo, fontsize=14, pad=12)
    plt.tight_layout()
    plt.show()


def plot_distribuicao(df: pd.DataFrame, col: str, grupo: str = None) -> None:
    """Histograma + boxplot lado a lado."""
    fig, axes = plt.subplots(1, 2, figsize=(14, 5))
    sns.histplot(data=df, x=col, hue=grupo, kde=True, ax=axes[0])
    sns.boxplot(data=df, x=grupo, y=col, ax=axes[1]) if grupo \
        else sns.boxplot(data=df, y=col, ax=axes[1])
    plt.suptitle(f'Distribuição de {col}', fontsize=13)
    plt.tight_layout()
    plt.show()
```

---

## 6. Automação de Excel com openpyxl

```python
def exportar_excel_estilizado(df: pd.DataFrame, path: str,
                              sheet_name: str = 'Dados') -> None:
    """
    Exporta DataFrame para Excel com formatação profissional.
    Header azul, zebra stripes, auto-largura de colunas.
    """
    wb = openpyxl.Workbook()
    ws = wb.active
    ws.title = sheet_name

    AZUL_ESCURO = 'FF1a3a5c'
    CINZA_CLARO = 'FFEBF1F5'
    header_fill = PatternFill(fill_type='solid', fgColor=AZUL_ESCURO)
    header_font = Font(color='FFFFFFFF', bold=True, size=10)
    zebra_fill  = PatternFill(fill_type='solid', fgColor=CINZA_CLARO)
    center      = Alignment(horizontal='center', vertical='center')

    # Escreve dados
    for r in dataframe_to_rows(df, index=False, header=True):
        ws.append(r)

    # Formata header
    for cell in ws[1]:
        cell.fill = header_fill
        cell.font = header_font
        cell.alignment = center

    # Auto-largura + zebra stripes
    for col_idx, col in enumerate(ws.columns, 1):
        max_len = max(len(str(cell.value or '')) for cell in col)
        ws.column_dimensions[col[0].column_letter].width = min(max_len + 4, 45)
        for row_idx, cell in enumerate(col, 1):
            if row_idx > 1 and row_idx % 2 == 0:
                cell.fill = zebra_fill

    # Freeze pane e filtros
    ws.freeze_panes = ws['A2']
    ws.auto_filter.ref = ws.dimensions

    wb.save(path)
    print(f"✅ Exportado: {path} | {len(df):,} linhas")


def consolidar_planilhas(pasta: str, padrao: str = '*.xlsx',
                          sheet_idx: int = 0) -> pd.DataFrame:
    """Consolida todas as planilhas de uma pasta em um único DataFrame."""
    arquivos = list(Path(pasta).glob(padrao))
    if not arquivos:
        raise FileNotFoundError(f"Nenhum arquivo '{padrao}' encontrado em '{pasta}'")

    dfs = []
    for arq in arquivos:
        try:
            df = pd.read_excel(arq, sheet_name=sheet_idx, engine='openpyxl')
            df['_arquivo']      = arq.name
            df['_importado_em'] = datetime.now()
            dfs.append(df)
            print(f"  ✅ {arq.name}: {len(df):,} linhas")
        except Exception as e:
            print(f"  ❌ {arq.name}: {e}")

    resultado = pd.concat(dfs, ignore_index=True) if dfs else pd.DataFrame()
    print(f"\n📦 Total: {len(resultado):,} linhas de {len(dfs)} arquivos")
    return resultado
```

---

## 7. Análise Estatística Aplicada

```python
def analise_series_temporal(df: pd.DataFrame, date_col: str,
                             value_col: str, freq: str = 'M') -> pd.DataFrame:
    """Resample + decomposição de série temporal."""
    from statsmodels.tsa.seasonal import seasonal_decompose

    df = df.copy()
    df[date_col] = pd.to_datetime(df[date_col])
    ts = df.set_index(date_col)[value_col].resample(freq).sum()

    # Decomposição (requer ≥ 2 ciclos completos)
    if len(ts) >= 24:
        decomp = seasonal_decompose(ts.dropna(), model='additive', period=12)
        fig, axes = plt.subplots(4, 1, figsize=(14, 10))
        for ax, serie, titulo in zip(axes,
            [decomp.observed, decomp.trend, decomp.seasonal, decomp.resid],
            ['Observado', 'Tendência', 'Sazonalidade', 'Resíduo']):
            serie.plot(ax=ax, title=titulo)
        plt.tight_layout()
        plt.show()

    # Estatísticas da série
    crescimento = ts.iloc[-1] / ts.iloc[0] - 1 if ts.iloc[0] != 0 else None
    print(f"Crescimento total: {crescimento:.1%}" if crescimento else "Crescimento: N/A")
    print(f"Média: {ts.mean():.2f} | Desvio: {ts.std():.2f} | CV: {ts.std()/ts.mean():.1%}")
    return ts


def regressao_linear(df: pd.DataFrame, x_cols: list,
                     y_col: str) -> object:
    """Regressão linear com statsmodels + interpretação."""
    X = sm.add_constant(df[x_cols].fillna(0))
    model = sm.OLS(df[y_col], X).fit()

    print(f"R² Ajustado: {model.rsquared_adj:.3f}")
    print(f"F-stat p-value: {model.f_pvalue:.4f}")
    sig = model.pvalues[model.pvalues < 0.05].index.tolist()
    print(f"Variáveis significativas (p<0.05): {sig}")
    return model
```

---

## Regras de Qualidade

- Código sempre funcional, com type hints e docstrings em funções públicas
- `df.copy()` antes de transformar — nunca modificar o DataFrame original
- `safe_divide()` em vez de `/` quando houver risco de divisão por zero
- `pathlib.Path` em vez de `os.path` para manipulação de arquivos
- Logging com `print(f"✅ ...")` em automações batch — nunca silencioso
- Polars para arquivos > 500MB; DuckDB para SQL in-process; pandas para padrão
- Nunca hardcodar paths absolutos — usar variáveis ou argumentos de função

## Observações

Para ETL e pipeline completo, use `etl-data-lake`.
Para Machine Learning e Forecast, use `ml-forecasting`.
Para automação com Power Automate, use `automacoes-power-platform`.
