#!/usr/bin/env python3

import argparse
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
from collections import defaultdict
from pathlib import Path


SCRIPT = Path(__file__).resolve()
REPO_ROOT = SCRIPT.parents[4]
GRAPH_RTL_ROOT = REPO_ROOT / "03_capi_integration/accelerator_rtl"
GRAPH_VERIFICATION_RTL_ROOT = (
    REPO_ROOT / "03_capi_integration/accelerator_verification/rtl"
)
CAPI_ROOT = REPO_ROOT / "01_capi_precis"
MANIFEST_ROOT = GRAPH_VERIFICATION_RTL_ROOT / "manifests"
LAYOUTS_PATH = MANIFEST_ROOT / "layouts.json"
INVENTORY_PATH = MANIFEST_ROOT / "rtl-inventory.json"
EXTRACT_SCRIPT = SCRIPT.with_name("extract_vsim_sources.tcl")
SIM_ROOT = REPO_ROOT / "03_capi_integration/accelerator_sim/sim"
SYNTH_ROOT = REPO_ROOT / "03_capi_integration/accelerator_synth"
GRAPH_BIND = (
    "03_capi_integration/accelerator_verification/rtl/"
    "accelerator_verification_bind.sv"
)
GRAPH_TB = (
    "03_capi_integration/accelerator_verification/rtl/"
    "accelerator_verification_tb.sv"
)
FP_BLACKBOX = GRAPH_VERIFICATION_RTL_ROOT / "models/fp_vendor_blackboxes.sv"
CAPI_TOP = (
    "01_capi_precis/01_capi_integration/pslse/afu_driver/verilog/top.v"
)
RTL_SUFFIXES = {".sv", ".v", ".vhd", ".vhdl"}
DECLARATION_RE = re.compile(
    r"\b(package|module|interface)\s+(?:automatic\s+)?"
    r"([A-Za-z_][A-Za-z0-9_$]*)"
)


def fail(message):
    print(f"FAIL {message}", file=sys.stderr)
    raise SystemExit(1)


def relative(path):
    return path.resolve().relative_to(REPO_ROOT).as_posix()


def read_source_file(path, allow_missing=False):
    if not path.is_file():
        fail(f"missing manifest: {relative(path)}")
    sources = []
    for line_number, raw_line in enumerate(path.read_text().splitlines(), 1):
        source = raw_line.strip()
        if not source or source.startswith("#"):
            continue
        source_path = Path(source)
        if (
            source_path.is_absolute() or
            ".." in source_path.parts or
            any(character in source for character in "*?[]$")
        ):
            fail(f"{relative(path)}:{line_number}: invalid source {source}")
        if source in sources:
            fail(f"{relative(path)}:{line_number}: duplicate source {source}")
        resolved = REPO_ROOT / source
        if not allow_missing and not resolved.is_file():
            fail(f"{relative(path)}:{line_number}: missing source {source}")
        if resolved.suffix.lower() != ".sv":
            fail(
                f"{relative(path)}:{line_number}: only SystemVerilog "
                f"is accepted: {source}"
            )
        if relative(resolved) != source:
            fail(
                f"{relative(path)}:{line_number}: non-canonical source {source}"
            )
        sources.append(source)
    if not sources:
        fail(f"empty manifest: {relative(path)}")
    return sources


def write_source_file(path, title, sources):
    contents = [f"# AccelGraph RTL manifest v2: {title}", *sources]
    path.write_text("\n".join(contents) + "\n")


def load_layouts():
    payload = json.loads(LAYOUTS_PATH.read_text())
    if payload.get("schema_version") != 2:
        fail("unsupported layouts schema")
    layouts = payload.get("layouts", [])
    if len(layouts) != 11:
        fail(f"expected 11 layouts, found {len(layouts)}")
    identifiers = [layout["id"] for layout in layouts]
    if len(set(identifiers)) != len(identifiers):
        fail("duplicate layout id")
    status_counts = defaultdict(int)
    for layout in layouts:
        status_counts[layout["status"]] += 1
        expected_id = "_".join(
            layout[key]
            for key in (
                "algorithm",
                "data_structure",
                "direction",
                "precision",
            )
        )
        if layout["id"] != expected_id:
            fail(f"layout id does not match fields: {layout['id']}")
        if (
            layout["graph_cus"] *
            layout["vertex_cus_per_graph_cu"] !=
            layout["total_vertex_cus"]
        ):
            fail(f"invalid topology product: {layout['id']}")
    if dict(status_counts) != {"active": 8, "quarantined": 3}:
        fail(f"expected 8 active and 3 quarantined layouts: {status_counts}")
    return payload, layouts


