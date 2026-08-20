#!/usr/bin/env python3

"""Standalone runner for the AccelGraph graph integration suite.

Elaborates the real graph cu_control top of every active layout, drives it
through the CAPI command/response/data boundary with an independent graph memory
adapter, exercises the five named graph backpressure domains, and enforces the
exact source hash and layout context denominators.

    ./run_graph_integration.py                    # every active layout
    ./run_graph_integration.py --layout cu_BFS_CSR_PULL_BottomUp
"""

import argparse
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

SCRIPT = Path(__file__).resolve()
SUITE_ROOT = SCRIPT.parent
REPO_ROOT = SCRIPT.parents[4]
SUITES = SUITE_ROOT / "suites.json"
SCENARIOS = SUITE_ROOT / "scenarios.json"
COVERAGE_SPEC = SUITE_ROOT / "coverage.json"
MANIFEST_ROOT = REPO_ROOT / "03_capi_integration/accelerator_verification/rtl/manifests"
FP_MODELS = SUITE_ROOT / "../unit/algorithms/models/fp_stream_models.sv"
FP_REFERENCE = SUITE_ROOT / "../unit/algorithms/models/fp32_reference.cpp"
MAIN_TEMPLATE = SUITE_ROOT / "../unit/algorithms/main/algorithms_main.cpp.in"
VENDOR_BLACKBOXES = (
    REPO_ROOT / "03_capi_integration/accelerator_verification/rtl/models/fp_vendor_blackboxes.sv"
)

WARNINGS = [
    "-Wall",
    "-Wno-ASCRANGE",
    "-Wno-BLKANDNBLK",
    "-Wno-BLKSEQ",
    "-Wno-CASEINCOMPLETE",
    "-Wno-CMPCONST",
    "-Wno-DECLFILENAME",
    "-Wno-EOFNEWLINE",
    "-Wno-GENUNNAMED",
    "-Wno-IMPORTSTAR",
    "-Wno-MULTIDRIVEN",
    "-Wno-PINCONNECTEMPTY",
    "-Wno-SYNCASYNCNET",
    "-Wno-TIMESCALEMOD",
    "-Wno-UNDRIVEN",
    "-Wno-UNOPTFLAT",
    "-Wno-UNUSEDPARAM",
    "-Wno-UNUSEDSIGNAL",
    "-Wno-WIDTHEXPAND",
    "-Wno-WIDTHTRUNC",
    "-Werror-IMPLICIT",
    "-Werror-MODDUP",
    "-Werror-PINMISSING",
    "-Werror-PINNOTFOUND",
    "-Werror-PKGNODECL",
]

# Machine readable ownership claim for this suite.  Printed by exactly one code
# path - emit_owner_line - and only when the run proved full closure of every
# layout context of the graph-top family.  A filtered run, a blocked or defect
# context, a missing mutation, or any coverage gap keeps it silent.
OWNER_LINE = "OWNERS:graph-top"
OWNED_FAMILIES = frozenset(OWNER_LINE.split(":", 1)[1].split(","))


def emit_owner_line(closure):
    """Print the ownership claim only when every closure condition holds."""
    if not closure["closed"]:
        return False
    print(OWNER_LINE)
    return True


def closure_state(args, families, results, coverage_gaps):
    """Return the exact closure decision and every reason it was refused."""
    reasons = []
    if args.family or args.layout:
        reasons.append("filtered run")
    if getattr(args, "emit_baseline", None):
        reasons.append("baseline emission run")
    if args.no_mutations:
        reasons.append("mutations disabled")
    declared = {family["family"] for family in families}
    if declared != OWNED_FAMILIES:
        reasons.append(f"family set {sorted(declared)} != owned {sorted(OWNED_FAMILIES)}")
    executed = {}
    for result in results:
        executed.setdefault(result["family"], set()).add(result["layout"])
        if result["status"] != "active":
            reasons.append(f"{result['family']}::{result['layout']} status={result['status']}")
        if result.get("expected_defect"):
            reasons.append(f"{result['family']}::{result['layout']} declared defect")
        if len(result["mutations_detected"]) != result["mutations_total"]:
            reasons.append(f"{result['family']}::{result['layout']} mutations incomplete")
    for family in families:
        wanted = {context["layout"] for context in family["contexts"]}
        if executed.get(family["family"], set()) != wanted:
            reasons.append(f"{family['family']} contexts incomplete")
    if coverage_gaps:
        reasons.append(f"coverage gaps: {coverage_gaps}")
    return {"closed": not reasons, "reasons": reasons}


