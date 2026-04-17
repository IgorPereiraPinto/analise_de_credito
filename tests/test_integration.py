"""Teste de integração — pipeline ponta a ponta com o Excel sintético real.

Executa o fluxo completo: extract → clean → validate → export
usando o arquivo dados_sinteticos_case.xlsx em data/raw/.

Skippado automaticamente quando o Excel não está disponível
(ex: CI sem o arquivo versionado).
"""
import importlib.util
import os
import sys
import types
from pathlib import Path

import pandas as pd
import pytest

ROOT = Path(__file__).parent.parent
EXCEL_PATH = ROOT / "data" / "raw" / "dados_sinteticos_case.xlsx"
TABLES = {"clientes", "operacoes", "ratings", "limites", "exposicoes"}

pytestmark = pytest.mark.integration


def _load(filename: str, name: str):
    path = ROOT / "python" / filename
    spec = importlib.util.spec_from_file_location(name, path)
    mod = types.ModuleType(name)
    sys.modules[name] = mod
    spec.loader.exec_module(mod)
    return mod


@pytest.fixture(scope="module")
def pipeline_result(tmp_path_factory):
    if not EXCEL_PATH.exists():
        pytest.skip("dados_sinteticos_case.xlsx ausente — teste de integração ignorado")

    out_dir = tmp_path_factory.mktemp("processed")

    os.environ["DATA_RAW_PATH"] = str(EXCEL_PATH)
    os.environ["DATA_PROCESSED_PATH"] = str(out_dir) + "/"
    os.environ["EXPORT_FORMAT"] = "csv"

    e01 = _load("01_extract.py", "etl_01_int")
    e02 = _load("02_clean.py", "etl_02_int")
    e03 = _load("03_validate.py", "etl_03_int")
    e04 = _load("04_export.py", "etl_04_int")

    e01.DATA_RAW_PATH = str(EXCEL_PATH)
    e03.DATA_PROCESSED_PATH = str(out_dir) + "/"
    e04.DATA_PROCESSED_PATH = str(out_dir) + "/"
    e04.EXPORT_FORMAT = "csv"

    raw = e01.main()
    cleaned = e02.clean_all(raw)
    validated = e03.validate_all(cleaned)
    e04.export_all(validated)

    return {"raw": raw, "cleaned": cleaned, "validated": validated, "out_dir": out_dir}


class TestPipelineCompleto:
    def test_extracao_retorna_cinco_tabelas(self, pipeline_result):
        assert set(pipeline_result["raw"].keys()) == TABLES

    def test_limpeza_preserva_todas_tabelas(self, pipeline_result):
        assert set(pipeline_result["cleaned"].keys()) == TABLES

    def test_validacao_preserva_todas_tabelas(self, pipeline_result):
        assert set(pipeline_result["validated"].keys()) == TABLES

    def test_tabelas_validadas_nao_vazias(self, pipeline_result):
        for name, df in pipeline_result["validated"].items():
            assert len(df) > 0, f"Tabela {name} ficou vazia após validação"

    def test_csvs_exportados_existem(self, pipeline_result):
        out_dir = pipeline_result["out_dir"]
        for table in TABLES:
            csv_path = out_dir / f"{table}.csv"
            assert csv_path.exists(), f"{table}.csv não foi gerado"

    def test_csvs_exportados_nao_vazios(self, pipeline_result):
        out_dir = pipeline_result["out_dir"]
        for table in TABLES:
            df = pd.read_csv(out_dir / f"{table}.csv", sep=";", encoding="utf-8-sig")
            assert len(df) > 0, f"{table}.csv está vazio"

    def test_validation_report_gerado(self, pipeline_result):
        report_path = pipeline_result["out_dir"] / "validation_report.csv"
        assert report_path.exists()

    def test_clientes_tem_cliente_id(self, pipeline_result):
        df = pipeline_result["validated"]["clientes"]
        assert "cliente_id" in df.columns
        assert df["cliente_id"].notna().all()

    def test_ratings_pd_12m_no_intervalo(self, pipeline_result):
        df = pipeline_result["validated"]["ratings"]
        assert df["pd_12m"].between(0, 1).all()

    def test_operacoes_utilizado_menor_aprovado(self, pipeline_result):
        df = pipeline_result["validated"]["operacoes"]
        validas = df[df["valor_aprovado"] > 0]
        assert (validas["valor_utilizado"] <= validas["valor_aprovado"]).all()