def validate_capi_pin(expected_commit):
    try:
        actual = subprocess.run(
            ["git", "-C", str(CAPI_ROOT), "rev-parse", "HEAD"],
            check=True,
            capture_output=True,
            text=True,
        ).stdout.strip()
        index_entry = subprocess.run(
            ["git", "-C", str(REPO_ROOT), "ls-files", "-s", "--", "01_capi_precis"],
            check=True,
            capture_output=True,
            text=True,
        ).stdout.split()
        dirty = subprocess.run(
            ["git", "-C", str(CAPI_ROOT), "status", "--porcelain"],
            check=True,
            capture_output=True,
            text=True,
        ).stdout
        nested = subprocess.run(
            ["git", "-C", str(CAPI_ROOT), "submodule", "status", "--recursive"],
            check=True,
            capture_output=True,
            text=True,
        ).stdout.splitlines()
    except subprocess.CalledProcessError:
        fail("unable to validate the recursive CAPI-Precis pin")
    if actual != expected_commit:
        fail(f"CAPI-Precis pin {actual} != {expected_commit}")
    if len(index_entry) < 2 or index_entry[1] != expected_commit:
        fail("superproject gitlink does not match layouts.json")
    if dirty:
        fail("CAPI-Precis submodule has local modifications")
    if any(not line.startswith(" ") for line in nested):
        fail("CAPI-Precis nested submodules are not at their recorded pins")

    validator = (
        CAPI_ROOT /
        "01_capi_integration/accelerator_verification/rtl/"
        "scripts/verify_manifests.py"
    )
    if not validator.is_file():
        fail("pinned CAPI-Precis does not publish the Phase 0 manifest API")
    try:
        subprocess.run([str(validator)], check=True, cwd=CAPI_ROOT)
    except subprocess.CalledProcessError:
        fail("pinned CAPI-Precis manifest self-test failed")
    print(f"PASS capi_pin {actual}")


def validate_vendor_boundaries(payload):
    expected_modules = {"fp_single_add_acc", "fp_single_mul"}
    blackbox_declarations = {
        declaration["name"]
        for declaration in declarations(FP_BLACKBOX)
        if declaration["kind"] == "module"
    }
    if blackbox_declarations != expected_modules:
        fail(
            "portable FP blackboxes changed: "
            f"{sorted(blackbox_declarations)}"
        )
    if sha256(FP_BLACKBOX) != payload.get("portable_blackbox_sha256"):
        fail("portable FP blackbox hash changed")

    boundaries = payload.get("portable_vendor_ip_boundaries", [])
    if {item.get("module") for item in boundaries} != expected_modules:
        fail("portable vendor-IP boundary list changed")
    for boundary in boundaries:
        path = REPO_ROOT / boundary["path"]
        if not path.is_file():
            fail(f"missing generated vendor-IP wrapper: {boundary['path']}")
        if sha256(path) != boundary["sha256"]:
            fail(f"generated vendor-IP wrapper hash changed: {boundary['path']}")
        wrapper_modules = {
            declaration["name"]
            for declaration in declarations(path)
            if declaration["kind"] == "module"
        }
        if boundary["module"] not in wrapper_modules:
            fail(
                f"generated wrapper does not declare {boundary['module']}: "
                f"{boundary['path']}"
            )
    print("PASS portable_vendor_boundaries modules=2")


def capi_monitor_sources():
    manifest = (
        CAPI_ROOT /
        "01_capi_integration/accelerator_verification/rtl/manifests/monitor.f"
    )
    sources = []
    for raw_line in manifest.read_text().splitlines():
        source = raw_line.strip()
        if not source or source.startswith("#"):
            continue
        sources.append(f"01_capi_precis/{source}")
    if not sources:
        fail("pinned CAPI monitor manifest is empty")
    return sources


