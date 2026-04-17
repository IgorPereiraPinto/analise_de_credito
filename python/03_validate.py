"""
03_validate.py — Validação de qualidade e regras de negócio

Etapa: ponto de controle entre Silver e Gold
Aplica validações de integridade e regras de negócio do domínio de crédito.
Gera relatório de inconsistências em data/processed/validation_report.csv.

Para reutilizar em outro case:
  - ajuste VALIDATION_RULES com as regras do novo domínio
  - severidade "error" remove a linha; "warning" apenas registra
"""

import os
from dataclasses import dataclass, field
from pathlib import Path

import pandas as pd
from dotenv import load_dotenv
from loguru import logger

load_dotenv()

DATA_PROCESSED_PATH: str = os.getenv("DATA_PROCESSED_PATH", "data/processed/")


@dataclass
class ValidationResult:
    table: str
    rule: str
    severity: str  # "error" | "warning"
    affected_rows: int
    detail: str
    failed_ids: list = field(default_factory=list)


def validate_all(cleaned: dict[str, pd.DataFrame]) -> dict[str, pd.DataFrame]:
    """
    Executa todas as validações. Linhas com erro severo são removidas.
    Retorna DataFrames validados e salva relatório de qualidade.
    """
    results: list[ValidationResult] = []
    validated = {k: v.copy() for k, v in cleaned.items()}

    # ----------------------------------------------------------------
    # Regra 1: valor_utilizado <= valor_aprovado (operacoes)
    # ----------------------------------------------------------------
    if "operacoes" in validated:
        df = validated["operacoes"]
        mask = df["valor_utilizado"] > df["valor_aprovado"]
        if mask.any():
            ids = df.loc[mask, "operacao_id"].tolist()
            results.append(ValidationResult(
                table="operacoes",
                rule="valor_utilizado <= valor_aprovado",
                severity="warning",
                affected_rows=mask.sum(),
                detail="Utilizado maior que aprovado — possível erro de dados ou descasamento",
                failed_ids=ids,
            ))
            logger.warning(f"[operacoes] {mask.sum()} linhas com utilizado > aprovado")

    # ----------------------------------------------------------------
    # Regra 2: pd_12m entre 0 e 1 (ratings)
    # ----------------------------------------------------------------
    if "ratings" in validated:
        df = validated["ratings"]
        mask = ~df["pd_12m"].between(0, 1)
        if mask.any():
            results.append(ValidationResult(
                table="ratings",
                rule="0 <= pd_12m <= 1",
                severity="error",
                affected_rows=mask.sum(),
                detail="PD fora do intervalo [0,1] — linha inválida, removida",
                failed_ids=df.loc[mask, "cliente_id"].tolist(),
            ))
            validated["ratings"] = df[~mask]
            logger.error(f"[ratings] {mask.sum()} linhas removidas — pd_12m inválido")

    # ----------------------------------------------------------------
    # Regra 3: exposicao_descoberta = exposicao_total - exposicao_garantida
    # ----------------------------------------------------------------
    if "exposicoes" in validated:
        df = validated["exposicoes"]
        expected = (df["exposicao_total"] - df["exposicao_garantida"]).round(2)
        mask = (df["exposicao_descoberta"].round(2) - expected).abs() > 0.01
        if mask.any():
            results.append(ValidationResult(
                table="exposicoes",
                rule="exposicao_descoberta = exposicao_total - exposicao_garantida",
                severity="warning",
                affected_rows=mask.sum(),
                detail="Inconsistência aritmética na decomposição da exposição",
                failed_ids=df.loc[mask, "cliente_id"].tolist(),
            ))
            logger.warning(f"[exposicoes] {mask.sum()} linhas com inconsistência aritmética")

    # ----------------------------------------------------------------
    # Regra 4: data_vencimento >= data_aprovacao (operacoes)
    # ----------------------------------------------------------------
    if "operacoes" in validated:
        df = validated["operacoes"]
        mask = pd.to_datetime(df["data_vencimento"]) < pd.to_datetime(df["data_aprovacao"])
        if mask.any():
            results.append(ValidationResult(
                table="operacoes",
                rule="data_vencimento >= data_aprovacao",
                severity="error",
                affected_rows=mask.sum(),
                detail="Vencimento anterior à aprovação — operação inválida",
                failed_ids=df.loc[mask, "operacao_id"].tolist(),
            ))
            validated["operacoes"] = df[~mask]
            logger.error(f"[operacoes] {mask.sum()} linhas removidas — datas inconsistentes")

    # ----------------------------------------------------------------
    # Regra 5: valor_limite > 0 (limites)
    # ----------------------------------------------------------------
    if "limites" in validated:
        df = validated["limites"]
        mask = df["valor_limite"] <= 0
        if mask.any():
            results.append(ValidationResult(
                table="limites",
                rule="valor_limite > 0",
                severity="error",
                affected_rows=mask.sum(),
                detail="Limite zerado ou negativo — linha inválida",
                failed_ids=df.loc[mask, "cliente_id"].tolist(),
            ))
            validated["limites"] = df[~mask]
            logger.error(f"[limites] {mask.sum()} linhas removidas — limite inválido")

    # ----------------------------------------------------------------
    # Regra 6: unicidade de PK por tabela
    # ----------------------------------------------------------------
    pk_map = {
        "clientes": ["cliente_id"],
        "operacoes": ["operacao_id"],
        "ratings": ["cliente_id", "data_referencia"],
        "limites": ["cliente_id", "tipo_limite"],
        "exposicoes": ["cliente_id", "data_referencia"],
    }
    for table, pk_cols in pk_map.items():
        if table not in validated:
            continue
        df = validated[table]
        dupes = df.duplicated(subset=pk_cols, keep="first").sum()
        if dupes:
            results.append(ValidationResult(
                table=table,
                rule=f"PK única: {pk_cols}",
                severity="warning",
                affected_rows=dupes,
                detail="Linhas duplicadas na chave primária — mantida primeira ocorrência",
            ))
            validated[table] = df.drop_duplicates(subset=pk_cols, keep="first")
            logger.warning(f"[{table}] {dupes} duplicatas de PK removidas")

    _save_report(results)
    return validated


def _save_report(results: list[ValidationResult]) -> None:
    """Salva relatório de validação em CSV."""
    if not results:
        logger.success("Nenhuma inconsistência encontrada — dados limpos")
        return

    report = pd.DataFrame([{
        "tabela": r.table,
        "regra": r.rule,
        "severidade": r.severity,
        "linhas_afetadas": r.affected_rows,
        "detalhe": r.detail,
    } for r in results])

    out_path = Path(DATA_PROCESSED_PATH) / "validation_report.csv"
    out_path.parent.mkdir(parents=True, exist_ok=True)
    report.to_csv(out_path, index=False, encoding="utf-8-sig")
    logger.info(f"Relatório de validação salvo: {out_path}")

    errors = sum(1 for r in results if r.severity == "error")
    warnings = sum(1 for r in results if r.severity == "warning")
    logger.info(f"Resumo: {errors} erros, {warnings} avisos")


def main(cleaned: dict[str, pd.DataFrame] | None = None) -> dict[str, pd.DataFrame]:
    logger.info("=== 03_validate.py — Iniciando validação ===")
    if cleaned is None:
        import importlib.util, types
        spec = importlib.util.spec_from_file_location("etl_02", "python/02_clean.py")
        mod = types.ModuleType("etl_02"); spec.loader.exec_module(mod)
        cleaned = mod.main()
    validated = validate_all(cleaned)
    logger.success("Validação concluída")
    return validated


if __name__ == "__main__":
    main()
