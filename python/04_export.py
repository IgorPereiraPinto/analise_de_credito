"""
04_export.py — Exportação dos dados validados para carga no banco

Etapa: saída do pipeline Python — dado pronto para SQL Server ou S3/Athena
Exporta cada tabela como CSV (padrão) ou Parquet (para S3/Athena).

Para reutilizar em outro case:
  - ajuste DATA_PROCESSED_PATH e EXPORT_FORMAT no .env
  - para Athena: EXPORT_FORMAT=parquet e ajuste o path de saída para s3://...
  - nenhuma regra de negócio aqui — apenas serialização
"""

import os
from pathlib import Path

import pandas as pd
from dotenv import load_dotenv
from loguru import logger

load_dotenv()

DATA_PROCESSED_PATH: str = os.getenv("DATA_PROCESSED_PATH", "data/processed/")
EXPORT_FORMAT: str = os.getenv("EXPORT_FORMAT", "csv")  # "csv" ou "parquet"


def export_all(validated: dict[str, pd.DataFrame]) -> None:
    """Exporta todos os DataFrames validados para o formato configurado."""
    out_dir = Path(DATA_PROCESSED_PATH)
    out_dir.mkdir(parents=True, exist_ok=True)

    for table, df in validated.items():
        if EXPORT_FORMAT == "parquet":
            _export_parquet(df, table, out_dir)
        else:
            _export_csv(df, table, out_dir)

    logger.success(f"Exportação concluída — {len(validated)} tabelas em {out_dir.resolve()}")
    _print_summary(validated)


def _export_csv(df: pd.DataFrame, table: str, out_dir: Path) -> None:
    path = out_dir / f"{table}.csv"
    df.to_csv(path, index=False, encoding="utf-8-sig", sep=";")
    logger.info(f"  [{table}] {len(df):,} linhas → {path.name}")


def _export_parquet(df: pd.DataFrame, table: str, out_dir: Path) -> None:
    path = out_dir / f"{table}.parquet"
    df.to_parquet(path, index=False, engine="pyarrow", compression="snappy")
    logger.info(f"  [{table}] {len(df):,} linhas → {path.name}")


def _print_summary(validated: dict[str, pd.DataFrame]) -> None:
    """Imprime resumo de linhas por tabela para conferência rápida."""
    logger.info("=== Resumo da exportação ===")
    for table, df in validated.items():
        logger.info(f"  {table:<15} {len(df):>6,} linhas | {len(df.columns):>2} colunas")


def main(validated: dict[str, pd.DataFrame] | None = None) -> None:
    logger.info("=== 04_export.py — Iniciando exportação ===")
    if validated is None:
        import importlib.util, types
        spec = importlib.util.spec_from_file_location("etl_03", "python/03_validate.py")
        mod = types.ModuleType("etl_03"); spec.loader.exec_module(mod)
        validated = mod.main()
    export_all(validated)


if __name__ == "__main__":
    main()
