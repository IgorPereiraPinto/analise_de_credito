---
name: ml-forecasting
description: >
  Especialista em machine learning aplicado a negócios e forecasting de séries temporais.
  Cobre Prophet, XGBoost, scikit-learn, SHAP, regressão, classificação, clustering, segmentação
  RFM e avaliação de modelos. Use sempre que o usuário pedir previsão de vendas, forecast de
  demanda, modelo preditivo, classificação de clientes, segmentação, análise de churn, propensão,
  detecção de anomalias, ou qualquer aplicação de ML em dados de negócio. Trigger para: "prevê",
  "forecast de", "modelo preditivo", "classifica clientes", "segmenta", "propensão a",
  "churn model", "Prophet", "XGBoost", "sklearn", "clustering", "anomalia".
---

# ML & Forecasting — Machine Learning Aplicado a Negócios

## Identidade

Cientista de Dados com foco em ML aplicado a problemas reais de negócio. Prioriza modelos
interpretáveis, baselines simples antes de complexidade, e comunicação de resultados para
públicos não técnicos. Sempre usa SHAP para explicar predições ao negócio.

---

## Quando Usar

Use esta skill para forecasting (Prophet, XGBoost), classificação (churn, propensão),
segmentação (RFM + KMeans), regressão preditiva e anomalias. Para estatística descritiva
e A/B test, use `statistics-business-kpis`. Para análise exploratória Python, use
`python-analytics`.

---

## Regra de Ouro do ML de Negócio

```
1. Defina o problema de negócio → qual decisão o modelo vai apoiar?
2. Defina a métrica de sucesso → precisão, recall, MAPE, AUC?
3. Construa um baseline simples antes de qualquer modelo complexo
4. Valide temporalmente (TimeSeriesSplit) — nunca random split em séries
5. Explique com SHAP antes de apresentar ao negócio
6. Monitore o modelo em produção — dados mudam, modelos decaem
```

---

## 1. Forecast de Séries Temporais — Prophet (Meta)

```python
from prophet import Prophet
import pandas as pd
import matplotlib.pyplot as plt

def forecast_prophet(df: pd.DataFrame, date_col: str, value_col: str,
                     periods: int = 6, freq: str = 'M',
                     pais: str = 'BR') -> pd.DataFrame:
    """
    Forecast com Prophet da Meta.

    Args:
        df: DataFrame com coluna de data e valor
        date_col: nome da coluna de data
        value_col: nome da coluna de valor numérico
        periods: quantos períodos prever
        freq: frequência — 'D' dia, 'W' semana, 'M' mês, 'Q' trimestre
        pais: código do país para feriados (BR, US, etc.)

    Returns:
        DataFrame com previsão e intervalos de confiança
    """
    # Prepara no formato Prophet
    df_p = (df[[date_col, value_col]]
            .rename(columns={date_col: 'ds', value_col: 'y'})
            .assign(ds=lambda x: pd.to_datetime(x['ds'])))

    # Configura modelo
    model = Prophet(
        seasonality_mode='multiplicative',  # 'additive' para séries estáveis
        yearly_seasonality=True,
        weekly_seasonality=(freq == 'D'),   # só faz sentido para dados diários
        changepoint_prior_scale=0.1,        # 0.05 = rígido, 0.5 = flexível
        interval_width=0.80                 # intervalo de confiança 80%
    )
    model.add_country_holidays(country_name=pais)
    model.fit(df_p)

    # Previsão
    future   = model.make_future_dataframe(periods=periods, freq=freq)
    forecast = model.predict(future)

    # Visualização
    model.plot(forecast)
    plt.title(f'Forecast — próximos {periods} períodos ({freq})')
    plt.tight_layout()
    plt.show()

    model.plot_components(forecast)
    plt.show()

    # Retorna somente a previsão futura
    resultado = forecast[['ds', 'yhat', 'yhat_lower', 'yhat_upper']].tail(periods)
    resultado.columns = ['data', 'previsao', 'lim_inferior', 'lim_superior']
    return resultado
```

---

## 2. Forecast com XGBoost (Abordagem Supervisionada)

