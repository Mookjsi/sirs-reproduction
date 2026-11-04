"""Parse source and compare configuration text; never import or invoke the pipeline."""
from pathlib import Path
import csv
import hashlib
import re
import subprocess

root = Path(__file__).resolve().parents[1]
source = root.parent / "perturbation"
messages = ["Phase 3 static validation only; no pipeline commands or experiments invoked."]
registry = list(csv.DictReader((root / "configs/regions.csv").open()))
assert len(registry) == 8
assert len({(r["region"], r["variant"]) for r in registry}) == 8
for row in registry:
    text = (source / row["source_script"]).read_text()
    assert f'../stanmodel/{row["model"]}.stan' in text
    for key in ("Nnonpi", "seed", "adapt_delta"):
        match = re.search(r"\b" + key + r"\s*=\s*([0-9.]+)", text)
        assert match and float(match[1]) == float(row[key]), (row, key)
    for key, value in (("chain", 4), ("cores", 4), ("iter", 4000), ("max_treedepth", 15)):
        assert float(re.search(r"\b" + key + r"\s*=\s*([0-9.]+)", text)[1]) == value
    if row["source_break"]:
        assert re.search(r">\s*" + re.escape(row["source_break"]), text)
    messages.append("CONFIG_MATCH " + row["variant"] + "/" + row["region"])
for row in csv.DictReader((root / "audit_artifacts/source_manifest.tsv").open(), delimiter="\t"):
    assert hashlib.sha256((source / row["relative_path"]).read_bytes()).hexdigest() == row["sha256"]
messages.append("ORIGINAL_SOURCE_UNCHANGED: 54 pinned tracked files")
for path in sorted((root / "scripts").glob("*.sh")):
    subprocess.run(["bash", "-n", str(path)], check=True)
    messages.append("SHELL_PARSE_OK " + path.name)
# R parse() constructs language objects only; no source(), eval(), sampling or data actions.
parsed = subprocess.check_output([
    "Rscript", "--vanilla", "-e",
    'a<-commandArgs(TRUE);for(f in a){parse(f);cat("R_PARSE_OK",basename(f),"\\n")}',
    *map(str, sorted(list((root / "scripts").glob("*.R")) +
                     list((root / "configs").glob("*.R")) +
                     list((root / "diagnostics").glob("*.R"))))
], text=True)
messages.append(parsed.strip())
for path in [root / "README.md", root / "phase3_execution_plan.md", root / "configs/README.md",
             root / "diagnostics/README.md"]:
    for target in re.findall(r"\]\(([^)]+)\)", path.read_text()):
        if not target.startswith(("https:", "http:")):
            assert (path.parent / target).exists(), (path, target)
messages.append("DOCUMENT_LINKS_OK")
messages.append("Runtime validation deliberately not performed. User execution required.")
result = "\n".join(messages) + "\n"
(root / "phase3_static_validation.txt").write_text(result)
print(result, end="")
