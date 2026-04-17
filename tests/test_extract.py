"""Testes para 01_extract.py — extração e validação de schema."""
import importlib.util
import sys
import types
from pathlib import Path

import pandas as pd
import pytest

ROOT = Path(__file__).parent.parent


def _load_extract():
    path = ROOT / "python" / "01_extract.py"
    spec = importlib.util.spec_from_file_location("etl_01_test", path)
    mod = types.ModuleType("etl_01_test")
    sys.modules["etl_01_test"] = mod
    spec.loader.exec_module(mod)
    return mod


@pytest.fixture(scope="module")
def extract_mod():
    return _load_extract()


class TestValidateSchema:
    def test_schema_valido_nao_aborta(self, extract_mod):
        df = pd.DataFrame({"cliente_id": ["C001"], "segmento": ["CORPORATE"]})
        extract_mod._validate_schema(df, "test", ["cliente_id", "segmento"])

    def test_coluna_ausente_chama_sys_exit(self, extract_mod):
        df = pd.DataFrame({"cliente_id": ["C001"]})
        with pytest.raises(SystemExit):
            extract_mod._validate_schema(df, "test", ["cliente_id", "coluna_faltando"])

    def test_multiplas_colunas_ausentes(self, extract_mod):
        df = pd.DataFrame({"cliente_id": ["C001"]})
        with pytest.raises(SystemExit):
            extract_mod._validate_schema(df, "test", ["cliente_id", "seg", "porte"])

    def test_normaliza_nomes_de_coluna_upper(self, extract_mod):
        df = pd.DataFrame({"CLIENTE_ID": ["C001"], "SEGMENTO": ["CORP"]})
        extract_mod._validate_schema(df, "test", ["cliente_id", "segmento"])
        assert "cliente_id" in df.columns
        assert "segmento" in df.columns

    def test_normaliza_nomes_com_espacos(self, extract_mod):
        df = pd.DataFrame({"cliente_id ": ["C001"], " segmento": ["CORP"]})
        extract_mod._validate_schema(df, "test", ["cliente_id", "segmento"])

    def test_schema_parcialmente_correto_aborta(self, extract_mod):
        df = pd.DataFrame({"cliente_id": ["C001"], "segmento": ["CORP"]})
        with pytest.raises(SystemExit):
            extract_mod._validate_schema(df, "test", ["cliente_id", "segmento", "porte"])


class TestLoadExcel:
    def test_arquivo_inexistente_chama_sys_exit(self, extract_mod):
        with pytest.raises(SystemExit):
            extract_mod.load_excel("caminho/que/nao/existe.xlsx")

    def test_excel_com_aba_faltando_chama_sys_exit(self, extract_mod, workspace_tmp_dir):
        excel_path = workspace_tmp_dir / "incompleto.xlsx"
        pd.DataFrame({"cliente_id": ["C001"]}).to_excel(
            excel_path, sheet_name="clientes", index=False
        )
        with pytest.raises(SystemExit):
            extract_mod.load_excel(str(excel_path))

    def test_excel_com_schema_errado_chama_sys_exit(self, extract_mod, workspace_tmp_dir):
        excel_path = workspace_tmp_dir / "schema_errado.xlsx"
        sheets = ["clientes", "operacoes", "ratings", "limites", "exposicoes"]
        with pd.ExcelWriter(excel_path, engine="openpyxl") as writer:
            for sheet in sheets:
                pd.DataFrame({"coluna_errada": ["x"]}).to_excel(
                    writer, sheet_name=sheet, index=False
                )
        with pytest.raises(SystemExit):
            extract_mod.load_excel(str(excel_path))

    def test_carrega_excel_real_retorna_cinco_tabelas(self, extract_mod):
        excel_path = ROOT / "data" / "raw" / "dados_sinteticos_case.xlsx"
        if not excel_path.exists():
            pytest.skip("dados_sinteticos_case.xlsx não encontrado em data/raw/")
        result = extract_mod.load_excel(str(excel_path))
        assert isinstance(result, dict)
        assert set(result.keys()) == {"clientes", "operacoes", "ratings", "limites", "exposicoes"}

    def test_carrega_excel_real_todas_tabelas_nao_vazias(self, extract_mod):
        excel_path = ROOT / "data" / "raw" / "dados_sinteticos_case.xlsx"
        if not excel_path.exists():
            pytest.skip("dados_sinteticos_case.xlsx não encontrado em data/raw/")
        result = extract_mod.load_excel(str(excel_path))
        for name, df in result.items():
            assert len(df) > 0, f"Tabela {name} veio vazia do Excel"