```python
import xgboost as xgb
from sklearn.model_selection import TimeSeriesSplit
from sklearn.metrics import mean_absolute_percentage_error, mean_squared_error
import numpy as np

def criar_features_lag(df: pd.DataFrame, col: str,
                        lags: list = [1, 2, 3, 6, 12]) -> pd.DataFrame:
    """Cria features de lag e rolling para modelo de série temporal."""
    df = df.copy()
    for lag in lags:
        df[f'{col}_lag{lag}'] = df[col].shift(lag)

    # Rolling statistics (usando shift para evitar data leakage)
    df[f'{col}_roll3_mean'] = df[col].shift(1).rolling(3).mean()
    df[f'{col}_roll6_mean'] = df[col].shift(1).rolling(6).mean()
    df[f'{col}_roll3_std']  = df[col].shift(1).rolling(3).std()
    df[f'{col}_roll12_max'] = df[col].shift(1).rolling(12).max()

    return df.dropna()


def treinar_xgb_forecast(df: pd.DataFrame, feature_cols: list,
                          target_col: str, n_splits: int = 5) -> xgb.XGBRegressor:
    """
    Treina XGBoost para forecast com TimeSeriesSplit.
    Usa validação temporal (nunca random split).
    """
    X, y = df[feature_cols], df[target_col]
    tscv = TimeSeriesSplit(n_splits=n_splits)

    scores_mape = []
    for fold, (train_idx, val_idx) in enumerate(tscv.split(X), 1):
        X_train, X_val = X.iloc[train_idx], X.iloc[val_idx]
        y_train, y_val = y.iloc[train_idx], y.iloc[val_idx]

        model = xgb.XGBRegressor(
            n_estimators=300, learning_rate=0.05,
            max_depth=5, subsample=0.8,
            colsample_bytree=0.8, random_state=42,
            early_stopping_rounds=20
        )
        model.fit(X_train, y_train,
                  eval_set=[(X_val, y_val)], verbose=False)

        mape = mean_absolute_percentage_error(y_val, model.predict(X_val))
        scores_mape.append(mape)
        print(f"  Fold {fold}: MAPE = {mape:.2%}")

    print(f"\nMAPE médio: {np.mean(scores_mape):.2%} ± {np.std(scores_mape):.2%}")

    # Treina no conjunto completo
    model_final = xgb.XGBRegressor(
        n_estimators=300, learning_rate=0.05,
        max_depth=5, subsample=0.8, random_state=42
    )
    model_final.fit(X, y)
    return model_final
```

---

## 3. Segmentação RFM + KMeans

```python
from sklearn.preprocessing import StandardScaler
from sklearn.cluster import KMeans
from sklearn.metrics import silhouette_score
import pandas as pd

def rfm_analise(df: pd.DataFrame, date_col: str, value_col: str,
                client_col: str, order_col: str,
                reference_date=None, n_clusters: int = 4) -> pd.DataFrame:
    """
    Segmentação de clientes via RFM + KMeans.

    Segmentos padrão (ajustar por domínio):
        0 = Campeões    → alta recência, alta frequência, alto valor
        1 = Leais       → frequentes, valor médio
        2 = Em Risco    → compraram antes, mas sumiram
        3 = Perdidos    → inativos e baixo valor
    """
    if reference_date is None:
        reference_date = pd.to_datetime(df[date_col]).max() + pd.Timedelta(days=1)

    # Calcula RFM
    rfm = (df.groupby(client_col)
             .agg(
                 recencia   = (date_col,  lambda x: (reference_date - pd.to_datetime(x).max()).days),
                 frequencia = (order_col, 'nunique'),
                 monetario  = (value_col, 'sum')
             ).reset_index())

    # Normaliza e clusteriza
    scaler     = StandardScaler()
    rfm_scaled = scaler.fit_transform(rfm[['recencia', 'frequencia', 'monetario']])

    # Elbow automático (testa k=2..8)
    inertias = {k: KMeans(n_clusters=k, random_state=42, n_init=10)
                   .fit(rfm_scaled).inertia_
                for k in range(2, 9)}

    kmeans = KMeans(n_clusters=n_clusters, random_state=42, n_init=10)
    rfm['cluster'] = kmeans.fit_predict(rfm_scaled)

    # Nomeia segmentos com base nas médias (ajuste se necessário)
    stats = (rfm.groupby('cluster')
                .agg(rec_med=('recencia', 'median'),
                     mon_med=('monetario', 'median'))
                .sort_values(['mon_med', 'rec_med'], ascending=[False, True]))

    labels = ['Campoes', 'Leais', 'Em Risco', 'Perdidos'][:n_clusters]
    mapa   = dict(zip(stats.index, labels))
    rfm['segmento'] = rfm['cluster'].map(mapa)

    # Resumo por segmento
    print(rfm.groupby('segmento')[['recencia', 'frequencia', 'monetario']].mean().round(1))
    return rfm
```

---

## 4. Classificação — Churn e Propensão

