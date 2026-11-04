"""Create an immutable upstream snapshot and a separately patched execution copy."""
from pathlib import Path
import csv
import difflib
import hashlib
import subprocess

root = Path(__file__).resolve().parents[1]
original = root.parent / "perturbation"
commit = "475c7dcdadc12987033d332b101f025625074301"
snapshot = root / "source" / commit
work = root / "work" / commit
assert subprocess.check_output(["git", "-C", str(original), "rev-parse", "HEAD"], text=True).strip() == commit
names = subprocess.check_output(["git", "-C", str(original), "ls-tree", "-r", "--name-only", commit], text=True).splitlines()
patches = []
manifest = []
for name in names:
    data = subprocess.check_output(["git", "-C", str(original), "show", f"{commit}:{name}"])
    assert (original / name).read_bytes() == data, f"Original differs: {name}"
    target = snapshot / name
    target.parent.mkdir(parents=True, exist_ok=True)
    if target.exists():
        assert target.read_bytes() == data
    else:
        target.write_bytes(data)
    changed = data
    if name.endswith(".R"):
        lines = data.decode().splitlines(keepends=True)
        changed = "".join(line for line in lines if not line.startswith("birth <- filter(japan_birth_island,")).encode()
    target = work / name
    target.parent.mkdir(parents=True, exist_ok=True)
    if target.exists():
        assert target.read_bytes() == changed, f"Refusing overwrite: {target}"
    else:
        target.write_bytes(changed)
    if changed != data:
        patches.extend(difflib.unified_diff(data.decode().splitlines(True), changed.decode().splitlines(True), fromfile="upstream/"+name, tofile="work/"+name))
    manifest.append([name, hashlib.sha256(data).hexdigest(), hashlib.sha256(changed).hexdigest()])
helper = 'firstup <- function(x) {\n  paste0(toupper(substr(x, 1, 1)), substr(x, 2, nchar(x)))\n}\n'
target = work / "R/firstup.R"
if target.exists():
    assert target.read_text() == helper
else:
    target.write_text(helper)
patches.extend(difflib.unified_diff([], helper.splitlines(True), fromfile="/dev/null", tofile="work/R/firstup.R"))
manifest.append(["R/firstup.R", "ABSENT", hashlib.sha256(helper.encode()).hexdigest()])
(root / "patches/compatibility.patch").write_text("".join(patches))
with (root / "patches/file_hashes.tsv").open("w") as f:
    w = csv.writer(f, delimiter="\t")
    w.writerow(["path", "upstream_sha256", "execution_copy_sha256"])
    w.writerows(manifest)
for supplied, expected in [("cases.csv", "data/japan_rsv.csv"), ("population.csv", "data/japan_pop.csv"), ("humidity.csv", "data_processed/data_processed_humidity.csv"), ("temperature.csv", "data_processed/data_processed_temperature.csv")]:
    assert (original / "raw_data" / supplied).read_bytes() == (snapshot / expected).read_bytes()
print(f"SOURCE_PASS: {len(names)} source files pinned; four supplied inputs match; original unchanged.")