class SuiteFailure(Exception):
    pass


def fail(message):
    raise SuiteFailure(message)


def run(command, **kwargs):
    return subprocess.run(command, check=False, text=True, **kwargs)


def sha256_of(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def verilator_version(verilator):
    result = run([verilator, "--version"], capture_output=True)
    if result.returncode:
        return 0
    match = re.search(r"Verilator\s+(\d+)", result.stdout)
    return int(match.group(1)) if match else 0


def load_json(path):
    if not path.is_file():
        fail(f"missing required input {path}")
    return json.loads(path.read_text())


def manifest_sources(layout, excluded, exclude_modules):
    manifest = MANIFEST_ROOT / f"{layout}.f"
    if not manifest.is_file():
        fail(f"missing layout manifest {manifest}")
    sources = []
    for line in manifest.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        name = Path(line).name
        if name in excluded or name in exclude_modules:
            continue
        resolved = REPO_ROOT / line
        if not resolved.is_file():
            fail(f"manifest {layout} references a missing source {line}")
        sources.append(line)
    if not sources:
        fail(f"layout manifest {layout} produced no sources")
    return sources


def compile_case(verilator, build_dir, top, sources, defines, coverage, include_dirs=()):
    build_dir.mkdir(parents=True, exist_ok=True)
    harness = build_dir / f"{top}_main.cpp"
    harness.write_text(MAIN_TEMPLATE.read_text().replace("@TOP@", top))
    command = [
        verilator,
        "--cc",
        "--exe",
        "--build",
        "--timing",
        "--assert",
        "-Wno-fatal",
        *WARNINGS,
        "--top-module",
        top,
        "--Mdir",
        str(build_dir),
    ]
    if coverage:
        command.extend(["--coverage-line", "--coverage-toggle"])
    for include_dir in include_dirs:
        command.append(f"+incdir+{include_dir}")
    for define in defines:
        command.append(f"+define+{define}")
    command.extend(str(source) for source in sources)
    command.append(str(FP_REFERENCE))
    command.append(str(harness))
    result = run(command, capture_output=True, cwd=REPO_ROOT)
    if result.returncode:
        fail("verilator compile failed\n" + result.stdout + result.stderr)
    return command


def run_case(build_dir, top, timeout):
    executable = build_dir / f"V{top}"
    if not executable.is_file():
        fail(f"missing simulation binary {executable}")
    try:
        return run([str(executable)], cwd=build_dir, capture_output=True, timeout=timeout)
    except subprocess.TimeoutExpired as error:
        fail(f"simulation timed out after {timeout}s: {error}")


COVERAGE_RECORD = re.compile(r"^C '(.*)' (\d+)$")


def parse_coverage(coverage_dat, sources):
    """Raw Verilator coverage points of the declarations under test.

    Ported from the graph-common suite so both suites census coverage the same
    way: one entry per (file, page, line, column, signal, scope) with its raw
    count, restricted to the sources being measured.
    """
    if not Path(coverage_dat).is_file():
        fail("coverage.dat was not produced")
    wanted = {str(source) for source in sources}
    points = {}
    for line in Path(coverage_dat).read_bytes().decode("latin1").splitlines():
        match = COVERAGE_RECORD.match(line)
        if not match:
            continue
        body, count = match.group(1), int(match.group(2))
        fields = {}
        for chunk in body.split("\x01"):
            if not chunk:
                continue
            key, _, value = chunk.partition("\x02")
            fields[key] = value
        source = fields.get("f")
        if source not in wanted:
            continue
        page = fields.get("page", "").split("/")[0]
        key = (source, page, fields.get("l"), fields.get("n"), fields.get("o"), fields.get("h"))
        points[key] = points.get(key, 0) + count
    return points



MERGE_ROOT = REPO_ROOT / "02_capi_graph/obj/rtl_coverage_merge"
PRODUCTION_PREFIX = str(REPO_ROOT / "03_capi_integration/accelerator_rtl")


def parse_production_points(coverage_dat):
    """Raw points of every production source in a run, keyed without scope.

    Dropping the instance scope is what makes cross-suite merging meaningful: a
    kernel bit exercised by the algorithm-shell or graph-top run counts for the
    same declaration in the kernel run, because it is the same source point.
    """
    if not Path(coverage_dat).is_file():
        fail("coverage.dat was not produced")
    points = {}
    for line in Path(coverage_dat).read_bytes().decode("latin1").splitlines():
        match = COVERAGE_RECORD.match(line)
        if not match:
            continue
        body, count = match.group(1), int(match.group(2))
        fields = {}
        for chunk in body.split("\x01"):
            if not chunk:
                continue
            key, _, value = chunk.partition("\x02")
            fields[key] = value
        source = fields.get("f", "")
        if not source.startswith(PRODUCTION_PREFIX):
            continue
        page = fields.get("page", "").split("/")[0]
        key = "|".join([source, page, fields.get("l", ""), fields.get("n", ""), fields.get("o", "")])
        points[key] = points.get(key, 0) + count
    return points


def export_points(layout, family, points):
    MERGE_ROOT.mkdir(parents=True, exist_ok=True)
    (MERGE_ROOT / f"{layout}__{family}.json").write_text(json.dumps(points) + "\n")


def merged_points(layout, dut_path):
    """Union of every exported run of this layout, restricted to one declaration."""
    merged = {}
    source = str(REPO_ROOT / dut_path)
    for path in sorted(MERGE_ROOT.glob(f"{layout}__*.json")):
        for key, count in json.loads(path.read_text()).items():
            if not key.startswith(source + "|"):
                continue
            merged[key] = merged.get(key, 0) + count
    return merged


def census_from_merged(merged):
    denominator = {}
    zeros = []
    for key, count in merged.items():
        source, page, line, _column, name = key.split("|", 4)
        bucket = denominator.setdefault(Path(source).name, {}).setdefault(
            page, {"found": 0, "hit": 0}
        )
        bucket["found"] += 1
        if count > 0:
            bucket["hit"] += 1
        else:
            zeros.append(f"{Path(source).name}:{line} {page} {name}")
    return denominator, sorted(zeros)


def summarise_coverage(points):
    """Raw found/hit denominators per measured file and coverage page."""
    summary = {}
    for (source, page, _line, _column, _name, _scope), count in points.items():
        bucket = summary.setdefault(Path(source).name, {}).setdefault(
            page, {"found": 0, "hit": 0}
        )
        bucket["found"] += 1
        bucket["hit"] += 1 if count > 0 else 0
    return summary


def unhit_points(points):
    """The zero-point census: every instrumented point never exercised."""
    return sorted(
        f"{Path(source).name}:{line} {page} {name} scope={scope}"
        for (source, page, line, _column, name, scope), count in points.items()
        if count == 0
    )


def percent(hit, found):
    return 0.0 if found == 0 else round(100.0 * hit / found, 2)


def points_per_page(points):
    """Group a census point list by the coverage page it belongs to."""
    pages = {}
    for point in points:
        page = point.split(" ")[1]
        pages[page] = pages.get(page, 0) + 1
    return pages


def reachable_coverage(evidence, declared):
    """Coverage of the points the stimulus can reach, per coverage page.

    The reachable denominator is the raw denominator minus the points this
    context declares unreachable, so a closed context reports every reachable
    point exercised rather than a percentage of the raw instrumentation.
    """
    waived = points_per_page(entry["point"] for entry in declared)
    reachable = {}
    for page, counters in evidence["code_coverage"].items():
        found = counters["found"] - waived.get(page, 0)
        reachable[page] = {
            "hit": counters["hit"],
            "found": found,
            "percent": percent(counters["hit"], found),
        }
    return reachable


def census_gaps(label, evidence, coverage_spec, emitting_baseline):
    """The exact census gate for one context.

    Every point the run never exercised is either declared unreachable with a
    category and a reason, or it is a gap; a declared point that the run did
    exercise is a stale declaration; and the raw denominators are pinned so a
    change of instrumentation cannot move the census silently.
    """
    gaps = []
    declared = coverage_spec["unreachable"].get(label)
    if declared is None:
        if not emitting_baseline:
            gaps.append(f"{label} has no unreachable census record")
        declared = []
    for entry in declared:
        if not entry.get("reason") or not entry.get("category"):
            gaps.append(
                f"{label} declares {entry.get('point')} without a reason and category"
            )
        elif entry["category"] not in coverage_spec["categories"]:
            gaps.append(
                f"{label} declares {entry['point']} with the undeclared category "
                f"{entry['category']}"
            )
    waived = [entry["point"] for entry in declared]
    unexpected = [point for point in evidence["zero_points"] if point not in waived]
    if unexpected:
        gaps.append(f"{label} left reachable coverage points unexercised: {unexpected}")
    stale = [point for point in waived if point not in evidence["zero_points"]]
    if stale:
        gaps.append(
            f"{label} declares unreachable coverage points that are exercised: {stale}"
        )
    pinned = coverage_spec["denominators"].get(label)
    if pinned is None:
        if not emitting_baseline:
            gaps.append(f"{label} has no pinned coverage denominator")
    elif pinned != evidence["coverage_denominator"]:
        gaps.append(
            f"{label} coverage denominator changed\n  pinned  ={pinned}\n"
            f"  observed={evidence['coverage_denominator']}"
        )
    evidence["reachable_coverage"] = reachable_coverage(evidence, declared)
    target = coverage_spec["targets"]
    for metric, key in (
        ("line", "reachable_statement_percent"),
        ("branch", "reachable_branch_percent"),
        ("toggle", "reachable_control_toggle_percent"),
    ):
        measured = evidence["reachable_coverage"]["v_" + metric]
        if measured["found"] == 0:
            continue
        if measured["percent"] < target[key]:
            gaps.append(f"{label}:{metric}")
            print(
                f"COVERAGE-GAP {label} {metric}={measured['percent']}% < "
                f"{target[key]}% ({measured['hit']}/{measured['found']})"
            )
    return gaps


def check_context_denominator(matrix, family, contexts):
    """The declared contexts must equal the manifest contexts, exactly."""
    declared = {}
    for module in matrix["modules"]:
        if module.get("family") != family["family"]:
            continue
        declared.setdefault(module["path"], set()).update(module["contexts"])
    executed = {}
    for context in contexts:
        executed.setdefault(context["dut"], set()).add(context["layout"])
    if declared != executed:
        fail(
            f"family {family['family']} context denominator mismatch\n"
            f"  manifest: {json.dumps({k: sorted(v) for k, v in declared.items()}, indent=2)}\n"
            f"  executed: {json.dumps({k: sorted(v) for k, v in executed.items()}, indent=2)}"
        )


def check_hashes(inventory, contexts):
    """Inventory hash gate with declared production patches (see suites.json)."""
    index = {entry["path"]: entry["sha256"] for entry in inventory["files"]}
    patches = {patch["path"]: patch for patch in RTL_PATCHES}
    for context in contexts:
        path = context["dut"]
        if path not in index:
            fail(f"DUT {path} is absent from the RTL inventory")
        actual = sha256_of(REPO_ROOT / path)
        if actual == index[path]:
            continue
        patch = patches.get(path)
        if patch is None:
            fail(f"DUT {path} hash drifted\n  inventory={index[path]}\n  actual   ={actual}")
        if patch["inventory_sha256"] != index[path] or patch["patched_sha256"] != actual:
            fail(
                f"DUT {path} patch declaration is stale\n"
                f"  inventory={index[path]} declared={patch['inventory_sha256']}\n"
                f"  actual   ={actual} declared={patch['patched_sha256']}"
            )
        print(
            f"PATCHED {path} {patch['inventory_sha256'][:12]}->{patch['patched_sha256'][:12]} "
            f"defect={patch['defect']}"
        )


def needs_vendor_boundary(layout):
    return "FloatPoint" in layout


def build_sources(family, context, mutated_dut=None):
    sources = manifest_sources(
        context["layout"],
        set(SUITE["excluded_manifest_files"]),
        set(family.get("exclude_modules", [])),
    )
    resolved = []
    for source in sources:
        if mutated_dut is not None and source == context["dut"]:
            resolved.append(str(mutated_dut))
        else:
            resolved.append(str(REPO_ROOT / source))
    if context["dut"] not in sources:
        resolved.append(
            str(mutated_dut) if mutated_dut is not None else str(REPO_ROOT / context["dut"])
        )
    if context.get("fp_models"):
        resolved.append(str(FP_MODELS))
    elif needs_vendor_boundary(context["layout"]):
        resolved.append(str(VENDOR_BLACKBOXES))
    if context.get("shim"):
        resolved.append(str(SUITE_ROOT / context["shim"]))
    resolved.extend(str(SUITE_ROOT / tb) for tb in family["tb"])
    return resolved


def execute_context(args, verilator, family, context, matrix_status):
    layout = context["layout"]
    name = f"{family['family']}::{layout}"
    build_dir = BUILD_ROOT / family["family"] / layout
    shutil.rmtree(build_dir, ignore_errors=True)
    build_dir.mkdir(parents=True)

    sources = build_sources(family, context)
    defines = list(context.get("defines", []))
    include_dirs = [str(SUITE_ROOT / d) for d in family.get("include_dirs", [])]
    command = compile_case(
        verilator, build_dir, family["top"], sources, defines, coverage=True,
        include_dirs=include_dirs,
    )
    result = run_case(build_dir, family["top"], args.timeout)
    output = result.stdout + result.stderr
    (build_dir / "run.log").write_text(output)

    blocked = family.get("status") == "blocked"
    expected_defect = context.get("expected_defect")
    match = re.search(family["evidence_regex"], output)
    if match is None:
        fail(f"{name} did not report its evidence line\n{output[-4000:]}")
    if expected_defect:
        if f"signature={expected_defect['signature']}" not in output or "NODEFECT" in output:
            if "NODEFECT" in output:
                fail(
                    f"{name} unexpectedly passed: the declared defect "
                    f"{expected_defect['signature']} no longer reproduces (XPASS)"
                )
            fail(
                f"{name} failed with a different signature than "
                f"{expected_defect['signature']}\n{output[-4000:]}"
            )
        if result.returncode != 0:
            fail(f"{name} aborted before reporting complete evidence\n{output[-4000:]}")
    elif not blocked and result.returncode != 0:
        fail(f"{name} failed\n{output[-4000:]}")

    export_points(layout, family["family"], parse_production_points(build_dir / "coverage.dat"))
    points = parse_coverage(build_dir / "coverage.dat", [REPO_ROOT / context["dut"]])
    if not points:
        fail(f"{name} produced no coverage point for the declaration under test")
    counters = {
        page: [bucket["hit"], bucket["found"]]
        for page, bucket in summarise_coverage(points)
        .get(Path(context["dut"]).name, {})
        .items()
    }
    for page in ("v_line", "v_branch", "v_toggle"):
        counters.setdefault(page, [0, 0])
    coverage_counters = counters
    evidence = {
        "family": family["family"],
        "test_id": family["test_id"],
        "oracle_id": family["oracle_id"],
        "layout": layout,
        "status": family.get("status", "active"),
        "matrix_status": matrix_status,
        "dut": context["dut"],
        "dut_sha256": sha256_of(REPO_ROOT / context["dut"]),
        "defines": defines,
        "vendor_ip": "behavioural-stand-in" if context.get("fp_models") else "not-applicable",
        "evidence": list(match.groups()),
        "code_coverage": {
            key: {
                "hit": value[0],
                "found": value[1],
                "percent": percent(value[0], value[1]),
            }
            for key, value in coverage_counters.items()
        },
        "coverage_denominator": summarise_coverage(points),
        "zero_points": unhit_points(points),
        "reproduction": " ".join(command),
    }
    if blocked:
        evidence["expected_failure"] = family["expected_failure"]
    if expected_defect:
        evidence["expected_defect"] = expected_defect
        evidence["status"] = "defect-reproduced"

    detected = []
    if not args.no_mutations:
        source_text = (REPO_ROOT / context["dut"]).read_text()
        for mutation in context.get("mutations", []):
            if source_text.count(mutation["from"]) != 1:
                fail(
                    f"{name} mutation anchor is not unique: {mutation['id']} "
                    f"({source_text.count(mutation['from'])} matches)"
                )
            mutated_dir = build_dir / f"mutation-{mutation['id']}"
            mutated_dir.mkdir(parents=True)
            mutated_dut = mutated_dir / Path(context["dut"]).name
            mutated_dut.write_text(source_text.replace(mutation["from"], mutation["to"]))
            mutation_sources = build_sources(family, context, mutated_dut=mutated_dut)
            compile_case(
                verilator,
                mutated_dir / "build",
                family["top"],
                mutation_sources,
                defines,
                coverage=False,
                include_dirs=include_dirs,
            )
            mutation_result = run_case(mutated_dir / "build", family["top"], args.timeout)
            mutation_output = mutation_result.stdout + mutation_result.stderr
            if mutation_result.returncode == 0:
                fail(f"{name} mutation was not detected: {mutation['id']}")
            if mutation["diagnostic"] not in mutation_output:
                fail(
                    f"{name} mutation {mutation['id']} failed for the wrong reason\n"
                    + mutation_output[-2000:]
                )
            detected.append(mutation["id"])
    evidence["mutations_detected"] = detected
    evidence["mutations_total"] = len(context.get("mutations", []))
    (build_dir / "summary.json").write_text(json.dumps(evidence, indent=2) + "\n")
    return evidence


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--family", action="append", default=[])
    parser.add_argument("--layout", action="append", default=[])
    parser.add_argument("--no-mutations", action="store_true")
    parser.add_argument("--timeout", type=int, default=900)
    parser.add_argument(
        "--emit-baseline",
        metavar="PATH",
        help="write the observed coverage denominators and zero-point census for review; "
             "the run is reported as partial and never claims ownership",
    )
    args = parser.parse_args()

    verilator = os.environ.get("VERILATOR", "verilator")
    required = os.environ.get("RTL_VERIFICATION_REQUIRED") == "1"
    if not shutil.which(verilator) or verilator_version(verilator) < 5:
        if required:
            fail("Verilator 5 or newer is required")
        print("SKIP graph_integration: install Verilator 5 or set RTL_VERIFICATION_REQUIRED=1")
        return 0

    layouts = load_json(MANIFEST_ROOT / "layouts.json")
    inventory = load_json(MANIFEST_ROOT / "rtl-inventory.json")
    matrix = load_json(MANIFEST_ROOT / "module-test-matrix.json")
    scenarios = load_json(SCENARIOS)
    coverage_spec = load_json(COVERAGE_SPEC)

    active = {entry["id"] for entry in layouts["layouts"] if entry["status"] == "active"}
    if len(active) != 8:
        fail(f"expected 8 active layouts, found {len(active)}")
    if matrix["plan_id"] != SUITE["plan_id"]:
        fail("coverage plan identity drifted")

    matrix_status = {}
    for module in matrix["modules"]:
        matrix_status.setdefault(module["family"], set()).add(module["implementation_status"])

    results = []
    coverage_gaps = []
    observed_denominators = {}
    observed_zero_points = {}
    executed_contexts = 0
    for family in SUITE["families"]:
        if args.family and family["family"] not in args.family:
            continue
        contexts = family["contexts"]
        for context in contexts:
            if context["layout"] not in active:
                fail(f"{family['family']} references inactive layout {context['layout']}")
        check_context_denominator(matrix, family, contexts)
        check_hashes(inventory, contexts)
        expected_bins = scenarios["families"][family["family"]]["required_bins"]["total"]
        for context in contexts:
            if args.layout and context["layout"] not in args.layout:
                continue
            status = sorted(matrix_status.get(family["family"], {"unknown"}))
            evidence = execute_context(args, verilator, family, context, status)
            if family.get("status") != "blocked":
                reported_bins = int(evidence["evidence"][-2])
                if reported_bins != expected_bins:
                    fail(
                        f"{family['family']}::{context['layout']} reported "
                        f"{reported_bins} bins, scenarios.json declares {expected_bins}"
                    )
            label = f"{context['layout']}/{family['family']}"
            observed_denominators[label] = evidence["coverage_denominator"]
            observed_zero_points[label] = evidence["zero_points"]
            coverage_gaps.extend(
                census_gaps(label, evidence, coverage_spec, args.emit_baseline)
            )
            results.append(evidence)
            executed_contexts += 1
            label = "BLOCKED" if family.get("status") == "blocked" else (
                "DEFECT" if context.get("expected_defect") else "PASS"
            )
            print(
                f"{label} "
                f"{family['family']}::{context['layout']} "
                f"line={evidence['reachable_coverage']['v_line']['percent']}% "
                f"branch={evidence['reachable_coverage']['v_branch']['percent']}% "
                f"toggle={evidence['reachable_coverage']['v_toggle']['percent']}% "
                f"zeros={len(evidence['zero_points'])} "
                f"mutations={len(evidence['mutations_detected'])}/{evidence['mutations_total']}"
            )

    summary = {
        "schema_version": 1,
        "suite_id": SUITE["suite_id"],
        "plan_id": SUITE["plan_id"],
        "capi_precis_commit": layouts["capi_precis_commit"],
        "coverage_plan_sha256": matrix["coverage_plan_sha256"],
        "rtl_inventory_sha256": matrix["rtl_inventory_sha256"],
        "context_executions": executed_contexts,
        "results": results,
        "coverage_denominators": observed_denominators,
        "zero_point_census": observed_zero_points,
    }
    BUILD_ROOT.mkdir(parents=True, exist_ok=True)
    (BUILD_ROOT / "summary.json").write_text(json.dumps(summary, indent=2) + "\n")
    if args.emit_baseline:
        Path(args.emit_baseline).write_text(
            json.dumps(
                {
                    "denominators": observed_denominators,
                    "unreachable": {
                        label: [{"point": point, "category": "TODO", "reason": "TODO"}
                                for point in points]
                        for label, points in observed_zero_points.items()
                    },
                },
                indent=2,
                sort_keys=True,
            )
            + "\n"
        )
        print(f"BASELINE graph_integration written to {args.emit_baseline}")
    blocked = [r for r in results if r["status"] == "blocked"]
    closure = closure_state(args, SUITE["families"], results, coverage_gaps)
    summary["closure"] = closure
    (BUILD_ROOT / "summary.json").write_text(json.dumps(summary, indent=2) + "\n")
    print(
        f"SUITE graph_integration contexts={executed_contexts} "
        f"blocked={len(blocked)} coverage_gaps={len(coverage_gaps)} "
        f"closed={closure['closed']} summary={BUILD_ROOT / 'summary.json'}"
    )
    if not closure["closed"]:
        for reason in closure["reasons"]:
            print(f"NOT-CLOSED graph_integration {reason}")
    emit_owner_line(closure)
    return 0


SUITE = json.loads(SUITES.read_text())
RTL_PATCHES = json.loads(
    (SUITE_ROOT / "../unit/algorithms/suites.json").read_text()
).get("rtl_patches", [])
BUILD_ROOT = REPO_ROOT / SUITE["build_root"]


if __name__ == "__main__":
    try:
        sys.exit(main())
    except SuiteFailure as error:
        print(f"FAIL graph_integration {error}", file=sys.stderr)
        sys.exit(1)