```python
from sklearn.ensemble import RandomForestClassifier, GradientBoostingClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import train_test_split, cross_val_score
from sklearn.metrics import classification_report, roc_auc_score, ConfusionMatrixDisplay
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler
import shap

def treinar_churn_model(X: pd.DataFrame, y: pd.Series,
                         test_size: float = 0.2) -> Pipeline:
    """
    Pipeline de classificação para churn com avaliação completa e SHAP.
    Compara Logistic Regression (baseline), Random Forest e Gradient Boosting.
    """
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=test_size, stratify=y, random_state=42)

    modelos = {
        'Logistic (baseline)': LogisticRegression(max_iter=1000, random_state=42),
        'Random Forest':       RandomForestClassifier(n_estimators=200, random_state=42),
        'Gradient Boosting':   GradientBoostingClassifier(n_estimators=200, random_state=42),
    }

    melhor_auc  = 0
    melhor_pipe = None

    for nome, clf in modelos.items():
        pipe = Pipeline([('scaler', StandardScaler()), ('model', clf)])
        cv_auc = cross_val_score(pipe, X_train, y_train, cv=5, scoring='roc_auc')
        pipe.fit(X_train, y_train)
        test_auc = roc_auc_score(y_test, pipe.predict_proba(X_test)[:, 1])

        print(f"\n{nome}:")
        print(f"  CV AUC: {cv_auc.mean():.3f} ± {cv_auc.std():.3f}")
        print(f"  Test AUC: {test_auc:.3f}")
        print(classification_report(y_test, pipe.predict(X_test)))

        if test_auc > melhor_auc:
            melhor_auc  = test_auc
            melhor_pipe = pipe

    print(f"\n✅ Melhor modelo: AUC = {melhor_auc:.3f}")

    # SHAP para interpretabilidade (Random Forest ou GBM)
    clf_final = melhor_pipe.named_steps['model']
    if hasattr(clf_final, 'feature_importances_'):
        explainer   = shap.TreeExplainer(clf_final)
        shap_values = explainer.shap_values(X_test)
        if isinstance(shap_values, list):
            shap_values = shap_values[1]  # classe positiva
        shap.summary_plot(shap_values, X_test, plot_type='bar',
                          max_display=15, show=True)

    return melhor_pipe
```

---

## 5. Detecção de Anomalias

```python
from sklearn.ensemble import IsolationForest
from sklearn.preprocessing import StandardScaler

def detectar_anomalias(df: pd.DataFrame, cols: list,
                        contamination: float = 0.05) -> pd.DataFrame:
    """
    Detecção de anomalias com Isolation Forest.
    contamination = % esperado de outliers (0.01 a 0.1)
    """
    df = df.copy()
    scaler = StandardScaler()
    X = scaler.fit_transform(df[cols].fillna(df[cols].median()))

    iso = IsolationForest(contamination=contamination,
                          n_estimators=200, random_state=42)
    df['anomalia']       = iso.fit_predict(X)
    df['anomalia_score'] = iso.score_samples(X)
    df['is_anomalia']    = df['anomalia'] == -1

    n_anomalias = df['is_anomalia'].sum()
    print(f"Anomalias detectadas: {n_anomalias} ({n_anomalias/len(df):.1%})")
    return df.sort_values('anomalia_score')
```

---

## 6. Métricas de Avaliação — Referência

```python
from sklearn.metrics import (
    mean_absolute_error, mean_squared_error, r2_score,
    mean_absolute_percentage_error, accuracy_score,
    precision_score, recall_score, f1_score, roc_auc_score
)

def avaliar_regressao(y_true, y_pred) -> dict:
    rmse = np.sqrt(mean_squared_error(y_true, y_pred))
    return {
        'MAE':  round(mean_absolute_error(y_true, y_pred), 4),
        'RMSE': round(rmse, 4),
        'MAPE': round(mean_absolute_percentage_error(y_true, y_pred), 4),
        'R2':   round(r2_score(y_true, y_pred), 4),
    }

def avaliar_classificacao(y_true, y_pred, y_proba=None) -> dict:
    result = {
        'Accuracy':  round(accuracy_score(y_true, y_pred), 4),
        'Precision': round(precision_score(y_true, y_pred, average='weighted'), 4),
        'Recall':    round(recall_score(y_true, y_pred, average='weighted'), 4),
        'F1':        round(f1_score(y_true, y_pred, average='weighted'), 4),
    }
    if y_proba is not None:
        result['AUC-ROC'] = round(roc_auc_score(y_true, y_proba), 4)
    return result
```

---

## Guia de Escolha do Algoritmo

| Problema de Negócio | Algoritmo Recomendado | Baseline Simples |
|---|---|---|
| Receita mensal (série temporal) | Prophet + XGBoost | Média móvel 3 meses |
| Demanda diária | XGBoost com lags + Prophet | Média histórica por dia |
| Churn / propensão | XGBoost / Random Forest | Regra de negócio (dias sem compra) |
| Segmentação de clientes | KMeans + RFM | Tercis de recência/valor |
| Detecção de anomalias | Isolation Forest | IQR ou Z-score |
| Preço ótimo | Regressão + otimização | Análise de elasticidade |
| Classificação de texto | TF-IDF + LogReg → BERT | Palavras-chave simples |

## Regras de Qualidade

- Sempre construir baseline simples antes de modelo complexo
- TimeSeriesSplit obrigatório para dados temporais — nunca random split
- SHAP obrigatório antes de apresentar ao negócio — ML sem explicação não vai
- Reportar MAPE para regressão, AUC para classificação — sempre incluir base rate
- Documentar premissas, período de treino e data de corte (cutoff)
- Alertar sobre data leakage, overfitting e viés de seleção sempre que relevante
