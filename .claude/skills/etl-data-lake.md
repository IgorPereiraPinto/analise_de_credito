---
name: etl-data-lake
description: >
  Especialista em pipelines ETL e arquitetura de Data Lake. Cobre arquitetura medallion
  (Bronze/Silver/Gold), limpeza e validação de dados, deduplicação, tratamento de nulos,
  tipagem, SCD Type 2 com Surrogate Keys, qualidade de dados e organização de Data Lake em
  S3/OneLake. Use sempre que o usuário mencionar ETL, pipeline de dados, Data Lake, camadas
  de dados, limpeza, transformação, qualidade de dados, deduplicação, schema, SCD2, surrogate
  key, ou qualquer preparação e organização de dados. Trigger para: "cria um pipeline",
  "estrutura um ETL", "camadas Bronze Silver Gold", "limpa esses dados", "trata nulos",
  "remove duplicatas", "SCD2", "Data Lake", "qualidade de dados".
---

# ETL & Data Lake — Pipelines e Arquitetura Medallion

## Identidade

Engenheiro de Dados com foco em pipelines robustos, rastreáveis e escaláveis. Especialista
em arquitetura medallion (Bronze/Silver/Gold), qualidade de dados e modelagem dimensional com
SCD Type 2 — fundação para análises financeiras, operacionais e estratégicas confiáveis ao
longo do tempo.

---

## Arquitetura Medallion — Princípio

```
Bronze (Raw)
  → Dado exatamente como chegou da fonte
  → Nunca alterar — é o backup e auditoria
  → Particionado por data de carga

Silver (Trusted/Clean)
  → Dado limpo, tipado, deduplicado, normalizado
  → Regras de negócio básicas aplicadas
  → Particionado por data de negócio (data_venda, data_pedido)

Gold (Business/Serving)
  → Dado agregado, modelado e pronto para BI/ML
  → Star schema, KPIs pré-calculados, dimensões históricas (SCD2)
  → Otimizado para consulta (Parquet + ZORDER)
```

---

## 1. Pipeline ETL Padrão (Classe Base)

```python
import pandas as pd
import numpy as np
from datetime import datetime
from pathlib import Path
from abc import ABC, abstractmethod
import logging
import hashlib
import json

logger = logging.getLogger(__name__)

class ETLPipeline(ABC):
    """
    Classe base para todos os pipelines deste projeto.
    Herdar e implementar extract(), transform() e load().
    """

    def __init__(self, source_name: str, env: str = 'prod'):
        self.source_name = source_name
        self.env         = env
        self.run_id      = datetime.now().strftime('%Y%m%d_%H%M%S')
        self.stats       = {}

    @abstractmethod
    def extract(self) -> pd.DataFrame:
        ...

    @abstractmethod
    def transform(self, df: pd.DataFrame) -> pd.DataFrame:
        ...

    @abstractmethod
    def load(self, df: pd.DataFrame) -> None:
        ...

    def validate(self, df: pd.DataFrame, rules: dict) -> bool:
        """Valida regras de qualidade. Retorna False se regra crítica falhar."""
        falhas = []
        for col, rule in rules.items():
            if col not in df.columns:
                falhas.append(f"COLUNA AUSENTE: {col}")
                continue
            if rule.get('not_null') and df[col].isna().any():
                pct = df[col].isna().mean() * 100
                falhas.append(f"NULOS: {col} ({pct:.1f}%)")
            if 'min' in rule and (df[col] < rule['min']).any():
                falhas.append(f"VALOR ABAIXO DO MÍNIMO: {col} < {rule['min']}")
            if 'values' in rule:
                invalidos = ~df[col].isin(rule['values'])
                if invalidos.any():
                    falhas.append(f"VALORES INVÁLIDOS: {col} → {df[col][invalidos].unique()[:5].tolist()}")

        if falhas:
            for f in falhas:
                logger.error(f"[VALIDATE] ❌ {f}")
            return False

        logger.info(f"[VALIDATE] ✅ {len(rules)} regras OK")
        return True

    def run(self) -> bool:
        logger.info(f"[START] {self.source_name} | run_id={self.run_id} | env={self.env}")
        try:
            df = self.extract()
            self.stats['rows_extracted'] = len(df)

            df = self.transform(df)
            self.stats['rows_transformed'] = len(df)

            self.load(df)
            self.stats['rows_loaded'] = len(df)

            logger.info(f"[END] ✅ {self.source_name} | stats={self.stats}")
            return True

        except Exception as e:
            logger.error(f"[FAIL] ❌ {self.source_name} | erro={e}")
            raise
```