def extract_modelsim_sources(layout):
    tclsh = shutil.which("tclsh")
    if not tclsh:
        fail("tclsh is required to evaluate the ModelSim source flow")
    try:
        result = subprocess.run(
            [
                tclsh,
                str(EXTRACT_SCRIPT),
                layout["algorithm"],
                layout["data_structure"],
                layout["direction"],
                layout["precision"],
                str(layout["total_vertex_cus"]),
            ],
            check=True,
            capture_output=True,
            text=True,
        )
    except subprocess.CalledProcessError:
        fail(f"ModelSim source extraction failed: {layout['id']}")
    sources = []
    for raw_line in result.stdout.splitlines():
        source_path = (SIM_ROOT / raw_line).resolve()
        try:
            source = relative(source_path)
        except ValueError:
            fail(
                f"{layout['id']} ModelSim source escapes repository: "
                f"{raw_line}"
            )
        if source in sources:
            fail(f"{layout['id']} duplicates ModelSim source {source}")
        sources.append(source)
    expected_tail = [*capi_monitor_sources(), GRAPH_BIND, CAPI_TOP]
    if sources[-len(expected_tail):] != expected_tail:
        fail(f"{layout['id']} verification/top source tail changed")
    return sources[:-len(expected_tail)]


def validate_topology(layout, sources):
    package_suffix = (
        f"/{layout['precision']}/pkg/globals_cu_pkg.sv"
    )
    matches = [
        source
        for source in sources
        if source.startswith(
            "03_capi_integration/accelerator_rtl/cu_control/"
        ) and source.endswith(package_suffix)
    ]
    if len(matches) != 1:
        fail(f"{layout['id']} has no unique topology package")
    text = (REPO_ROOT / matches[0]).read_text()
    values = {}
    for name in ("NUM_GRAPH_CU_GLOBAL", "NUM_VERTEX_CU_GLOBAL"):
        match = re.search(
            rf"\bparameter\s+{name}\s*=\s*(\d+)\s*;",
            text,
        )
        if not match:
            fail(f"{layout['id']} package does not declare {name}")
        values[name] = int(match.group(1))
    if values["NUM_GRAPH_CU_GLOBAL"] != layout["graph_cus"]:
        fail(f"{layout['id']} graph-CU topology differs")
    if (
        values["NUM_VERTEX_CU_GLOBAL"] !=
        layout["vertex_cus_per_graph_cu"]
    ):
        fail(f"{layout['id']} vertex-CU topology differs")


def layout_manifest_path(layout):
    suffix = ".f" if layout["status"] == "active" else ".xfail.f"
    return MANIFEST_ROOT / f"{layout['id']}{suffix}"


def validate_layouts(layouts, write):
    source_sets = {}
    for layout in layouts:
        intended = extract_modelsim_sources(layout)
        expected_failure = layout.get("expected_failure")
        missing = [
            source
            for source in intended
            if not (REPO_ROOT / source).is_file()
        ]
        if layout["status"] == "active":
            if expected_failure:
                fail(f"active layout has expected failure: {layout['id']}")
            if missing:
                fail(f"{layout['id']} is missing: {', '.join(missing)}")
            validate_topology(layout, intended)
        else:
            required_contract = {
                "tool": "accelgraph-manifest-validator",
                "tool_version": 1,
                "phase": "source-resolution",
                "normalized_error": "missing-source",
            }
            if not expected_failure:
                fail(f"quarantined layout lacks failure contract: {layout['id']}")
            if expected_failure.get("defect") != (
                "docs/wiki/Verification-Infrastructure.md"
                "#phase-5---pagerank-push-closure"
            ):
                fail(f"{layout['id']} defect link changed")
            for key, value in required_contract.items():
                if expected_failure.get(key) != value:
                    fail(f"{layout['id']} expected failure {key} changed")
            if not missing:
                fail(f"XPASS quarantined layout is now source-complete: {layout['id']}")
            if missing != expected_failure.get("missing_files"):
                fail(f"{layout['id']} missing-file signature changed")
            validate_topology(layout, intended)

        path = layout_manifest_path(layout)
        if write:
            write_source_file(path, layout["id"], intended)
        recorded = read_source_file(
            path,
            allow_missing=layout["status"] == "quarantined",
        )
        if recorded != intended:
            fail(f"{layout['id']} manifest differs from ModelSim")
        source_sets[layout["id"]] = recorded
        outcome = "active" if layout["status"] == "active" else "XFAIL"
        print(
            f"PASS layout {layout['id']} status={outcome} "
            f"files={len(recorded)} missing={len(missing)}"
        )
    expected_files = {
        layout_manifest_path(layout).name for layout in layouts
    }
    actual_files = {path.name for path in MANIFEST_ROOT.glob("*.f")}
    if actual_files != expected_files:
        fail(
            "layout manifest file set changed: "
            f"extra={sorted(actual_files - expected_files)} "
            f"missing={sorted(expected_files - actual_files)}"
        )
    return source_sets


