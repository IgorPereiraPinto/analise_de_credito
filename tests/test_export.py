"""Testes para 04_export.py: serializacao dos dados validados."""
import importlib.util
import sys
import types
from pathlib import Path

import pandas as pd
import pytest

ROOT = Path(__file__).parent.parent
pyarrow = pytest.importorskip("pyarrow", reason="pyarrow nao instalado - skip testes parquet")


def _load_export():
    path = ROOT / "python" / "04_export.py"
    spec = importlib.util.spec_from_file_location("etl_04", path)
    mod = types.ModuleType("etl_04")
    sys.modules["etl_04"] = mod
    spec.loader.exec_module(mod)
    return mod


@pytest.fixture(scope="module")
def export_mod():
    return _load_export()


@pytest.fixture
def sample_data():
    return {
        "clientes": pd.DataFrame({
            "cliente_id": ["C001", "C002"],
            "segmento": ["CORPORATE", "MIDDLE MARKET"],
            "status_cliente": ["ATIVO", "ATIVO"],
        }),
        "ratings": pd.DataFrame({
            "cliente_id": ["C001", "C002"],
            "pd_12m": [0.001, 0.02],
            "score_interno": [920, 750],
        }),
    }


@pytest.fixture
def configured_csv(export_mod, workspace_tmp_dir, monkeypatch):
    """Configura o modulo de export para CSV em diretorio temporario local."""
    monkeypatch.setattr(export_mod, "DATA_PROCESSED_PATH", str(workspace_tmp_dir))
    monkeypatch.setattr(export_mod, "EXPORT_FORMAT", "csv")
    return workspace_tmp_dir


@pytest.fixture
def configured_parquet(export_mod, workspace_tmp_dir, monkeypatch):
    """Configura o modulo de export para Parquet em diretorio temporario local."""
    monkeypatch.setattr(export_mod, "DATA_PROCESSED_PATH", str(workspace_tmp_dir))
    monkeypatch.setattr(export_mod, "EXPORT_FORMAT", "parquet")
    return workspace_tmp_dir


class TestExportCSV:
    def test_csv_criado(self, export_mod, sample_data, configured_csv):
        export_mod.export_all(sample_data)
        assert (configured_csv / "clientes.csv").exists()
        assert (configured_csv / "ratings.csv").exists()

    def test_csv_separador_ponto_virgula(self, export_mod, sample_data, configured_csv):
        export_mod.export_all(sample_data)
        content = (configured_csv / "clientes.csv").read_text(encoding="utf-8-sig")
        assert ";" in content

    def test_csv_sem_index(self, export_mod, sample_data, configured_csv):
        export_mod.export_all(sample_data)
        df = pd.read_csv(configured_csv / "clientes.csv", sep=";", encoding="utf-8-sig")
        assert "Unnamed: 0" not in df.columns

    def test_csv_linhas_preservadas(self, export_mod, sample_data, configured_csv):
        export_mod.export_all(sample_data)
        df = pd.read_csv(configured_csv / "clientes.csv", sep=";", encoding="utf-8-sig")
        assert len(df) == 2


class TestExportParquet:
    def test_parquet_criado(self, export_mod, sample_data, configured_parquet):
        export_mod.export_all(sample_data)
        assert (configured_parquet / "clientes.parquet").exists()

    def test_parquet_linhas_preservadas(self, export_mod, sample_data, configured_parquet):
        export_mod.export_all(sample_data)
        df = pd.read_parquet(configured_parquet / "clientes.parquet")
        assert len(df) == 2
