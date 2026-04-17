"""
01_extract.py — Extração do Excel de crédito corporativo

Etapa: RAW → entrada do pipeline
Lê o arquivo Excel, valida abas e schema mínimo, retorna DataFrames brutos.

Para reutilizar em outro case:
  - ajuste EXPECTED_SHEETS com os nomes de abas e colunas do novo arquivo
  - ajuste DATA_RAW_PATH no .env
"""

import os
import sys
from pathlib import Path

import pandas as pd
from dotenv import load_dotenv
from loguru import logger

load_dotenv()

# ----------------------------------------------------------------
# Configuração — ajuste aqui para reutilização
# ----------------------------------------------------------------
DATA_RAW_PATH: str = os.getenv("DATA_RAW_PATH", "data/raw/dados_sinteticos_case.xlsx")

# Mapa de abas esperadas no Excel → colunas obrigatórias
EXPECTED_SHEETS: dict[str, list[str]] = {
    "clientes": [
        "cliente_id", "segmento", "porte", "setor", "subsetor",
        "data_inicio_relacionamento", "regiao", "status_cliente",
    ],
    "operacoes": [
        "operacao_id", "cliente_id", "produto", "modalidade",
        "valor_aprovado", "valor_utilizado", "taxa_juros", "prazo_meses",
        "data_aprovacao", "data_vencimento", "garantia_tipo", "status_operacao",
    ],
    "ratings": [
        "cliente_id", "data_referencia", "rating_interno", "rating_externo",
        "pd_12m", "score_interno",
    ],
    "limites": [
        "cliente_id", "tipo_limite", "valor_limite", "valor_utilizado",
        "data_aprovacao", "data_revisao", "status_limite",
    ],
    "exposicoes": [
        "cliente_id", "data_referencia", "exposicao_total",
        "exposicao_garantida", "exposicao_descoberta",
    ],
}


def load_excel(path: str) -> dict[str, pd.DataFrame]:
    """Lê todas as abas esperadas do Excel e retorna dicionário de DataFrames."""
    file = Path(path)

    if not file.exists():
        logger.error(f"Arquivo não encontrado: {file.resolve()}")
        sys.exit(1)

    logger.info(f"Lendo arquivo: {file.resolve()}")
    raw: dict[str, pd.DataFrame] = {}

    for sheet_name, required_cols in EXPECTED_SHEETS.items():
        try:
            df = pd.read_excel(file, sheet_name=sheet_name)
            logger.info(f"  [{sheet_name}] {len(df):,} linhas lidas")
        except Exception as exc:
            logger.error(f"  [{sheet_name}] Aba não encontrada ou erro na leitura: {exc}")
            sys.exit(1)

        _validate_schema(df, sheet_name, required_cols)
        raw[sheet_name] = df

    return raw


def _validate_schema(df: pd.DataFrame, sheet: str, required_cols: list[str]) -> None:
    """Verifica se todas as colunas obrigatórias estão presentes."""
    df_cols = [c.lower().strip() for c in df.columns]
    df.columns = df_cols  # normaliza nomes de coluna já na extração

    missing = [c for c in required_cols if c not in df_cols]
    if missing:
        logger.error(f"  [{sheet}] Colunas ausentes: {missing}")
        sys.exit(1)

    logger.success(f"  [{sheet}] Schema validado — {len(df.columns)} colunas OK")


def main() -> dict[str, pd.DataFrame]:
    logger.info("=== 01_extract.py — Iniciando extração ===")
    raw = load_excel(DATA_RAW_PATH)
    logger.success(f"Extração concluída — {len(raw)} tabelas carregadas")
    return raw


if __name__ == "__main__":
    main()
