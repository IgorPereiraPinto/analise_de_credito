"""Runner do pipeline ETL completo — executa os 4 scripts em sequência."""
import importlib.util
import sys
import types
from pathlib import Path

from dotenv import load_dotenv
from loguru import logger

load_dotenv()

BASE = Path(__file__).parent


def _load(filename: str, name: str):
    path = BASE / "python" / filename
    spec = importlib.util.spec_from_file_location(name, path)
    mod = types.ModuleType(name)
    sys.modules[name] = mod
    spec.loader.exec_module(mod)
    return mod


e01 = _load("01_extract.py",  "etl_01")
e02 = _load("02_clean.py",    "etl_02")
e03 = _load("03_validate.py", "etl_03")
e04 = _load("04_export.py",   "etl_04")

logger.info("━━━ ETAPA 1/4 — Extração ━━━")
raw = e01.main()

logger.info("━━━ ETAPA 2/4 — Limpeza ━━━")
cleaned = e02.clean_all(raw)

logger.info("━━━ ETAPA 3/4 — Validação ━━━")
validated = e03.validate_all(cleaned)

logger.info("━━━ ETAPA 4/4 — Exportação ━━━")
e04.export_all(validated)

logger.success("Pipeline ETL concluído.")
