import ast
import json
import pathlib
import re


ROOT = pathlib.Path(__file__).resolve().parents[1]
SRC = ROOT / "src" / "data"
OUT = ROOT / "assets" / "reference"


def strip_comments(text: str) -> str:
    return re.sub(r"//.*", "", text)


def quote_keys(text: str) -> str:
    return re.sub(
        r"([{\[,]\s*)([A-Za-z_][A-Za-z0-9_]*)\s*:",
        r'\1"\2":',
        text,
    )


def extract_export(path: pathlib.Path, export_name: str) -> str:
    text = path.read_text(encoding="utf-8")
    match = re.search(
        rf"export const {re.escape(export_name)}\s*=\s*(.*?);",
        strip_comments(text),
        re.S,
    )
    if not match:
        raise ValueError(f"Could not find export {export_name} in {path}")
    return match.group(1).strip()


def parse_js_literal(literal: str):
    pythonish = (
        quote_keys(literal)
        .replace("null", "None")
        .replace("true", "True")
        .replace("false", "False")
    )
    return ast.literal_eval(pythonish)


def write_json(name: str, payload) -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    path = OUT / name
    path.write_text(json.dumps(payload, indent=2), encoding="utf-8")


def main() -> None:
    write_json("foods.json", parse_js_literal(extract_export(SRC / "foods.js", "FOODS")))
    write_json(
        "medical_modifiers.json",
        {
            "medicalModifiers": parse_js_literal(
                extract_export(SRC / "medical-modifiers.js", "MEDICAL_MODIFIERS")
            ),
            "microPriorityElevations": parse_js_literal(
                extract_export(SRC / "medical-modifiers.js", "MICRO_PRIORITY_ELEVATIONS")
            ),
            "basePenaltyThresholds": parse_js_literal(
                extract_export(SRC / "medical-modifiers.js", "BASE_PENALTY_THRESHOLDS")
            ),
            "basePenaltyWeights": parse_js_literal(
                extract_export(SRC / "medical-modifiers.js", "BASE_PENALTY_WEIGHTS")
            ),
        },
    )
    write_json(
        "micronutrient_rda.json",
        {
            "demographicKeys": parse_js_literal(
                extract_export(SRC / "rda.js", "DEMOGRAPHIC_KEYS")
            ),
            "rda": parse_js_literal(extract_export(SRC / "rda.js", "RDA")),
        },
    )


if __name__ == "__main__":
    main()