def strip_comments(text):
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.DOTALL)
    return re.sub(r"//.*", "", text)


def declarations(path):
    return [
        {"kind": kind, "name": name}
        for kind, name in DECLARATION_RE.findall(
            strip_comments(path.read_text(errors="replace"))
        )
    ]


def sha256(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def verification_unit(source):
    if "/accelerator_verification/rtl/unit/" in source:
        return "unit-" + source.split("/rtl/unit/", 1)[1].split("/", 1)[0]
    if "/accelerator_verification/rtl/integration/" in source:
        return "integration-" + source.split(
            "/rtl/integration/", 1
        )[1].split("/", 1)[0]
    if "/accelerator_verification/" in source:
        return "graph-rtl-lifecycle"
    if "/cu_control/" not in source:
        fail(f"graph RTL is outside cu_control/ or verification/: {source}")
    relative_source = source.split("/cu_control/", 1)[1]
    parts = relative_source.split("/")
    unit_parts = parts[:3]
    if len(parts) >= 6 and parts[4] in {"cu", "pkg"}:
        unit_parts.append(parts[3])
    return "-".join(unit_parts + [Path(source).stem])


def build_inventory(layouts, source_sets, vendor_boundaries):
    active_membership = defaultdict(list)
    quarantined_membership = defaultdict(list)
    for layout in layouts:
        memberships = (
            active_membership
            if layout["status"] == "active"
            else quarantined_membership
        )
        for order, source in enumerate(source_sets[layout["id"]]):
            if source.startswith("03_capi_integration/accelerator_rtl/"):
                memberships[source].append({
                    "layout": layout["id"],
                    "order": order,
                })

    active_membership[GRAPH_BIND].append({
        "layout": "graph-monitor-bind",
        "order": 0,
    })
    active_membership[GRAPH_TB].append({
        "layout": "graph-monitor-testbench",
        "order": 0,
    })
    active_membership[relative(FP_BLACKBOX)].append({
        "layout": "portable-vendor-boundaries",
        "order": 0,
    })
    discovered = sorted({
        relative(path)
        for root in (GRAPH_RTL_ROOT, GRAPH_VERIFICATION_RTL_ROOT)
        for path in root.rglob("*")
        if path.is_file() and path.suffix.lower() in RTL_SUFFIXES
    })
    for source in discovered:
        if (
            "/cu_PageRank/CSR/PUSH/" in source and
            source not in quarantined_membership
        ):
            quarantined_membership[source].append({
                "layout": "cu_PageRank_CSR_PUSH_source_tree",
                "order": -1,
            })
    design_sources = [
        source
        for source in discovered
        if source.startswith(
            "03_capi_integration/accelerator_rtl/cu_control/"
        )
    ]
    design_declarations = [
        declaration
        for source in design_sources
        for declaration in declarations(REPO_ROOT / source)
    ]
    design_counts = defaultdict(int)
    for declaration in design_declarations:
        design_counts[declaration["kind"]] += 1
    if dict(sorted(design_counts.items())) != {
        "module": 93,
        "package": 22,
    }:
        fail(f"graph declaration denominator changed: {dict(design_counts)}")

    module_sources = [
        source
        for source in design_sources
        if "/pkg/" not in source and "/global_pkg/" not in source
    ]
    module_hashes = {
        sha256(REPO_ROOT / source) for source in module_sources
    }
    if len(module_hashes) != 69:
        fail(f"distinct graph module hash count changed: {len(module_hashes)}")

    hash_groups = defaultdict(list)
    for source in design_sources:
        hash_groups[sha256(REPO_ROOT / source)].append(source)

    files = []
    for source in discovered:
        if source in active_membership and source in quarantined_membership:
            fail(f"RTL is both active and quarantined: {source}")
        if source in active_membership:
            status = "active"
            membership = active_membership[source]
            evidence = "active layout or graph monitor evidence"
        elif source.startswith((
            "03_capi_integration/accelerator_verification/rtl/unit/",
            "03_capi_integration/accelerator_verification/rtl/integration/",
        )):
            status = "active"
            if "/rtl/unit/" in source:
                kind = "unit"
                suite = source.split("/rtl/unit/", 1)[1].split("/", 1)[0]
                suite_root = GRAPH_VERIFICATION_RTL_ROOT / kind / suite
            else:
                kind = "integration"
                suite = "graph"
                suite_root = GRAPH_VERIFICATION_RTL_ROOT / kind
            runners = list(suite_root.glob("run_*.py"))
            scenarios = list(suite_root.glob("*scenarios*.json"))
            coverage = list(suite_root.glob("*coverage*.json"))
            if not runners or not scenarios or not coverage:
                fail(
                    f"{kind} testbench lacks executable evidence: "
                    f"{relative(suite_root)}"
                )
            membership = [{
                "layout": f"{kind}-{suite}",
                "order": 0,
            }]
            active_membership[source].extend(membership)
            evidence = f"executable {kind} testbench: {suite}"
        elif source in quarantined_membership:
            status = "quarantined"
            membership = quarantined_membership[source]
            evidence = (
                "PageRank PUSH expected failure"
            )
        else:
            fail(f"unclassified graph RTL: {source}")

        path = REPO_ROOT / source
        found_declarations = declarations(path)
        source_hash = sha256(path)
        kind = "bind" if source.endswith("_bind.sv") else "rtl"
        if found_declarations:
            kinds = sorted({item["kind"] for item in found_declarations})
            kind = kinds[0] if len(kinds) == 1 else "multi-declaration"
        files.append({
            "path": source,
            "status": status,
            "kind": kind,
            "declarations": found_declarations,
            "sha256": source_hash,
            "equivalent_paths": hash_groups.get(source_hash, [source]),
            "verification_unit": verification_unit(source),
            "build_membership": membership,
            "evidence": evidence,
        })

    status_counts = defaultdict(int)
    for item in files:
        status_counts[item["status"]] += 1
    return {
        "schema_version": 2,
        "rtl_roots": [
            relative(GRAPH_RTL_ROOT),
            relative(GRAPH_VERIFICATION_RTL_ROOT),
        ],
        "generated_by": relative(SCRIPT),
        "capi_precis_commit": subprocess.run(
            ["git", "-C", str(CAPI_ROOT), "rev-parse", "HEAD"],
            check=True,
            capture_output=True,
            text=True,
        ).stdout.strip(),
        "portable_vendor_ip_boundaries": vendor_boundaries,
        "summary": {
            "files": len(files),
            "design_modules": 93,
            "design_packages": 22,
            "distinct_module_hashes": 69,
            "status_counts": dict(sorted(status_counts.items())),
        },
        "files": files,
    }


def validate_synthesis(layouts, source_sets):
    synth_script = SYNTH_ROOT / "accel-graph.tcl"
    if "add_graph_accelerator_manifest" not in synth_script.read_text():
        fail("Quartus does not load the graph layout manifest")
    for path in sorted(SYNTH_ROOT.rglob("*.tcl")):
        if path.name == "graph_accelerator_sources.tcl":
            continue
        for line_number, raw_line in enumerate(path.read_text().splitlines(), 1):
            line = raw_line.strip()
            if line.startswith("#") or "accelerator_rtl" not in line:
                continue
            if "glob" in line or re.search(
                r"set_global_assignment\s+-name\s+"
                r"(?:SYSTEMVERILOG|VERILOG|VHDL)_FILE",
                line,
            ):
                fail(
                    f"{relative(path)}:{line_number}: graph RTL must use "
                    "the layout manifest"
                )
    makefile = (SYNTH_ROOT / "Makefile").read_text()
    if re.search(r"\$\(wildcard[^\n]*\.(?:sv|v|vhd|vhdl)", makefile):
        fail("synthesis Makefile still discovers RTL sources by wildcard")
    for required in ("ACCEL_MANIFEST", "$(ACCEL_MANIFEST)"):
        if required not in makefile:
            fail(f"synthesis Makefile is missing {required}")

    test_script = SCRIPT.with_name("test_graph_accelerator_sources.tcl")
    try:
        subprocess.run(
            [shutil.which("tclsh"), str(test_script), str(REPO_ROOT)],
            check=True,
        )
    except subprocess.CalledProcessError:
        fail("Quartus graph manifest loader regression failed")

    quartus_arguments = (
        "$(PROJECT).tcl $(CU_GRAPH_ALGORITHM) $(CU_DATA_STRUCTURE) "
        "$(CU_DIRECTION) $(CU_PRECISION) $(NUM_THREADS)"
    )
    sweep_arguments = (
        "sweep.tcl $(CU_GRAPH_ALGORITHM) $(CU_DATA_STRUCTURE) "
        "$(CU_DIRECTION) $(CU_PRECISION) $(NUM_THREADS)"
    )
    if quartus_arguments not in makefile or sweep_arguments not in makefile:
        fail("Quartus invocation is not coupled to the resolved layout fields")

    make_environment = os.environ.copy()
    for variable in ("MAKEFLAGS", "MAKELEVEL", "MFLAGS"):
        make_environment.pop(variable, None)
    for layout in layouts:
        if layout["status"] != "active":
            if (MANIFEST_ROOT / f"{layout['id']}.f").exists():
                fail(f"quarantined layout has active manifest: {layout['id']}")
            continue
        try:
            result = subprocess.run(
                [
                    "make",
                    "-s",
                    "--no-print-directory",
                    "-C",
                    str(SYNTH_ROOT),
                    f"CU_GRAPH_ALGORITHM={layout['algorithm']}",
                    f"CU_DATA_STRUCTURE={layout['data_structure']}",
                    f"CU_DIRECTION={layout['direction']}",
                    f"CU_PRECISION={layout['precision']}",
                    "print-accelerator-sources",
                ],
                check=True,
                capture_output=True,
                env=make_environment,
                text=True,
            )
        except subprocess.CalledProcessError:
            fail(f"synthesis Make source query failed: {layout['id']}")
        make_sources = [
            relative(SYNTH_ROOT / line)
            for line in result.stdout.splitlines()
            if line
        ]
        if make_sources != source_sets[layout["id"]]:
            fail(f"synthesis Make source order differs: {layout['id']}")

    invalid_layouts = (
        ("cu_PageRank", "CSR", "PUSH", "FloatPoint"),
        ("cu_Unknown", "CSR", "PULL", "None"),
    )
    for algorithm, data_structure, direction, precision in invalid_layouts:
        result = subprocess.run(
            [
                "make",
                "-s",
                "--no-print-directory",
                "-C",
                str(SYNTH_ROOT),
                f"CU_GRAPH_ALGORITHM={algorithm}",
                f"CU_DATA_STRUCTURE={data_structure}",
                f"CU_DIRECTION={direction}",
                f"CU_PRECISION={precision}",
                "print-accelerator-sources",
            ],
            capture_output=True,
            env=make_environment,
            text=True,
        )
        if result.returncode == 0:
            fail(
                "synthesis Make accepted unknown/quarantined layout: "
                f"{algorithm}_{data_structure}_{direction}_{precision}"
            )
    print("PASS source_set quartus=manifest make=exact")


def main():
    parser = argparse.ArgumentParser(
        description="Validate AccelGraph Phase 0 RTL manifests"
    )
    parser.add_argument("--write", action="store_true")
    args = parser.parse_args()

    payload, layouts = load_layouts()
    validate_capi_pin(payload["capi_precis_commit"])
    validate_vendor_boundaries(payload)
    source_sets = validate_layouts(layouts, args.write)
    validate_synthesis(layouts, source_sets)

    inventory = build_inventory(
        layouts,
        source_sets,
        payload["portable_vendor_ip_boundaries"],
    )
    serialized = json.dumps(inventory, indent=2) + "\n"
    if args.write:
        INVENTORY_PATH.write_text(serialized)
        print(f"WROTE {relative(INVENTORY_PATH)}")
    elif not INVENTORY_PATH.is_file():
        fail(f"missing inventory: {relative(INVENTORY_PATH)}; run --write")
    elif INVENTORY_PATH.read_text() != serialized:
        fail(
            "graph RTL inventory is stale; review changes and run "
            "03_capi_integration/accelerator_verification/rtl/"
            "scripts/verify_manifests.py --write"
        )

    summary = inventory["summary"]
    print(
        "PASS graph_rtl_inventory "
        f"files={summary['files']} modules={summary['design_modules']} "
        f"packages={summary['design_packages']} "
        f"hashes={summary['distinct_module_hashes']} "
        f"active={summary['status_counts'].get('active', 0)} "
        f"quarantined={summary['status_counts'].get('quarantined', 0)}"
    )


if __name__ == "__main__":
    main()
