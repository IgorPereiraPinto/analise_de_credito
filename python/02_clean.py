"""
02_clean.py — Limpeza e padronização dos DataFrames de crédito

Etapa: Silver — dado limpo, sem regra de negócio ainda
Converte tipos, normaliza strings, trata nulos com estratégia explícita.

Para reutilizar em outro case:
  - ajuste DTYPE_MAP com os tipos corretos por tabela e campo
  - ajuste NULL_STRATEGY com a estratégia de nulo por campo
"""

import sys
from typing import Any

import numpy as np
import pandas as pd
from loguru import logger


# ----------------------------------------------------------------
# Configuração de tipos — ajuste para reutilização
# ----------------------------------------------------------------
DTYPE_MAP: dict[str, dict[str, str]] = {
    "clientes": {
        "cliente_id": "str",
        "segmento": "str",
        "porte": "str",
        "setor": "str",
        "subsetor": "str",
        "data_inicio_relacionamento": "date",
        "regiao": "str",
        "status_cliente": "str",
    },
    "operacoes": {
        "operacao_id": "str",
        "cliente_id": "str",
        "produto": "str",
        "modalidade": "str",
        "valor_aprovado": "decimal",
        "valor_utilizado": "decimal",
        "taxa_juros": "decimal",
        "prazo_meses": "int",
        "data_aprovacao": "date",
        "data_vencimento": "date",
        "garantia_tipo": "str",
        "status_operacao": "str",
    },
    "ratings": {
        "cliente_id": "str",
        "data_referencia": "date",
        "rating_interno": "str",
        "rating_externo": "str",
        "pd_12m": "decimal",
        "score_interno": "int",
        "observacao": "str",
    },
    "limites": {
        "cliente_id": "str",
        "tipo_limite": "str",
        "valor_limite": "decimal",
        "valor_utilizado": "decimal",
        "data_aprovacao": "date",
        "data_revisao": "date",
        "aprovador": "str",
        "status_limite": "str",
    },
    "exposicoes": {
        "cliente_id": "str",
        "data_referencia": "date",
        "exposicao_total": "decimal",
        "exposicao_garantida": "decimal",
        "exposicao_descoberta": "decimal",
    },
}

# Estratégia de nulo por tabela/campo: "drop" | "fill_zero" | "fill_unknown" | "fill_value:X"
# Campos de valor financeiro crítico: nulo → drop (linha descartada com log)
NULL_STRATEGY: dict[str, dict[str, str]] = {
    "clientes": {
        "cliente_id": "drop",
        "segmento": "fill_unknown",
        "porte": "fill_unknown",
        "setor": "fill_unknown",
        "subsetor": "fill_unknown",
        "regiao": "fill_unknown",
        "status_cliente": "fill_value:INDEFINIDO",
    },
    "operacoes": {
        "operacao_id": "drop",
        "cliente_id": "drop",
        "valor_aprovado": "drop",
        "valor_utilizado": "fill_zero",
        "taxa_juros": "fill_zero",
        "prazo_meses": "drop",
    },
    "ratings": {
        "cliente_id": "drop",
        "data_referencia": "drop",
        "pd_12m": "drop",
        "score_interno": "drop",
    },
    "limites": {
        "cliente_id": "drop",
        "tipo_limite": "drop",
        "valor_limite": "drop",
        "valor_utilizado": "fill_zero",
    },
    "exposicoes": {
        "cliente_id": "drop",
        "data_referencia": "drop",
        "exposicao_total": "drop",
        "exposicao_garantida": "fill_zero",
        "exposicao_descoberta": "fill_zero",
    },
}


def clean_all(raw: dict[str, pd.DataFrame]) -> dict[str, pd.DataFrame]:
    """Aplica limpeza completa em todas as tabelas."""
    cleaned: dict[str, pd.DataFrame] = {}

    for table, df in raw.items():
        logger.info(f"[{table}] Iniciando limpeza — {len(df):,} linhas")
        df = _normalize_strings(df, table)
        df = _convert_types(df, table)
        df = _handle_nulls(df, table)
        df = df.drop_duplicates()
        logger.success(f"[{table}] Limpeza concluída — {len(df):,} linhas restantes")
        cleaned[table] = df

    return cleaned


def _normalize_strings(df: pd.DataFrame, table: str) -> pd.DataFrame:
    """Strip e uppercase em campos string categóricos."""
    str_fields = [
        col for col, dtype in DTYPE_MAP.get(table, {}).items()
        if dtype == "str" and col in df.columns
    ]
    for col in str_fields:
        df[col] = df[col].astype(str).str.strip()
        # campos de ID mantém case original; demais → uppercase
        if not col.endswith("_id"):
            df[col] = df[col].str.upper()
    return df


def _convert_types(df: pd.DataFrame, table: str) -> pd.DataFrame:
    """Converte tipos conforme DTYPE_MAP."""
    for col, dtype in DTYPE_MAP.get(table, {}).items():
        if col not in df.columns:
            continue
        try:
            if dtype == "date":
                df[col] = pd.to_datetime(df[col], errors="coerce").dt.date
            elif dtype == "decimal":
                df[col] = pd.to_numeric(df[col], errors="coerce").astype(float)
            elif dtype == "int":
                df[col] = pd.to_numeric(df[col], errors="coerce").astype("Int64")
        except Exception as exc:
            logger.warning(f"[{table}][{col}] Erro na conversão de tipo: {exc}")
    return df


def _handle_nulls(df: pd.DataFrame, table: str) -> pd.DataFrame:
    """Aplica estratégia de nulo por campo conforme NULL_STRATEGY."""
    strategy = NULL_STRATEGY.get(table, {})
    rows_before = len(df)
    drop_mask = pd.Series([False] * len(df), index=df.index)

    for col, action in strategy.items():
        if col not in df.columns:
            continue
        null_count = df[col].isna().sum()
        if null_count == 0:
            continue

        if action == "drop":
            drop_mask = drop_mask | df[col].isna()
            logger.warning(f"[{table}][{col}] {null_count} nulos → linhas marcadas para drop")
        elif action == "fill_zero":
            df[col] = df[col].fillna(0)
        elif action == "fill_unknown":
            df[col] = df[col].fillna("DESCONHECIDO")
        elif action.startswith("fill_value:"):
            fill_val: Any = action.split(":", 1)[1]
            df[col] = df[col].fillna(fill_val)

    df = df[~drop_mask]
    dropped = rows_before - len(df)
    if dropped > 0:
        logger.warning(f"[{table}] {dropped} linhas removidas por nulos críticos")

    return df


def main(raw: dict[str, pd.DataFrame] | None = None) -> dict[str, pd.DataFrame]:
    logger.info("=== 02_clean.py — Iniciando limpeza ===")
    if raw is None:
        import importlib.util, types
        spec = importlib.util.spec_from_file_location("etl_01", "python/01_extract.py")
        mod = types.ModuleType("etl_01"); spec.loader.exec_module(mod)
        raw = mod.main()
    cleaned = clean_all(raw)
    logger.success("Limpeza concluída")
    return cleaned


if __name__ == "__main__":
    main()