---

## 2. Transformações Silver — Limpeza Padrão

```python
class SilverTransformer:
    """Conjunto de transformações padrão para a camada Silver."""

    @staticmethod
    def clean_column_names(df: pd.DataFrame) -> pd.DataFrame:
        """Normaliza nomes de colunas: snake_case, sem caracteres especiais."""
        df.columns = (df.columns
            .str.strip()
            .str.lower()
            .str.replace(r'[\s\-/\\]', '_', regex=True)
            .str.replace(r'[^\w]', '', regex=True)
            .str.replace(r'_{2,}', '_', regex=True))
        return df

    @staticmethod
    def infer_and_cast_types(df: pd.DataFrame) -> pd.DataFrame:
        """Inferência e conversão automática de tipos."""
        for col in df.select_dtypes(include='object').columns:
            # Tenta numérico (BR: vírgula como decimal)
            try:
                converted = df[col].str.replace(',', '.', regex=False).apply(
                    pd.to_numeric, errors='coerce')
                if converted.notna().mean() > 0.8:  # 80% convertido = numérico
                    df[col] = converted
                    continue
            except (AttributeError, TypeError):
                pass
            # Tenta datetime
            try:
                converted = pd.to_datetime(df[col], dayfirst=True, errors='coerce')
                if converted.notna().mean() > 0.8:
                    df[col] = converted
            except Exception:
                pass
        return df

    @staticmethod
    def treat_nulls(df: pd.DataFrame,
                    num_strategy: str = 'median',
                    cat_fill: str = 'NAO_INFORMADO') -> pd.DataFrame:
        """Estratégia padrão de tratamento de nulos por tipo de coluna."""
        df = df.copy()
        for col in df.select_dtypes(include='number').columns:
            null_pct = df[col].isna().mean()
            if null_pct == 0:
                continue
            if null_pct < 0.30:
                fill_val = df[col].median() if num_strategy == 'median' else df[col].mean()
                df[col] = df[col].fillna(fill_val)
            else:
                # Alta proporção de nulos → flag de nulo + zerar
                df[f'{col}_is_null'] = df[col].isna().astype(int)
                df[col] = df[col].fillna(0)

        for col in df.select_dtypes(include=['object', 'string']).columns:
            df[col] = df[col].fillna(cat_fill)

        return df

    @staticmethod
    def deduplicate(df: pd.DataFrame, subset: list = None,
                    keep: str = 'last') -> pd.DataFrame:
        """Remove duplicatas com log de quantas foram removidas."""
        before = len(df)
        df = df.drop_duplicates(subset=subset, keep=keep)
        removed = before - len(df)
        if removed > 0:
            logger.warning(f"[DEDUP] {removed:,} duplicatas removidas ({removed/before:.1%})")
        return df.reset_index(drop=True)

    @staticmethod
    def clean_text(series: pd.Series) -> pd.Series:
        """Padroniza strings: strip, upper, remove acentos."""
        return (series.astype(str)
            .str.strip().str.upper()
            .str.normalize('NFKD')
            .str.encode('ascii', errors='ignore').str.decode('ascii')
            .replace('NAN', np.nan))

    @staticmethod
    def clean_currency(series: pd.Series) -> pd.Series:
        """Converte strings de moeda brasileira para float."""
        return (series.astype(str)
            .str.replace('R$', '', regex=False)
            .str.replace('.', '', regex=False)
            .str.replace(',', '.', regex=False)
            .str.strip()
            .apply(pd.to_numeric, errors='coerce'))

    @staticmethod
    def add_etl_metadata(df: pd.DataFrame, source: str, run_id: str) -> pd.DataFrame:
        """Adiciona metadados de rastreabilidade obrigatórios."""
        df['_etl_source']    = source
        df['_etl_run_id']    = run_id
        df['_etl_loaded_at'] = datetime.now()
        return df

    @staticmethod
    def compute_row_hash(df: pd.DataFrame, cols: list) -> pd.Series:
        """Gera hash MD5 das colunas especificadas (usado em SCD2)."""
        return df[cols].apply(
            lambda row: hashlib.md5(
                '|'.join(str(v) for v in row).encode()
            ).hexdigest(),
            axis=1
        )
```

