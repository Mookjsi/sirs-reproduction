"""Prepare the pinned authors' inputs and source copies; execute no scientific code."""
from pathlib import Path
import csv
import hashlib
import shutil
import subprocess
import sys

root = Path(__file__).resolve().parents[1]
original = root.parent / "perturbation"
commit = "475c7dcdadc12987033d332b101f025625074301"

if not original.exists():
    subprocess.run(["git", "clone", "--no-checkout",
                    "https://github.com/parksw3/perturbation.git", str(original)], check=True)
    subprocess.run(["git", "-C", str(original), "checkout", "--detach", commit], check=True)
else:
    actual = subprocess.check_output(["git", "-C", str(original), "rev-parse", "HEAD"], text=True).strip()
    if actual != commit:
        raise SystemExit(f"Existing {original} is at {actual}, expected {commit}; left untouched.")

for row in csv.DictReader((root / "audit_artifacts/source_manifest.tsv").open(), delimiter="\t"):
    path = original / row["relative_path"]
    if hashlib.sha256(path.read_bytes()).hexdigest() != row["sha256"]:
        raise SystemExit(f"Pinned source mismatch; refusing to proceed: {path}")

pairs = {"cases.csv": "data/japan_rsv.csv", "population.csv": "data/japan_pop.csv",
         "humidity.csv": "data_processed/data_processed_humidity.csv",
         "temperature.csv": "data_processed/data_processed_temperature.csv"}
(original / "raw_data").mkdir(exist_ok=True)
for name, source in pairs.items():
    target = original / "raw_data" / name
    if target.exists():
        if target.read_bytes() != (original / source).read_bytes():
            raise SystemExit(f"Existing differing input left untouched: {target}")
    else:
        shutil.copy2(original / source, target)

for directory in ["environment/library", "environment/downloads", "environment/tmp",
                  "environment/logs", "patches"]:
    (root / directory).mkdir(parents=True, exist_ok=True)
subprocess.run([sys.executable, str(root / "scripts/prepare_source.py")], check=True)
print("Bootstrap complete. No scientific computation or package installation performed.")
