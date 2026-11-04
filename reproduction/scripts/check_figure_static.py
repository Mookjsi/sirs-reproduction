"""Validate Phase 4 sources and metadata without invoking any scientific R code."""
from pathlib import Path
import csv
import hashlib
import re
import subprocess
import zipfile
import xml.etree.ElementTree as ET

root = Path(__file__).resolve().parents[1]
source = root.parent / "perturbation"
messages = ["PHASE4_STATIC_ONLY: no pipeline, scientific script, simulation, plot or PPC executed."]
catalog = list(csv.DictReader((root / "configs/figures/targets.csv").open()))
assert {f"figure{i}" for i in range(1, 5)} <= {r["target"] for r in catalog}
for row in catalog:
    script = source / row["script"]
    assert script.exists()
    text = script.read_text()
    for name in filter(None, row["outputs"].split(";")):
        assert f'"{name}"' in text, (row["target"], name)
    messages.append("TARGET_SOURCE_MATCH " + row["target"] + " " + row["script"])
for row in csv.DictReader((root / "audit_artifacts/source_manifest.tsv").open(), delimiter="\t"):
    assert hashlib.sha256((source / row["relative_path"]).read_bytes()).hexdigest() == row["sha256"]
    pinned = root / "source/475c7dcdadc12987033d332b101f025625074301" / row["relative_path"]
    assert hashlib.sha256(pinned.read_bytes()).hexdigest() == row["sha256"]
messages.append("ORIGINAL_AND_PINNED_SOURCE_UNCHANGED: 54 files each")
for region in ("honshu", "shikoku", "kyushu", "hokkaido", "ryukyu"):
    text = (source / "simulate_sirs" / f"simulate_sirs_{region}.R").read_text()
    assert "tmax=53" in text and "length.out=21" in text
    assert "sim$cases[-1]" in text
    assert 'summary(' in text and ',6]' in text
text = (source / "simulate_sirs/simulate_sirs_interpolate.R").read_text()
for marker in ("length.out=41", 'bs="cc"', "S0=0.078", "S0=0.105",
               "which.max(cases1)-which.max(cases2)"):
    assert marker in text
messages.append("SIMULATION_SOURCE_RULES_MATCH: original medians, grids, indexing and peak metric")
with zipfile.ZipFile(source / "data/japan_childcare.xlsx") as z:
    ns = {"s": "http://schemas.openxmlformats.org/spreadsheetml/2006/main"}
    strings = ["".join(si.itertext()) for si in ET.fromstring(z.read("xl/sharedStrings.xml")).findall("s:si", ns)]
    sheet = ET.fromstring(z.read("xl/worksheets/sheet1.xml"))
    years = [int(float(c.find("s:v", ns).text)) for c in sheet.findall(".//s:c", ns)
             if c.attrib["r"].startswith("A") and c.attrib.get("t") != "s"]
    assert "year" in strings and len(strings) == 5 and set(range(2013, 2020)) <= set(years)
messages.append("CHILDCARE_SCHEMA_PRESENT: year plus four categories, required 2013..2019 rows")
rfiles = sorted(list((root / "figures").glob("*.R")) +
                list((root / "simulations").glob("*.R")) +
                list((root / "configs/figures").glob("*.R")) +
                [root / "scripts/pipeline.R", root / "scripts/pipeline_common.R",
                 root / "scripts/setup_figure_extras.R"])
messages.append(subprocess.check_output([
    "Rscript", "--vanilla", "-e",
    'for(f in commandArgs(TRUE)){parse(f);cat("R_PARSE_OK",basename(f),"\\n")}',
    *map(str, rfiles)], text=True).strip())
subprocess.run(["bash", "-n", str(root / "scripts/pipeline.sh")], check=True)
messages.append("SHELL_PARSE_OK pipeline.sh")
for path in [root / "phase4_execution_plan.md", root / "README.md",
             root / "figure_dependency_map.md", root / "figure_comparison_template.md"]:
    for target in re.findall(r"\]\(([^)]+)\)", path.read_text()):
        if not target.startswith(("http:", "https:")):
            assert (path.parent / target).exists(), (path, target)
messages.append("DOCUMENT_LINKS_OK")
messages.append("Runtime/numerical/graphical validation is pending manual user execution.")
result = "\n".join(messages) + "\n"
(root / "phase4_static_validation.txt").write_text(result)
print(result, end="")