---

## 3. SCD Type 2 — Versionamento de Dimensões

```python
def aplicar_scd2(df_new: pd.DataFrame, df_hist: pd.DataFrame,
                  natural_key: str, sk_col: str = 'sk',
                  track_cols: list = None) -> pd.DataFrame:
    """
    Aplica SCD Type 2 para manter histórico de dimensões.

    Conceito: cada alteração em colunas monitoradas (track_cols) gera
    uma nova versão do registro. O registro anterior é fechado
    (valid_to = hoje, is_current = False).

    Args:
        df_new:      DataFrame com os novos dados da dimensão
        df_hist:     DataFrame com o histórico atual (Silver/Gold)
        natural_key: chave natural da entidade (ex: id_cliente)
        sk_col:      nome da surrogate key (PK do DW)
        track_cols:  colunas a monitorar (se None, monitora tudo)

    Returns:
        DataFrame com histórico atualizado (SCD2 aplicado)
    """
    hoje = datetime.now().date()
    DATE_MIN = pd.Timestamp('1900-01-01').date()
    DATE_MAX = pd.Timestamp('9999-12-31').date()

    if track_cols is None:
        track_cols = [c for c in df_new.columns
                      if c not in [natural_key] + [sk_col]]

    # Adiciona hash das colunas monitoradas
    df_new  = df_new.copy()
    df_hist = df_hist.copy() if not df_hist.empty else pd.DataFrame(columns=df_new.columns)

    df_new['_row_hash']  = SilverTransformer.compute_row_hash(df_new, track_cols)

    if not df_hist.empty:
        df_hist['_row_hash'] = SilverTransformer.compute_row_hash(df_hist, track_cols)

    # Registros atuais do histórico
    atuais = df_hist[df_hist.get('is_current', pd.Series(True, index=df_hist.index))]

    # Detecta mudanças
    merged = df_new.merge(
        atuais[[natural_key, '_row_hash']].rename(columns={'_row_hash': '_hash_hist'}),
        on=natural_key, how='left'
    )
    novos        = merged[merged['_hash_hist'].isna()]          # nunca visto
    modificados  = merged[merged['_row_hash'] != merged['_hash_hist']]  # mudou

    linhas_novas = pd.concat([novos, modificados], ignore_index=True)

    # Fecha registros antigos (is_current = False, valid_to = hoje)
    if not df_hist.empty and len(modificados) > 0:
        nk_modificados = modificados[natural_key].values
        df_hist.loc[
            df_hist[natural_key].isin(nk_modificados) &
            df_hist.get('is_current', True),
            ['is_current', 'valid_to']
        ] = [False, hoje]

    # Prepara novas linhas com metadados SCD2
    if len(linhas_novas) > 0:
        linhas_novas = linhas_novas.drop(columns=['_hash_hist'], errors='ignore')
        linhas_novas['valid_from'] = hoje
        linhas_novas['valid_to']   = DATE_MAX
        linhas_novas['is_current'] = True
        # Gera SK sequencial
        max_sk = df_hist[sk_col].max() if not df_hist.empty and sk_col in df_hist else 0
        linhas_novas[sk_col] = range(int(max_sk) + 1,
                                      int(max_sk) + 1 + len(linhas_novas))

    resultado = pd.concat([df_hist, linhas_novas], ignore_index=True)
    logger.info(f"[SCD2] Novos: {len(novos)} | Modificados: {len(modificados)} | "
                f"Total histórico: {len(resultado)}")
    return resultado
```

---

## 4. Data Quality Report

```python
def data_quality_report(df: pd.DataFrame,
                          rules: dict = None) -> pd.DataFrame:
    """
    Gera relatório completo de qualidade de dados.

    Args:
        df: DataFrame a avaliar
        rules: dict de regras no formato {coluna: {not_null, min, max, values}}
    """
    report = []
    for col in df.columns:
        s = df[col]
        row = {
            'coluna':     col,
            'tipo':       str(s.dtype),
            'total':      len(s),
            'nulos':      s.isna().sum(),
            'pct_nulos':  round(s.isna().mean() * 100, 2),
            'unicos':     s.nunique(),
            'pct_unicos': round(s.nunique() / len(s) * 100, 2),
            'min':        s.min() if pd.api.types.is_numeric_dtype(s) else None,
            'max':        s.max() if pd.api.types.is_numeric_dtype(s) else None,
            'media':      round(s.mean(), 4) if pd.api.types.is_numeric_dtype(s) else None,
            'amostra':    str(s.dropna().iloc[:3].tolist()) if s.notna().any() else '',
        }
        # Avalia regras se fornecidas
        if rules and col in rules:
            rule    = rules[col]
            passou  = True
            if rule.get('not_null') and row['pct_nulos'] > 0:
                passou = False
            if 'min' in rule and row['min'] is not None and row['min'] < rule['min']:
                passou = False
            row['status_regra'] = '✅ OK' if passou else '❌ FALHA'
        report.append(row)

    df_report = pd.DataFrame(report).sort_values('pct_nulos', ascending=False)
    print(df_report.to_string(index=False))
    return df_report
```

---

## 5. Organização do Data Lake S3

```
s3://empresa-datalake-prod/
├── bronze/
│   └── {fonte}/{entidade}/year={YYYY}/month={MM}/day={DD}/
│       └── {entidade}_{YYYYMMDD_HHMMSS}.parquet
│
├── silver/
│   └── {entidade}/year={YYYY}/month={MM}/
│       └── {entidade}_clean.parquet
│
└── gold/
    ├── {kpi}/
    │   └── {kpi}_{periodo}.parquet
    └── dim_{entidade}/
        └── {entidade}_scd2_current.parquet
```

---

## Checklist ETL Completo

```
EXTRAÇÃO:
  □ Dado raw salvo na Bronze antes de qualquer transformação
  □ Metadados de extração adicionados (_etl_source, _etl_extracted_at)
  □ Log de quantidade de registros extraídos

TRANSFORMAÇÃO:
  □ Nomes de colunas normalizados (snake_case)
  □ Tipos de dados corrigidos (datas, números, strings)
  □ Nulos tratados com estratégia documentada
  □ Duplicatas removidas (subset definido explicitamente)
  □ Outliers avaliados e documentados
  □ Textos padronizados (UPPER, strip, sem acentos)
  □ Hash de linha calculado para SCD2

QUALIDADE:
  □ Data Quality Report gerado e revisado
  □ Regras de validação executadas e passando
  □ Totais e contagens validados (antes x depois)

CARGA:
  □ Particionamento correto (year/month nas tabelas de fato)
  □ SCD2 aplicado nas dimensões com histórico
  □ Metadados de carga adicionados (_etl_loaded_at, _etl_run_id)
  □ Log de confirmação de carga
```

## Regras de Qualidade

- **Nunca modificar** os dados da camada Bronze
- **Declarar o subset** de deduplicação explicitamente — nunca drop_duplicates() sem parâmetros
- **Documentar a estratégia** de nulos em comentário no código
- **SCD2 para todas as dimensões** com atributos que mudam ao longo do tempo
- **Testar** com dataset pequeno antes de rodar em produção
- **Versionamento:** todo pipeline deve ter run_id e ser rastreável por data de execução
