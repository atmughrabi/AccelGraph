#!/usr/bin/env python3
"""Executable unit coverage for AccelGraph graph plumbing and schedulers."""

from __future__ import annotations

import argparse
import concurrent.futures
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
from collections import defaultdict
from pathlib import Path
from typing import Any, Iterable


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[4]
MANIFEST_DIR = (
    REPO_ROOT
    / "03_capi_integration"
    / "accelerator_verification"
    / "rtl"
    / "manifests"
)
ARTIFACT_ROOT = REPO_ROOT / "02_capi_graph" / "obj" / "rtl_unit_engines"
SCENARIOS_PATH = SCRIPT_DIR / "engine_scenarios.json"
COVERAGE_RULES_PATH = SCRIPT_DIR / "coverage_rules.json"
MATRIX_PATH = MANIFEST_DIR / "module-test-matrix.json"
LAYOUTS_PATH = MANIFEST_DIR / "layouts.json"
SUM_REDUCE_PATH = (
    REPO_ROOT
    / "03_capi_integration"
    / "accelerator_rtl"
    / "cu_control"
    / "cu_PageRank"
    / "CSR"
    / "PULL"
    / "global_cu"
    / "sum_reduce.sv"
)
FP_MODEL_PATH = (
    REPO_ROOT
    / "03_capi_integration"
    / "accelerator_verification"
    / "rtl"
    / "models"
    / "fp_vendor_blackboxes.sv"
)
CAPI_ROOT = (
    REPO_ROOT / "01_capi_precis" / "01_capi_integration"
)

WARNING_FLAGS = [
    "-Wno-fatal",
    "-Wno-ASCRANGE",
    "-Wno-WIDTH",
    "-Wno-UNUSEDSIGNAL",
    "-Wno-UNUSEDPARAM",
    "-Wno-MULTIDRIVEN",
    "-Wno-DECLFILENAME",
    "-Wno-PINCONNECTEMPTY",
]
OWNER_FAMILIES = (
    "algorithm-arbiters",
    "cluster-scheduler",
    "edge-job",
    "edge-read",
    "edge-write",
    "graph-algorithm-scheduler",
    "vertex-job",
)


def load_json(path: Path) -> dict[str, Any]:
    with path.open(encoding="utf-8") as handle:
        return json.load(handle)


def write_json(path: Path, payload: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as handle:
        json.dump(payload, handle, indent=2, sort_keys=True)
        handle.write("\n")


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def safe_name(value: str) -> str:
    return re.sub(r"[^A-Za-z0-9_.-]+", "_", value)


def current_capi_commit() -> str:
    return subprocess.run(
        ["git", "-C", str(REPO_ROOT / "01_capi_precis"), "rev-parse", "HEAD"],
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        text=True,
        check=True,
    ).stdout.strip()


def resolved_unit_manifest(manifest: Path, output_path: Path) -> Path:
    lines: list[str] = []
    for raw_line in manifest.read_text(encoding="utf-8").splitlines():
        stripped = raw_line.strip()
        if not stripped or stripped.startswith("#"):
            lines.append(raw_line)
            continue
        lines.append(str((REPO_ROOT / stripped).resolve()))
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text("\n".join(lines) + "\n", encoding="utf-8")
    return output_path


def run_command(
    command: list[str],
    *,
    cwd: Path,
    log_path: Path,
    timeout: int = 300,
) -> dict[str, Any]:
    log_path.parent.mkdir(parents=True, exist_ok=True)
    try:
        process = subprocess.run(
            command,
            cwd=cwd,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            timeout=timeout,
            check=False,
        )
        output = process.stdout
        return_code = process.returncode
    except subprocess.TimeoutExpired as error:
        output = (error.stdout or "") + "\nTIMEOUT\n"
        return_code = 124
    log_path.write_text(output, encoding="utf-8")
    return {
        "command": command,
        "return_code": return_code,
        "log": str(log_path.relative_to(ARTIFACT_ROOT)),
        "output": output,
    }


def diagnostic(output: str) -> str:
    assertion_lines = [
        line.strip()
        for line in output.splitlines()
        if "ASSERT " in line
    ]
    if assertion_lines:
        return assertion_lines[-1]
    lines = [
        line.strip()
        for line in output.splitlines()
        if "%Fatal" in line or "%Error" in line
    ]
    return lines[-1] if lines else "process failed without an assertion diagnostic"


def parse_bins(output: str) -> set[str]:
    return {
        line.split("AG_BIN:", 1)[1].strip()
        for line in output.splitlines()
        if "AG_BIN:" in line
    }


def parse_coordinates(output: str) -> set[tuple[int, int]]:
    coordinates: set[tuple[int, int]] = set()
    for line in output.splitlines():
        if "AG_COORD:" not in line:
            continue
        _, graph, vertex = line.strip().split(":")
        coordinates.add((int(graph), int(vertex)))
    return coordinates


def build_binary(
    *,
    name: str,
    top: str,
    sources: list[Path],
    jobs: int,
    parameters: dict[str, int] | None = None,
    defines: Iterable[str] = (),
    manifest: Path | None = None,
    include_dirs: Iterable[Path] = (),
) -> dict[str, Any]:
    build_dir = ARTIFACT_ROOT / "build" / safe_name(name)
    mdir = build_dir / "obj"
    build_dir.mkdir(parents=True, exist_ok=True)
    main_path = build_dir / "coverage_main.cpp"
    main_path.write_text(
        "\n".join(
            [
                "#include <memory>",
                "#include <verilated.h>",
                "#include <verilated_cov.h>",
                f'#include "V{top}.h"',
                "",
                "int main(int argc, char** argv) {",
                "    auto context = std::make_unique<VerilatedContext>();",
                "    context->commandArgs(argc, argv);",
                f"    auto top = std::make_unique<V{top}>(context.get());",
                "    while (!context->gotFinish()) {",
                "        top->eval();",
                "        if (!top->eventsPending()) break;",
                "        context->time(top->nextTimeSlot());",
                "    }",
                "    top->final();",
                '    VerilatedCov::write("coverage.dat");',
                "    return context->gotFinish() ? 0 : 1;",
                "}",
                "",
            ]
        ),
        encoding="utf-8",
    )
    command = [
        "verilator",
        "--cc",
        "--exe",
        "--build",
        "--timing",
        "--assert",
        "--coverage-line",
        "--coverage-toggle",
        "--build-jobs",
        str(jobs),
        *WARNING_FLAGS,
        "--Mdir",
        str(mdir),
        "--top-module",
        top,
    ]
    if parameters:
        command.extend(f"-G{key}={value}" for key, value in parameters.items())
    command.extend(f"-D{define}" for define in defines)
    command.extend(
        f"+incdir+{include_dir.resolve()}"
        for include_dir in include_dirs
    )
    if manifest is not None:
        unit_manifest = resolved_unit_manifest(
            manifest,
            build_dir / "resolved_unit.f",
        )
        command.extend(["-f", str(unit_manifest)])
    command.extend(str(source) for source in sources)
    if manifest is not None and "FloatPoint" in manifest.name:
        command.append(str(FP_MODEL_PATH))
    command.append(str(main_path))
    result = run_command(
        command,
        cwd=REPO_ROOT,
        log_path=ARTIFACT_ROOT / "logs" / f"build_{safe_name(name)}.log",
        timeout=600,
    )
    result["binary"] = str(mdir / f"V{top}")
    result["name"] = name
    result["capi_source_root"] = str(CAPI_ROOT)
    result["capi_commit"] = current_capi_commit()
    result.pop("output")
    return result


def run_binary(
    build: dict[str, Any],
    *,
    case_name: str,
    plusargs: Iterable[str] = (),
    timeout: int = 120,
) -> dict[str, Any]:
    run_dir = ARTIFACT_ROOT / "runs" / safe_name(case_name)
    run_dir.mkdir(parents=True, exist_ok=True)
    command = [build["binary"], *(f"+{arg}" for arg in plusargs)]
    result = run_command(
        command,
        cwd=run_dir,
        log_path=ARTIFACT_ROOT / "logs" / f"run_{safe_name(case_name)}.log",
        timeout=timeout,
    )
    result["case"] = case_name
    result["bins"] = sorted(parse_bins(result["output"]))
    result["coordinates"] = sorted(parse_coordinates(result["output"]))
    coverage_data = run_dir / "coverage.dat"
    result["coverage_data"] = (
        str(coverage_data.relative_to(ARTIFACT_ROOT))
        if coverage_data.exists()
        else None
    )
    result["diagnostic"] = (
        None if result["return_code"] == 0 else diagnostic(result["output"])
    )
    result.pop("output")
    return result


def source_contract_key(module: str, contracts: dict[str, list[str]]) -> str:
    if module in contracts:
        return module
    if module.endswith("_arbiter_control"):
        return "*_arbiter_control"
    raise KeyError(f"No source contracts defined for {module}")


def collect_targets(
    scenarios: dict[str, Any],
    matrix: dict[str, Any],
) -> list[dict[str, Any]]:
    families = set(scenarios["families"])
    return [module for module in matrix["modules"] if module["family"] in families]


def verify_source_scope(
    scenarios: dict[str, Any],
    layouts: dict[str, Any],
    targets: list[dict[str, Any]],
) -> tuple[dict[str, Any], list[str]]:
    errors: list[str] = []
    active_manifest_layouts = {
        item["id"]: item for item in layouts["layouts"] if item["status"] == "active"
    }
    expected_layouts = {item["id"]: item for item in scenarios["active_layouts"]}
    if set(active_manifest_layouts) != set(expected_layouts):
        errors.append(
            "active layout mismatch: "
            f"manifest={sorted(active_manifest_layouts)} "
            f"scenarios={sorted(expected_layouts)}"
        )
    for layout_id, expected in expected_layouts.items():
        actual = active_manifest_layouts.get(layout_id, {})
        for key in ("algorithm", "graph_cus", "vertex_cus_per_graph_cu"):
            if actual.get(key) != expected[key]:
                errors.append(
                    f"{layout_id} {key}: expected={expected[key]} actual={actual.get(key)}"
                )

    hashes_by_family: dict[str, set[str]] = defaultdict(set)
    context_executions = 0
    hash_checks: list[dict[str, Any]] = []
    contract_checks: list[dict[str, Any]] = []
    contracts = scenarios["source_contracts"]
    hash_overrides = scenarios.get("production_hash_overrides", {})
    for target in targets:
        path = REPO_ROOT / target["path"]
        actual_hash = sha256(path)
        expected_hash = hash_overrides.get(target["path"], target["sha256"])
        passed_hash = actual_hash == expected_hash
        hash_checks.append(
            {
                "family": target["family"],
                "module": target["module"],
                "path": target["path"],
                "inventory_expected": target["sha256"],
                "expected": expected_hash,
                "actual": actual_hash,
                "passed": passed_hash,
            }
        )
        if not passed_hash:
            errors.append(f"source hash mismatch: {target['path']}")
        hashes_by_family[target["family"]].add(actual_hash)
        context_executions += len(target["contexts"])
        text = path.read_text(encoding="utf-8")
        contract_key = source_contract_key(target["module"], contracts)
        for pattern in contracts[contract_key]:
            passed = re.search(pattern, text, flags=re.MULTILINE | re.DOTALL) is not None
            contract_checks.append(
                {
                    "module": target["module"],
                    "path": target["path"],
                    "pattern": pattern,
                    "passed": passed,
                }
            )
            if not passed:
                errors.append(
                    f"source contract missing: {target['path']} pattern={pattern}"
                )

    for family, expected in scenarios["expected_distinct_hashes"].items():
        actual = hashes_by_family.get(family, set())
        if actual != set(expected):
            errors.append(
                f"{family} hash inventory mismatch: "
                f"expected={sorted(expected)} actual={sorted(actual)}"
            )
    if context_executions != scenarios["expected_context_executions"]:
        errors.append(
            "context execution mismatch: "
            f"expected={scenarios['expected_context_executions']} "
            f"actual={context_executions}"
        )

    report = {
        "active_layouts": sorted(active_manifest_layouts),
        "module_declarations": len(targets),
        "distinct_source_hashes": len(
            {item["actual"] for item in hash_checks}
        ),
        "context_executions": context_executions,
        "hash_checks": hash_checks,
        "contract_checks": contract_checks,
        "hashes_by_family": {
            family: sorted(values) for family, values in hashes_by_family.items()
        },
    }
    return report, errors


def lint_target(
    target: dict[str, Any],
    context: str,
) -> dict[str, Any]:
    case_name = f"{context}__{target['module']}"
    command = [
        "verilator",
        "--lint-only",
        "--timing",
        *WARNING_FLAGS,
        "--Mdir",
        str(ARTIFACT_ROOT / "lint_obj" / safe_name(case_name)),
        "-f",
        str(
            resolved_unit_manifest(
                MANIFEST_DIR / f"{context}.f",
                ARTIFACT_ROOT
                / "lint_manifests"
                / f"{safe_name(case_name)}.f",
            )
        ),
        "--top-module",
        target["module"],
    ]
    if "FloatPoint" in context:
        command.append(str(FP_MODEL_PATH))
    result = run_command(
        command,
        cwd=REPO_ROOT,
        log_path=ARTIFACT_ROOT / "logs" / f"lint_{safe_name(case_name)}.log",
        timeout=300,
    )
    record = {
        "case": case_name,
        "context": context,
        "family": target["family"],
        "module": target["module"],
        "path": target["path"],
        "sha256": target["sha256"],
        "return_code": result["return_code"],
        "log": result["log"],
    }
    if result["return_code"] != 0:
        record["diagnostic"] = diagnostic(result["output"])
        record["missing_modules"] = sorted(
            set(
                re.findall(
                    r"Cannot find file containing module: '([^']+)'",
                    result["output"],
                )
            )
        )
    return record


def run_elaboration(
    targets: list[dict[str, Any]],
    jobs: int,
) -> list[dict[str, Any]]:
    executions = [
        (target, context)
        for target in targets
        for context in target["contexts"]
    ]
    with concurrent.futures.ThreadPoolExecutor(max_workers=jobs) as executor:
        futures = [
            executor.submit(lint_target, target, context)
            for target, context in executions
        ]
        return [future.result() for future in futures]


def filter_define(layout: dict[str, Any]) -> list[str]:
    if layout["filter_mode"] == "bfs":
        return ["FILTER_BFS"]
    if layout["filter_mode"] == "out_degree":
        return ["FILTER_CC"]
    return []


def filter_mode(layout: dict[str, Any]) -> int:
    if layout["filter_mode"] == "bfs":
        return 1
    if layout["filter_mode"] == "out_degree":
        return 2
    return 0


def layout_defines(layout: dict[str, Any]) -> list[str]:
    if layout["algorithm"] == "cu_BFS":
        return ["LAYOUT_BFS"]
    if layout["algorithm"] == "cu_ConnectedComponents":
        return ["LAYOUT_CC"]
    if layout["algorithm"] in ("cu_SPMV", "cu_TriangleCount"):
        return ["LAYOUT_WEIGHTED"]
    return []


def algorithm_arbiter_module(layout: dict[str, Any]) -> str:
    return {
        "cu_BFS": "cu_vertex_bfs_arbiter_control",
        "cu_PageRank": "cu_vertex_pagerank_arbiter_control",
        "cu_SPMV": "cu_vertex_spmv_arbiter_control",
        "cu_ConnectedComponents": "cu_vertex_connectedComponents_arbiter_control",
        "cu_TriangleCount": "cu_vertex_triangleCount_arbiter_control",
    }[layout["algorithm"]]


def run_models(
    scenarios: dict[str, Any],
    jobs: int,
) -> tuple[list[dict[str, Any]], list[str]]:
    results: list[dict[str, Any]] = []
    errors: list[str] = []
    plumbing_builds: dict[tuple[int, int, int], dict[str, Any]] = {}
    scheduler_builds: dict[tuple[int, int], dict[str, Any]] = {}
    expected_plumbing = set(scenarios["functional_bins"]["plumbing"])
    expected_scheduler = set(scenarios["functional_bins"]["scheduler"])

    for layout in scenarios["active_layouts"]:
        plumbing_key = (
            layout["read_bytes"],
            layout["write_bytes"],
            filter_mode(layout),
        )
        if plumbing_key not in plumbing_builds:
            name = "model_plumbing_" + "_".join(map(str, plumbing_key))
            plumbing_builds[plumbing_key] = build_binary(
                name=name,
                top="tb_plumbing_models",
                sources=[SCRIPT_DIR / "tb_plumbing_models.sv"],
                jobs=jobs,
                parameters={
                    "READ_BYTES": plumbing_key[0],
                    "WRITE_BYTES": plumbing_key[1],
                    "FILTER_MODE": plumbing_key[2],
                },
            )
        build = plumbing_builds[plumbing_key]
        if build["return_code"] != 0:
            errors.append(f"plumbing model build failed: {build['name']}")
        else:
            result = run_binary(
                build,
                case_name=f"{layout['id']}__plumbing_model",
            )
            missing = expected_plumbing - set(result["bins"])
            result["expected_bins"] = sorted(expected_plumbing)
            result["missing_bins"] = sorted(missing)
            results.append(result)
            if result["return_code"] != 0 or missing:
                errors.append(f"plumbing model failed: {layout['id']}")

        scheduler_key = (
            layout["graph_cus"],
            layout["vertex_cus_per_graph_cu"],
        )
        if scheduler_key not in scheduler_builds:
            name = "model_scheduler_" + "_".join(map(str, scheduler_key))
            scheduler_builds[scheduler_key] = build_binary(
                name=name,
                top="tb_scheduler_models",
                sources=[SCRIPT_DIR / "tb_scheduler_models.sv"],
                jobs=jobs,
                parameters={
                    "GRAPH_CUS": scheduler_key[0],
                    "VERTEX_CUS": scheduler_key[1],
                },
            )
        build = scheduler_builds[scheduler_key]
        if build["return_code"] != 0:
            errors.append(f"scheduler model build failed: {build['name']}")
        else:
            result = run_binary(
                build,
                case_name=f"{layout['id']}__scheduler_model",
            )
            missing = expected_scheduler - set(result["bins"])
            expected_coordinates = {
                (graph, vertex)
                for graph in range(layout["graph_cus"])
                for vertex in range(layout["vertex_cus_per_graph_cu"])
            }
            observed_coordinates = {
                tuple(item) for item in result["coordinates"]
            }
            result["expected_bins"] = sorted(expected_scheduler)
            result["missing_bins"] = sorted(missing)
            result["expected_coordinates"] = sorted(expected_coordinates)
            result["missing_coordinates"] = sorted(
                expected_coordinates - observed_coordinates
            )
            results.append(result)
            if (
                result["return_code"] != 0
                or missing
                or result["missing_coordinates"]
            ):
                errors.append(f"scheduler model failed: {layout['id']}")
    return results, errors


def run_mutations(
    scenarios: dict[str, Any],
    jobs: int,
) -> tuple[list[dict[str, Any]], list[str]]:
    results: list[dict[str, Any]] = []
    errors: list[str] = []
    for mutation in scenarios["mutations"]:
        plumbing = mutation["testbench"] == "plumbing"
        top = "tb_plumbing_models" if plumbing else "tb_scheduler_models"
        source = (
            SCRIPT_DIR / "tb_plumbing_models.sv"
            if plumbing
            else SCRIPT_DIR / "tb_scheduler_models.sv"
        )
        parameters = (
            {"READ_BYTES": 4, "WRITE_BYTES": 4, "FILTER_MODE": 1}
            if plumbing
            else {"GRAPH_CUS": 4, "VERTEX_CUS": 4}
        )
        build = build_binary(
            name=f"mutation_{mutation['id']}",
            top=top,
            sources=[source],
            jobs=jobs,
            parameters=parameters,
            defines=[mutation["define"]],
        )
        record: dict[str, Any] = {
            "id": mutation["id"],
            "define": mutation["define"],
            "build": build,
            "killed": False,
        }
        if build["return_code"] == 0:
            run = run_binary(build, case_name=f"mutation_{mutation['id']}")
            record["run"] = run
            record["killed"] = run["return_code"] != 0
        if not record["killed"]:
            errors.append(f"mutation survived: {mutation['id']}")
        results.append(record)
    return results, errors


def run_filter_duts(
    scenarios: dict[str, Any],
    jobs: int,
) -> tuple[list[dict[str, Any]], list[str]]:
    results: list[dict[str, Any]] = []
    errors: list[str] = []
    expected = {
        "filter_reset_disabled_idle",
        "filter_isolated_reject",
        "filter_active_accept",
        "filter_payload_toggle",
        "filter_queue_near_full",
        "filter_deterministic_drain",
    }
    for layout in scenarios["active_layouts"]:
        build = build_binary(
            name=f"{layout['id']}__filter_dut",
            top="tb_vertex_filter_dut",
            sources=[SCRIPT_DIR / "tb_vertex_filter_dut.sv"],
            jobs=jobs,
            defines=filter_define(layout),
            manifest=MANIFEST_DIR / f"{layout['id']}.f",
        )
        if build["return_code"] != 0:
            errors.append(f"filter DUT build failed: {layout['id']}")
            results.append({"layout": layout["id"], "build": build})
            continue
        run = run_binary(build, case_name=f"{layout['id']}__filter_dut")
        run["layout"] = layout["id"]
        run["expected_bins"] = sorted(expected)
        run["missing_bins"] = sorted(expected - set(run["bins"]))
        results.append({"layout": layout["id"], "build": build, "run": run})
        if run["return_code"] != 0 or run["missing_bins"]:
            errors.append(f"filter DUT failed: {layout['id']}")
    return results, errors


def run_extract_duts(
    scenarios: dict[str, Any],
    jobs: int,
) -> tuple[list[dict[str, Any]], list[dict[str, Any]], list[str]]:
    results: list[dict[str, Any]] = []
    blockers: list[dict[str, Any]] = []
    errors: list[str] = []
    expected = set(scenarios["dut_bins"]["edge_extract"]["baseline"])
    expected_pulse = set(scenarios["dut_bins"]["edge_extract"]["pulse_upper"])
    expected_reorder = set(scenarios["dut_bins"]["edge_extract"]["tag_reorder"])
    for layout in scenarios["active_layouts"]:
        build = build_binary(
            name=f"{layout['id']}__extract_dut",
            top="tb_edge_extract_dut",
            sources=[SCRIPT_DIR / "tb_edge_extract_dut.sv"],
            jobs=jobs,
            manifest=MANIFEST_DIR / f"{layout['id']}.f",
        )
        record: dict[str, Any] = {"layout": layout["id"], "build": build}
        if build["return_code"] != 0:
            errors.append(f"extract DUT build failed: {layout['id']}")
            results.append(record)
            continue
        baseline = run_binary(
            build,
            case_name=f"{layout['id']}__extract_dut_baseline",
        )
        baseline["expected_bins"] = sorted(expected)
        baseline["missing_bins"] = sorted(expected - set(baseline["bins"]))
        record["baseline"] = baseline
        if baseline["return_code"] != 0 or baseline["missing_bins"]:
            errors.append(f"extract DUT baseline failed: {layout['id']}")

        pulse = run_binary(
            build,
            case_name=f"{layout['id']}__extract_dut_pulse_upper",
            plusargs=["PULSE_UPPER"],
        )
        pulse["expected_bins"] = sorted(expected | expected_pulse)
        pulse["missing_bins"] = sorted(
            (expected | expected_pulse) - set(pulse["bins"])
        )
        record["pulse_upper"] = pulse
        if pulse["return_code"] != 0 or pulse["missing_bins"]:
            errors.append(f"extract one-cycle upper failed: {layout['id']}")

        reorder = run_binary(
            build,
            case_name=f"{layout['id']}__extract_dut_reorder",
            plusargs=["REORDER"],
        )
        reorder["expected_bins"] = sorted(expected | expected_reorder)
        reorder["missing_bins"] = sorted(
            (expected | expected_reorder) - set(reorder["bins"])
        )
        record["reorder"] = reorder
        if reorder["return_code"] != 0 or reorder["missing_bins"]:
            errors.append(f"extract tag reorder failed: {layout['id']}")
        results.append(record)
    return results, blockers, errors


def run_queue_controller_duts(
    scenarios: dict[str, Any],
    jobs: int,
) -> tuple[dict[str, list[dict[str, Any]]], list[str]]:
    results: dict[str, list[dict[str, Any]]] = {
        "vertex_job_control": [],
        "edge_job_control": [],
        "edge_read_command_control": [],
        "edge_write_command_control": [],
    }
    errors: list[str] = []
    for layout in scenarios["active_layouts"]:
        manifest = MANIFEST_DIR / f"{layout['id']}.f"
        defines = layout_defines(layout)
        cases = [
            (
                "vertex_job_control",
                "tb_vertex_job_control_dut",
                SCRIPT_DIR / "tb_vertex_job_control_dut.sv",
                set(scenarios["dut_bins"]["vertex_job"]),
            ),
            (
                "edge_job_control",
                "tb_edge_job_control_dut",
                SCRIPT_DIR / "tb_edge_job_control_dut.sv",
                set(scenarios["dut_bins"]["edge_job"]),
            ),
            (
                "edge_read_command_control",
                "tb_edge_read_command_dut",
                SCRIPT_DIR / "tb_edge_read_command_dut.sv",
                set(scenarios["dut_bins"]["edge_read_command"])
                | (
                    set(scenarios["dut_bins"]["edge_read_components"])
                    if layout["algorithm"] == "cu_ConnectedComponents"
                    else set(scenarios["dut_bins"]["edge_read_data_queue"])
                ),
            ),
        ]
        if layout["algorithm"] == "cu_BFS":
            cases.append(
                (
                    "edge_write_command_control",
                    "tb_edge_write_bfs_dut",
                    SCRIPT_DIR / "tb_edge_write_bfs_dut.sv",
                    set(scenarios["dut_bins"]["edge_write_bfs"]),
                )
            )
        else:
            cases.append(
                (
                    "edge_write_command_control",
                    "tb_edge_write_common_dut",
                    SCRIPT_DIR / "tb_edge_write_common_dut.sv",
                    set(scenarios["dut_bins"]["edge_write_common"]),
                )
            )
        for family_case, top, source, expected in cases:
            name = f"{layout['id']}__{family_case}_dut"
            build = build_binary(
                name=name,
                top=top,
                sources=[source],
                jobs=jobs,
                defines=defines,
                manifest=manifest,
            )
            record: dict[str, Any] = {
                "context": layout["id"],
                "build": build,
                "expected_bins": sorted(expected),
            }
            if build["return_code"] != 0:
                errors.append(f"{family_case} DUT build failed: {layout['id']}")
                results[family_case].append(record)
                continue
            run = run_binary(build, case_name=name)
            run["missing_bins"] = sorted(expected - set(run["bins"]))
            record["run"] = run
            if run["return_code"] != 0 or run["missing_bins"]:
                errors.append(f"{family_case} DUT failed: {layout['id']}")
            results[family_case].append(record)
    return results, errors


def run_scheduler_family_duts(
    scenarios: dict[str, Any],
    jobs: int,
) -> tuple[dict[str, list[dict[str, Any]]], list[dict[str, Any]], list[str]]:
    results: dict[str, list[dict[str, Any]]] = {
        "algorithm_arbiters": [],
        "cluster_arbiters": [],
        "cluster_midflight_reset": [],
        "cc_cu_control_midflight_reset": [],
        "cluster_controls": [],
        "graph_algorithm_arbiters": [],
        "graph_algorithm_controls": [],
    }
    blockers: list[dict[str, Any]] = []
    errors: list[str] = []

    def run_arbiter_case(
        *,
        category: str,
        layout: dict[str, Any],
        top: str,
        source: Path,
        defines: list[str],
        parameters: dict[str, int],
        expected: set[str],
        case_suffix: str = "",
    ) -> None:
        name = f"{layout['id']}__{category}{case_suffix}_dut"
        build = build_binary(
            name=name,
            top=top,
            sources=[source],
            jobs=jobs,
            defines=defines,
            parameters=parameters,
            manifest=MANIFEST_DIR / f"{layout['id']}.f",
        )
        record: dict[str, Any] = {
            "context": layout["id"],
            "build": build,
            "expected_bins": sorted(expected),
        }
        if build["return_code"] != 0:
            errors.append(f"{category} DUT build failed: {layout['id']}")
            results[category].append(record)
            return
        run = run_binary(build, case_name=name)
        run["missing_bins"] = sorted(expected - set(run["bins"]))
        if top == "tb_algorithm_arbiter_dut":
            expected_coordinates = {
                (parameters["GRAPH_Y"], vertex)
                for vertex in range(parameters["NUM_CUS"])
            }
            observed_coordinates = {
                tuple(item) for item in run["coordinates"]
            }
            run["expected_coordinates"] = sorted(expected_coordinates)
            run["missing_coordinates"] = sorted(
                expected_coordinates - observed_coordinates
            )
        else:
            run["missing_coordinates"] = []
        record["run"] = run
        if run["return_code"] != 0:
            if "payload owner=" in (run["diagnostic"] or ""):
                blockers.append(
                    {
                        "id": "arbiter_payload_grant_coupling",
                        "context": layout["id"],
                        "module": defines[0].split("=", 1)[1],
                        "diagnostic": run["diagnostic"],
                        "log": run["log"],
                    }
                )
            else:
                errors.append(f"{category} DUT failed: {layout['id']}")
        elif run["missing_bins"] or run["missing_coordinates"]:
            errors.append(f"{category} DUT bins missing: {layout['id']}")
        results[category].append(record)

    for layout in scenarios["active_layouts"]:
        for graph_y in range(layout["graph_cus"]):
            run_arbiter_case(
                category="algorithm_arbiters",
                layout=layout,
                top="tb_algorithm_arbiter_dut",
                source=SCRIPT_DIR / "tb_algorithm_arbiter_dut.sv",
                defines=[
                    f"DUT_MODULE={algorithm_arbiter_module(layout)}"
                ],
                parameters={
                    "NUM_CUS": layout["vertex_cus_per_graph_cu"],
                    "GRAPH_CUS": layout["graph_cus"],
                    "GRAPH_Y": graph_y,
                },
                expected=set(
                    scenarios["dut_bins"]["algorithm_arbiter"]
                ),
                case_suffix=f"_y{graph_y}",
            )

        if layout["algorithm"] != "cu_PageRank":
            run_arbiter_case(
                category="cluster_arbiters",
                layout=layout,
                top="tb_cluster_arbiter_dut",
                source=SCRIPT_DIR / "tb_cluster_arbiter_dut.sv",
                defines=[
                    "DUT_MODULE=cu_vertex_cluster_arbiter_control",
                    "HELD_OWNER_PROTOCOL",
                ],
                parameters={
                    "GRAPH_CUS": layout["graph_cus"],
                    "VERTEX_CUS": layout["vertex_cus_per_graph_cu"],
                },
                expected=set(scenarios["dut_bins"]["cluster_arbiter"]),
            )
            reset_name = (
                f"{layout['id']}__cluster_midflight_reset_dut"
            )
            reset_build = build_binary(
                name=reset_name,
                top="tb_cluster_midflight_reset_dut",
                sources=[SCRIPT_DIR / "tb_cluster_midflight_reset_dut.sv"],
                jobs=jobs,
                parameters={
                    "GRAPH_CUS": layout["graph_cus"],
                    "VERTEX_CUS": layout["vertex_cus_per_graph_cu"],
                },
                manifest=MANIFEST_DIR / f"{layout['id']}.f",
            )
            reset_expected = set(
                scenarios["dut_bins"]["cluster_midflight_reset"]
            )
            reset_record: dict[str, Any] = {
                "context": layout["id"],
                "build": reset_build,
                "expected_bins": sorted(reset_expected),
            }
            if reset_build["return_code"] != 0:
                errors.append(
                    f"cluster midflight reset DUT build failed: {layout['id']}"
                )
            else:
                reset_run = run_binary(reset_build, case_name=reset_name)
                reset_run["missing_bins"] = sorted(
                    reset_expected - set(reset_run["bins"])
                )
                reset_record["run"] = reset_run
                if (
                    reset_run["return_code"] != 0
                    or reset_run["missing_bins"]
                ):
                    errors.append(
                        f"cluster midflight reset DUT failed: {layout['id']}"
                    )
            results["cluster_midflight_reset"].append(reset_record)
            control_category = "cluster_controls"
            control_module = "cu_vertex_cluster_control"
        else:
            run_arbiter_case(
                category="graph_algorithm_arbiters",
                layout=layout,
                top="tb_cluster_arbiter_dut",
                source=SCRIPT_DIR / "tb_cluster_arbiter_dut.sv",
                defines=["DUT_MODULE=cu_graph_algorithm_arbiter_control"],
                parameters={
                    "GRAPH_CUS": layout["graph_cus"],
                    "VERTEX_CUS": layout["vertex_cus_per_graph_cu"],
                },
                expected=set(scenarios["dut_bins"]["cluster_arbiter"]),
            )
            control_category = "graph_algorithm_controls"
            control_module = "cu_graph_algorithm_control"

        name = f"{layout['id']}__{control_category}_dut"
        build = build_binary(
            name=name,
            top="tb_scheduler_control_dut",
            sources=[SCRIPT_DIR / "tb_scheduler_control_dut.sv"],
            jobs=jobs,
            defines=[f"DUT_MODULE={control_module}"],
            parameters={
                "VERTEX_CUS": layout["vertex_cus_per_graph_cu"],
                "GRAPH_CUS": layout["graph_cus"],
                "GRAPH_Y": 0,
            },
            manifest=MANIFEST_DIR / f"{layout['id']}.f",
        )
        expected_control = set(scenarios["dut_bins"]["scheduler_control"])
        record = {
            "context": layout["id"],
            "build": build,
            "expected_bins": sorted(expected_control),
        }
        if build["return_code"] != 0:
            errors.append(
                f"{control_category} DUT build failed: {layout['id']}"
            )
        else:
            run = run_binary(build, case_name=name)
            run["missing_bins"] = sorted(
                expected_control - set(run["bins"])
            )
            record["run"] = run
            if run["return_code"] != 0 or run["missing_bins"]:
                errors.append(f"{control_category} DUT failed: {layout['id']}")
        results[control_category].append(record)

    cc_layout = next(
        layout
        for layout in scenarios["active_layouts"]
        if layout["algorithm"] == "cu_ConnectedComponents"
    )
    cc_name = (
        f"{cc_layout['id']}__cc_cu_control_midflight_reset_dut"
    )
    cc_build = build_binary(
        name=cc_name,
        top="graph_integration_tb",
        sources=[
            REPO_ROOT
            / "03_capi_integration"
            / "accelerator_verification"
            / "rtl"
            / "unit"
            / "algorithms"
            / "tb"
            / "graph_fixture_pkg.sv",
            REPO_ROOT
            / "03_capi_integration"
            / "accelerator_verification"
            / "rtl"
            / "integration"
            / "tb"
            / "graph_integration_tb.sv",
            SCRIPT_DIR / "tb_cc_cu_control_midflight_reset_dut.sv",
        ],
        jobs=jobs,
        defines=["INTEG_TRACE_CC"],
        manifest=MANIFEST_DIR / f"{cc_layout['id']}.f",
        include_dirs=[
            REPO_ROOT
            / "03_capi_integration"
            / "accelerator_verification"
            / "rtl"
            / "integration"
            / "models",
        ],
    )
    cc_expected = set(
        scenarios["dut_bins"]["cc_cu_control_midflight_reset"]
    )
    cc_record: dict[str, Any] = {
        "context": cc_layout["id"],
        "build": cc_build,
        "expected_bins": sorted(cc_expected),
    }
    if cc_build["return_code"] != 0:
        errors.append("CC cu_control midflight reset DUT build failed")
    else:
        cc_run = run_binary(
            cc_build,
            case_name=cc_name,
            plusargs=["TRACE"],
            timeout=900,
        )
        cc_run["missing_bins"] = sorted(
            cc_expected - set(cc_run["bins"])
        )
        cc_record["run"] = cc_run
        if cc_run["return_code"] != 0 or cc_run["missing_bins"]:
            errors.append("CC cu_control midflight reset DUT failed")
    results["cc_cu_control_midflight_reset"].append(cc_record)

    return results, blockers, errors


def run_arbiter_duts(
    scenarios: dict[str, Any],
    jobs: int,
) -> tuple[list[dict[str, Any]], list[dict[str, Any]], list[str]]:
    results: list[dict[str, Any]] = []
    blockers: list[dict[str, Any]] = []
    errors: list[str] = []
    representatives: dict[int, str] = {}
    for layout in scenarios["active_layouts"]:
        representatives.setdefault(layout["graph_cus"], layout["id"])
    for requests, context in sorted(representatives.items()):
        build = build_binary(
            name=f"arbiter_primitive_{requests}",
            top="tb_arbiter_primitive_dut",
            sources=[SCRIPT_DIR / "tb_arbiter_primitive_dut.sv"],
            jobs=jobs,
            parameters={"REQUESTS": requests},
            manifest=MANIFEST_DIR / f"{context}.f",
        )
        record: dict[str, Any] = {
            "requests": requests,
            "representative_context": context,
            "build": build,
        }
        if build["return_code"] != 0:
            errors.append(f"arbiter DUT build failed: requests={requests}")
            results.append(record)
            continue
        run = run_binary(build, case_name=f"arbiter_primitive_{requests}")
        record["run"] = run
        if run["return_code"] != 0:
            blockers.append(
                {
                    "id": "arbiter_payload_grant_coupling",
                    "topology": {"requesters": requests},
                    "module": "round_robin_priority_arbiter_N_input_1_ouput",
                    "diagnostic": run["diagnostic"],
                    "log": run["log"],
                }
            )
        results.append(record)
    return results, blockers, errors


def run_reduction_duts(
    scenarios: dict[str, Any],
    jobs: int,
) -> tuple[list[dict[str, Any]], list[str]]:
    results: list[dict[str, Any]] = []
    errors: list[str] = []
    widths = sorted({layout["graph_cus"] for layout in scenarios["active_layouts"]})
    for width in widths:
        build = build_binary(
            name=f"sum_reduce_{width}",
            top="tb_sum_reduce_dut",
            sources=[SUM_REDUCE_PATH, SCRIPT_DIR / "tb_sum_reduce_dut.sv"],
            jobs=jobs,
            parameters={"BUS_WIDTH": width, "DATA_WIDTH": 32},
        )
        record: dict[str, Any] = {"bus_width": width, "build": build}
        if build["return_code"] != 0:
            errors.append(f"reduction DUT build failed: width={width}")
        else:
            run = run_binary(build, case_name=f"sum_reduce_{width}")
            record["run"] = run
            if run["return_code"] != 0:
                errors.append(f"reduction DUT failed: width={width}")
        results.append(record)
    return results, errors


def collect_assertion_sites() -> list[dict[str, Any]]:
    sites: list[dict[str, Any]] = []
    for path in sorted(SCRIPT_DIR.glob("tb_*.sv")):
        for line_number, line in enumerate(
            path.read_text(encoding="utf-8").splitlines(), start=1
        ):
            if "$fatal" in line:
                sites.append(
                    {
                        "file": path.name,
                        "line": line_number,
                        "code": line.strip(),
                    }
                )
    return sites


def collect_code_coverage(results: Any) -> list[dict[str, Any]]:
    coverage_paths: set[str] = set()

    def visit(value: Any) -> None:
        if isinstance(value, dict):
            coverage_data = value.get("coverage_data")
            if coverage_data:
                coverage_paths.add(coverage_data)
            for nested in value.values():
                visit(nested)
        elif isinstance(value, list):
            for nested in value:
                visit(nested)

    visit(results)
    records: list[dict[str, Any]] = []
    tool = shutil.which("verilator_coverage")
    for relative in sorted(coverage_paths):
        data_path = ARTIFACT_ROOT / relative
        info_path = data_path.with_suffix(".info")
        record: dict[str, Any] = {"coverage_data": relative}
        if tool is None:
            record["status"] = "verilator_coverage unavailable"
            records.append(record)
            continue
        command = [tool, "--write-info", str(info_path), str(data_path)]
        process = subprocess.run(
            command,
            cwd=REPO_ROOT,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            check=False,
        )
        if process.returncode != 0 or not info_path.exists():
            record["status"] = "conversion failed"
            record["diagnostic"] = diagnostic(process.stdout)
            records.append(record)
            continue
        lines_found = 0
        lines_hit = 0
        branches_found = 0
        branches_hit = 0
        for line in info_path.read_text(encoding="utf-8").splitlines():
            if line.startswith("DA:"):
                lines_found += 1
                if int(line.rsplit(",", 1)[1]) > 0:
                    lines_hit += 1
            elif line.startswith("BRDA:"):
                branches_found += 1
                if line.rsplit(",", 1)[1] not in ("0", "-"):
                    branches_hit += 1
        record.update(
            {
                "status": "collected",
                "info": str(info_path.relative_to(ARTIFACT_ROOT)),
                "lines_found": lines_found,
                "lines_hit": lines_hit,
                "line_percent": (
                    round(100.0 * lines_hit / lines_found, 2)
                    if lines_found
                    else 100.0
                ),
                "branches_found": branches_found,
                "branches_hit": branches_hit,
                "branch_percent": (
                    round(100.0 * branches_hit / branches_found, 2)
                    if branches_found
                    else 100.0
                ),
            }
        )
        records.append(record)
    if tool is not None and coverage_paths:
        merged_data = ARTIFACT_ROOT / "coverage_merged.dat"
        merged_info = ARTIFACT_ROOT / "coverage_merged.info"
        merge = subprocess.run(
            [
                tool,
                "--write",
                str(merged_data),
                *(str(ARTIFACT_ROOT / path) for path in sorted(coverage_paths)),
            ],
            cwd=REPO_ROOT,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            check=False,
        )
        convert = subprocess.run(
            [tool, "--write-info", str(merged_info), str(merged_data)],
            cwd=REPO_ROOT,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            check=False,
        )
        if (
            merge.returncode == 0
            and convert.returncode == 0
            and merged_info.exists()
        ):
            lines_found = 0
            lines_hit = 0
            branches_found = 0
            branches_hit = 0
            for line in merged_info.read_text(encoding="utf-8").splitlines():
                if line.startswith("DA:"):
                    lines_found += 1
                    if int(line.rsplit(",", 1)[1]) > 0:
                        lines_hit += 1
                elif line.startswith("BRDA:"):
                    branches_found += 1
                    if line.rsplit(",", 1)[1] not in ("0", "-"):
                        branches_hit += 1
            records.append(
                {
                    "aggregate": True,
                    "aggregate_scope": "all_passing_runs",
                    "coverage_data": str(
                        merged_data.relative_to(ARTIFACT_ROOT)
                    ),
                    "info": str(merged_info.relative_to(ARTIFACT_ROOT)),
                    "status": "collected",
                    "lines_found": lines_found,
                    "lines_hit": lines_hit,
                    "line_percent": (
                        round(100.0 * lines_hit / lines_found, 2)
                        if lines_found
                        else 100.0
                    ),
                    "branches_found": branches_found,
                    "branches_hit": branches_hit,
                    "branch_percent": (
                        round(100.0 * branches_hit / branches_found, 2)
                        if branches_found
                        else 100.0
                    ),
                }
            )
        model_paths = sorted(
            path
            for path in coverage_paths
            if "__plumbing_model/" in path or "__scheduler_model/" in path
        )
        if model_paths:
            model_data = ARTIFACT_ROOT / "coverage_models_merged.dat"
            model_info = ARTIFACT_ROOT / "coverage_models_merged.info"
            model_merge = subprocess.run(
                [
                    tool,
                    "--write",
                    str(model_data),
                    *(str(ARTIFACT_ROOT / path) for path in model_paths),
                ],
                cwd=REPO_ROOT,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
                check=False,
            )
            model_convert = subprocess.run(
                [tool, "--write-info", str(model_info), str(model_data)],
                cwd=REPO_ROOT,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
                check=False,
            )
            if (
                model_merge.returncode == 0
                and model_convert.returncode == 0
                and model_info.exists()
            ):
                model_lines_found = 0
                model_lines_hit = 0
                for line in model_info.read_text(encoding="utf-8").splitlines():
                    if line.startswith("DA:"):
                        model_lines_found += 1
                        if int(line.rsplit(",", 1)[1]) > 0:
                            model_lines_hit += 1
                records.append(
                    {
                        "aggregate": True,
                        "aggregate_scope": "independent_models",
                        "coverage_data": str(
                            model_data.relative_to(ARTIFACT_ROOT)
                        ),
                        "info": str(model_info.relative_to(ARTIFACT_ROOT)),
                        "status": "collected",
                        "lines_found": model_lines_found,
                        "lines_hit": model_lines_hit,
                        "line_percent": (
                            round(
                                100.0
                                * model_lines_hit
                                / model_lines_found,
                                2,
                            )
                            if model_lines_found
                            else 100.0
                        ),
                    }
                )
    return records


def parse_raw_coverage(path: Path) -> list[dict[str, Any]]:
    records: list[dict[str, Any]] = []
    if not path.exists():
        return records
    for line in path.read_text(encoding="latin1").splitlines():
        if not line.startswith("C '"):
            continue
        payload, count_text = line[3:].rsplit("' ", 1)
        fields: dict[str, str] = {}
        for item in payload.split("\x01"):
            if "\x02" not in item:
                continue
            key, value = item.split("\x02", 1)
            fields[key] = value
        page = fields.get("page", "")
        coverage_type = page.split("/", 1)[0]
        if coverage_type not in ("v_line", "v_branch", "v_toggle"):
            continue
        file_name = fields.get("f", "")
        try:
            relative_file = str(
                Path(file_name).resolve().relative_to(REPO_ROOT)
            )
        except ValueError:
            relative_file = file_name
        records.append(
            {
                "file": relative_file,
                "line": int(fields.get("l", "0")),
                "column": fields.get("n", ""),
                "type": coverage_type.removeprefix("v_"),
                "objective": fields.get("o", ""),
                "source": fields.get("S", ""),
                "hierarchy": fields.get("h", ""),
                "count": int(count_text),
            }
        )
    return records


def coverage_point_key(record: dict[str, Any]) -> tuple[Any, ...]:
    return (
        record["file"],
        record["type"],
        record["line"],
        record["column"],
        record["objective"],
        record["source"],
    )


def merge_target_coverage(
    paths: list[Path],
    target_path: str,
    target_paths: set[str],
    cache: dict[Path, dict[str, list[dict[str, Any]]]],
) -> tuple[list[dict[str, Any]], list[str]]:
    merged: dict[tuple[Any, ...], dict[str, Any]] = {}
    used: list[str] = []
    for path in paths:
        if path not in cache:
            grouped: dict[str, list[dict[str, Any]]] = defaultdict(list)
            for record in parse_raw_coverage(path):
                if record["file"] in target_paths:
                    grouped[record["file"]].append(record)
            cache[path] = dict(grouped)
        path_records = cache[path].get(target_path, [])
        if not path_records:
            continue
        used.append(str(path.relative_to(REPO_ROOT)))
        for record in path_records:
            key = coverage_point_key(record)
            if key not in merged:
                merged[key] = {**record, "count": 0, "hierarchies": []}
            merged[key]["count"] += record["count"]
            if record["hierarchy"] not in merged[key]["hierarchies"]:
                merged[key]["hierarchies"].append(record["hierarchy"])
    return list(merged.values()), used


def integration_coverage_paths(
    context: str,
    target_path: str,
) -> tuple[list[Path], list[dict[str, Any]]]:
    accepted: list[Path] = []
    identity: list[dict[str, Any]] = []
    target = REPO_ROOT / target_path
    roots = (
        (
            "algorithm-shell",
            REPO_ROOT / "02_capi_graph" / "obj" / "rtl_algorithms"
            / "algorithm-shells",
        ),
        (
            "graph-top",
            REPO_ROOT / "02_capi_graph" / "obj" / "rtl_graph_integration"
            / "graph-top",
        ),
    )
    for kind, root in roots:
        run_dir = root / context
        coverage_path = run_dir / "coverage.dat"
        summary_path = run_dir / "summary.json"
        record: dict[str, Any] = {
            "kind": kind,
            "context": context,
            "coverage_data": str(coverage_path.relative_to(REPO_ROOT)),
            "target": target_path,
            "target_sha256": sha256(target),
            "accepted": False,
        }
        if not coverage_path.exists() or not summary_path.exists():
            record["reason"] = "coverage or summary artifact absent"
            identity.append(record)
            continue
        summary = load_json(summary_path)
        if summary.get("layout") != context:
            record["reason"] = "layout identity mismatch"
            identity.append(record)
            continue
        summary_dut = REPO_ROOT / summary["dut"]
        current_top_hash = sha256(summary_dut)
        record["summary_dut"] = summary["dut"]
        record["summary_dut_sha256"] = summary.get("dut_sha256")
        record["current_dut_sha256"] = current_top_hash
        if current_top_hash != summary.get("dut_sha256"):
            record["reason"] = "top-level DUT hash is stale"
            identity.append(record)
            continue
        if target.stat().st_mtime_ns > coverage_path.stat().st_mtime_ns:
            record["reason"] = "target source is newer than coverage artifact"
            identity.append(record)
            continue
        record["accepted"] = True
        record["reason"] = (
            "exact layout, current top-level hash, and target source freshness"
        )
        accepted.append(coverage_path)
        identity.append(record)
    return accepted, identity


def coverage_rule_matches(
    rule: dict[str, Any],
    execution: dict[str, Any],
    record: dict[str, Any],
) -> bool:
    if rule.get("family") not in (None, execution["family"]):
        return False
    if rule.get("module") not in (None, execution["module"]):
        return False
    if rule.get("type") not in (None, record["type"]):
        return False
    match = rule.get("match", {})
    fields = {
        "path": record["file"],
        "objective": record["objective"],
        "source": record["source"],
        "line": str(record["line"]),
        "column": record["column"],
    }
    return all(
        re.search(pattern, fields[field]) is not None
        for field, pattern in match.items()
    )


def apply_reachable_coverage(
    scenarios: dict[str, Any],
    targets: list[dict[str, Any]],
    reports: dict[str, Any],
    contract: dict[str, Any],
) -> tuple[list[str], list[dict[str, Any]]]:
    errors: list[str] = []
    identities: list[dict[str, Any]] = []
    observed_denominators: dict[str, dict[str, int]] = {}
    rule_hits: dict[str, int] = {
        rule["id"]: 0 for rule in contract.get("rules", [])
    }
    target_paths = {target["path"] for target in targets}
    coverage_cache: dict[
        Path, dict[str, list[dict[str, Any]]]
    ] = {}
    executions_by_family: dict[str, list[dict[str, Any]]] = defaultdict(list)

    for target in targets:
        actual_hash = sha256(REPO_ROOT / target["path"])
        for context in target["contexts"]:
            label = (
                f"{context}/{target['module']}/{actual_hash}"
            )
            unit_paths = sorted(
                (ARTIFACT_ROOT / "runs").glob(
                    f"{safe_name(context)}__*/coverage.dat"
                )
            )
            integration_paths, identity = integration_coverage_paths(
                context,
                target["path"],
            )
            identities.extend(identity)
            records, evidence = merge_target_coverage(
                unit_paths + integration_paths,
                target["path"],
                target_paths,
                coverage_cache,
            )
            execution = {
                "label": label,
                "family": target["family"],
                "module": target["module"],
                "path": target["path"],
                "context": context,
                "sha256": actual_hash,
                "evidence": evidence,
            }
            denominators = {
                coverage_type: sum(
                    record["type"] == coverage_type for record in records
                )
                for coverage_type in ("line", "branch", "toggle")
            }
            observed_denominators[label] = denominators
            pinned = contract.get("denominators", {}).get(label)
            hash_pinned = "denominator_sha256" in contract
            denominator_matches = hash_pinned or pinned == denominators
            if not hash_pinned:
                if pinned is None:
                    errors.append(
                        f"{label} has no pinned raw coverage denominator"
                    )
                elif not denominator_matches:
                    errors.append(
                        f"{label} raw coverage denominator changed: "
                        f"pinned={pinned} observed={denominators}"
                    )

            structural: list[dict[str, Any]] = []
            unmatched: list[dict[str, Any]] = []
            ambiguous: list[dict[str, Any]] = []
            zeros = [record for record in records if record["count"] == 0]
            for record in zeros:
                matches = [
                    rule
                    for rule in contract.get("rules", [])
                    if coverage_rule_matches(rule, execution, record)
                ]
                if len(matches) == 1:
                    rule = matches[0]
                    rule_hits[rule["id"]] += 1
                    structural.append(
                        {
                            **record,
                            "rule": rule["id"],
                            "category": rule["category"],
                            "reason": rule["reason"],
                        }
                    )
                elif not matches:
                    unmatched.append(record)
                else:
                    ambiguous.append(
                        {
                            **record,
                            "matching_rules": [
                                rule["id"] for rule in matches
                            ],
                        }
                    )
            if unmatched:
                errors.append(
                    f"{label} has {len(unmatched)} unclassified zero points"
                )
            if ambiguous:
                errors.append(
                    f"{label} has {len(ambiguous)} ambiguously classified zero points"
                )

            metrics: dict[str, Any] = {}
            for coverage_type in ("line", "branch", "toggle"):
                type_records = [
                    record
                    for record in records
                    if record["type"] == coverage_type
                ]
                type_structural = [
                    record
                    for record in structural
                    if record["type"] == coverage_type
                ]
                hit = sum(record["count"] > 0 for record in type_records)
                reachable_total = len(type_records) - len(type_structural)
                metrics[coverage_type] = {
                    "raw_hit": hit,
                    "raw_total": len(type_records),
                    "structurally_unreachable": len(type_structural),
                    "reachable_hit": hit,
                    "reachable_total": reachable_total,
                    "reachable_percent": (
                        round(100.0 * hit / reachable_total, 2)
                        if reachable_total
                        else 100.0
                    ),
                }
            execution.update(
                {
                    "status": (
                        "closed"
                        if records
                        and denominator_matches
                        and not unmatched
                        and not ambiguous
                        else "blocked"
                    ),
                    "code_coverage": metrics,
                    "structurally_unreachable": structural,
                    "unmatched_zero_records": unmatched,
                    "ambiguous_zero_records": ambiguous,
                }
            )
            executions_by_family[target["family"]].append(execution)

    if "denominator_sha256" in contract:
        denominator_payload = json.dumps(
            observed_denominators,
            sort_keys=True,
            separators=(",", ":"),
        ).encode()
        observed_hash = hashlib.sha256(denominator_payload).hexdigest()
        if len(observed_denominators) != contract.get(
            "denominator_execution_count"
        ):
            errors.append(
                "raw coverage denominator execution count changed: "
                f"pinned={contract.get('denominator_execution_count')} "
                f"observed={len(observed_denominators)}"
            )
        if observed_hash != contract["denominator_sha256"]:
            errors.append(
                "raw coverage denominator table changed: "
                f"pinned={contract['denominator_sha256']} "
                f"observed={observed_hash}"
            )
    else:
        expected_labels = set(observed_denominators)
        pinned_labels = set(contract.get("denominators", {}))
        if expected_labels != pinned_labels:
            errors.append(
                "coverage denominator labels mismatch: "
                f"missing={sorted(expected_labels - pinned_labels)} "
                f"stale={sorted(pinned_labels - expected_labels)}"
            )
    for rule_id, count in rule_hits.items():
        if count == 0:
            errors.append(
                f"structural coverage rule {rule_id} is stale or unmatched"
            )

    for family in scenarios["families"]:
        executions = executions_by_family[family]
        behavioral = reports[family]["behavioral"]
        metrics: dict[str, Any] = {}
        structural: list[dict[str, Any]] = []
        unmatched: list[dict[str, Any]] = []
        for coverage_type in ("line", "branch", "toggle"):
            raw_hit = sum(
                item["code_coverage"][coverage_type]["raw_hit"]
                for item in executions
            )
            raw_total = sum(
                item["code_coverage"][coverage_type]["raw_total"]
                for item in executions
            )
            unreachable = sum(
                item["code_coverage"][coverage_type][
                    "structurally_unreachable"
                ]
                for item in executions
            )
            reachable_total = raw_total - unreachable
            metrics[coverage_type] = {
                "raw_hit": raw_hit,
                "raw_total": raw_total,
                "structurally_unreachable": unreachable,
                "reachable_hit": raw_hit,
                "reachable_total": reachable_total,
                "reachable_percent": (
                    round(100.0 * raw_hit / reachable_total, 2)
                    if reachable_total
                    else 100.0
                ),
            }
        for item in executions:
            structural.extend(item["structurally_unreachable"])
            unmatched.extend(item["unmatched_zero_records"])
        behavioral_closed = (
            behavioral["passed"] == behavioral["expected_context_executions"]
        )
        code_closed = all(item["status"] == "closed" for item in executions)
        reports[family].update(
            {
                "status": (
                    "closed"
                    if behavioral_closed and code_closed
                    else "blocked"
                ),
                "code_coverage": metrics,
                "coverage_executions": executions,
                "structurally_unreachable": structural,
                "uncovered_records": unmatched,
            }
        )

    extractor_executions = [
        item
        for item in executions_by_family["edge-read"]
        if item["module"] == "cu_edge_data_read_extract_control"
    ]
    extractor_metrics: dict[str, Any] = {}
    for coverage_type in ("line", "branch", "toggle"):
        raw_hit = sum(
            item["code_coverage"][coverage_type]["raw_hit"]
            for item in extractor_executions
        )
        raw_total = sum(
            item["code_coverage"][coverage_type]["raw_total"]
            for item in extractor_executions
        )
        unreachable = sum(
            item["code_coverage"][coverage_type]["structurally_unreachable"]
            for item in extractor_executions
        )
        reachable_total = raw_total - unreachable
        extractor_metrics[coverage_type] = {
            "raw_hit": raw_hit,
            "raw_total": raw_total,
            "structurally_unreachable": unreachable,
            "reachable_hit": raw_hit,
            "reachable_total": reachable_total,
            "reachable_percent": (
                round(100.0 * raw_hit / reachable_total, 2)
                if reachable_total
                else 100.0
            ),
        }
    reports["edge-read-extractor-detail"] = {
        "status": (
            "closed"
            if extractor_executions
            and all(item["status"] == "closed" for item in extractor_executions)
            else "blocked"
        ),
        "code_coverage": extractor_metrics,
        "coverage_executions": extractor_executions,
        "structurally_unreachable": [
            record
            for item in extractor_executions
            for record in item["structurally_unreachable"]
        ],
        "uncovered_records": [
            record
            for item in extractor_executions
            for record in item["unmatched_zero_records"]
        ],
    }
    return errors, identities


def build_family_reports(
    scenarios: dict[str, Any],
    targets: list[dict[str, Any]],
    results: dict[str, Any],
    blockers: list[dict[str, Any]],
) -> dict[str, Any]:
    expected: dict[tuple[str, str, str], dict[str, Any]] = {}
    target_lookup: dict[tuple[str, str], dict[str, Any]] = {}
    for target in targets:
        for context in target["contexts"]:
            key = (target["module"], context)
            target_lookup[key] = target
            expected[(target["family"], target["path"], context)] = {
                "family": target["family"],
                "module": target["module"],
                "path": target["path"],
                "context": context,
                "sha256": sha256(REPO_ROOT / target["path"]),
            }

    observations: dict[tuple[str, str, str], dict[str, Any]] = {}
    blocked_pairs = {
        (item.get("module"), item.get("context"))
        for item in blockers
        if item.get("context")
    }

    def add_observation(
        module: str,
        context: str,
        record: dict[str, Any],
    ) -> None:
        target = target_lookup.get((module, context))
        if target is None:
            return
        run = record.get("run")
        if record.get("build", {}).get("return_code") != 0:
            status = "failed"
            evidence = record["build"]["log"]
        elif run is None:
            status = "failed"
            evidence = None
        elif (
            run["return_code"] == 0
            and not run.get("missing_bins", [])
            and not run.get("missing_coordinates", [])
        ):
            status = "passed"
            evidence = run["log"]
        elif (module, context) in blocked_pairs:
            status = "blocked"
            evidence = run["log"]
        else:
            status = "failed"
            evidence = run["log"]
        observation_key = (target["family"], target["path"], context)
        observation = {
            "status": status,
            "evidence": evidence,
            "bins": run.get("bins", []) if run else [],
            "missing_bins": run.get("missing_bins", []) if run else [],
            "coordinates": run.get("coordinates", []) if run else [],
            "missing_coordinates": (
                run.get("missing_coordinates", []) if run else []
            ),
        }
        previous = observations.get(observation_key)
        if previous is not None:
            status_priority = {
                "passed": 0,
                "blocked": 1,
                "failed": 2,
            }
            observation["status"] = max(
                (previous["status"], observation["status"]),
                key=status_priority.__getitem__,
            )
            observation["bins"] = sorted(
                set(previous["bins"]) | set(observation["bins"])
            )
            observation["missing_bins"] = sorted(
                set(previous["missing_bins"])
                | set(observation["missing_bins"])
            )
            observation["coordinates"] = sorted(
                {
                    tuple(value)
                    for value in (
                        previous.get("coordinates", [])
                        + observation["coordinates"]
                    )
                }
            )
            observation["missing_coordinates"] = sorted(
                {
                    tuple(value)
                    for value in (
                        previous.get("missing_coordinates", [])
                        + observation["missing_coordinates"]
                    )
                }
            )
        observations[observation_key] = observation

    dut = results.get("dut", {})
    for record in dut.get("vertex_filter", []):
        add_observation("cu_vertex_job_filter", record["layout"], record)
    for record in dut.get("edge_extract", []):
        copy = dict(record)
        runs = [
            record.get("baseline"),
            record.get("pulse_upper"),
            record.get("reorder"),
        ]
        copy["run"] = {
            "return_code": (
                1
                if any((run or {}).get("return_code", 1) != 0 for run in runs)
                else 0
            ),
            "log": (record.get("reorder") or {}).get("log"),
            "bins": sorted(
                {
                    bin_name
                    for run in runs
                    if run
                    for bin_name in run.get("bins", [])
                }
            ),
            "missing_bins": sorted(
                {
                    bin_name
                    for run in runs
                    if run
                    for bin_name in run.get("missing_bins", [])
                }
            ),
        }
        add_observation(
            "cu_edge_data_read_extract_control",
            record["layout"],
            copy,
        )
    queue = dut.get("queue_controllers", {})
    queue_modules = {
        "vertex_job_control": "cu_vertex_job_control",
        "edge_job_control": "cu_edge_job_control",
        "edge_read_command_control": "cu_edge_data_read_command_control",
        "edge_write_command_control": "cu_edge_data_write_command_control",
    }
    for category, module in queue_modules.items():
        for record in queue.get(category, []):
            add_observation(module, record["context"], record)
    scheduler = dut.get("scheduler_families", {})
    for record in scheduler.get("algorithm_arbiters", []):
        layout = next(
            item
            for item in scenarios["active_layouts"]
            if item["id"] == record["context"]
        )
        add_observation(
            algorithm_arbiter_module(layout),
            record["context"],
            record,
        )
    scheduler_modules = {
        "cluster_arbiters": "cu_vertex_cluster_arbiter_control",
        "cluster_controls": "cu_vertex_cluster_control",
        "graph_algorithm_arbiters": "cu_graph_algorithm_arbiter_control",
        "graph_algorithm_controls": "cu_graph_algorithm_control",
    }
    for category, module in scheduler_modules.items():
        for record in scheduler.get(category, []):
            add_observation(module, record["context"], record)

    raw_records = parse_raw_coverage(ARTIFACT_ROOT / "coverage_merged.dat")
    direct_hierarchy = {
        "cu_vertex_job_filter": "TOP.tb_vertex_filter_dut.dut",
        "cu_vertex_job_control": "TOP.tb_vertex_job_control_dut.dut",
        "cu_edge_job_control": "TOP.tb_edge_job_control_dut.dut",
        "cu_edge_data_read_command_control": "TOP.tb_edge_read_command_dut.dut",
        "cu_edge_data_read_extract_control": "TOP.tb_edge_extract_dut.dut",
        "cu_edge_data_write_command_control": (
            "TOP.tb_edge_write_"
        ),
        "cu_vertex_cluster_arbiter_control": "TOP.tb_cluster_arbiter_dut.dut",
        "cu_vertex_cluster_control": "TOP.tb_scheduler_control_dut.dut",
        "cu_graph_algorithm_arbiter_control": "TOP.tb_cluster_arbiter_dut.dut",
        "cu_graph_algorithm_control": "TOP.tb_scheduler_control_dut.dut",
        "cu_vertex_bfs_arbiter_control": "TOP.tb_algorithm_arbiter_dut.dut",
        "cu_vertex_pagerank_arbiter_control": "TOP.tb_algorithm_arbiter_dut.dut",
        "cu_vertex_spmv_arbiter_control": "TOP.tb_algorithm_arbiter_dut.dut",
        "cu_vertex_connectedComponents_arbiter_control": "TOP.tb_algorithm_arbiter_dut.dut",
        "cu_vertex_triangleCount_arbiter_control": "TOP.tb_algorithm_arbiter_dut.dut",
    }
    direct_prefix_by_path = {
        target["path"]: direct_hierarchy[target["module"]]
        for target in targets
        if target["module"] in direct_hierarchy
    }
    reports: dict[str, Any] = {}
    for family in scenarios["families"]:
        family_expected = [
            value for key, value in expected.items() if key[0] == family
        ]
        family_observed = []
        for item in family_expected:
            key = (family, item["path"], item["context"])
            observation = observations.get(
                key,
                {
                    "status": "missing",
                    "evidence": None,
                    "bins": [],
                    "missing_bins": [],
                },
            )
            family_observed.append({**item, **observation})
        family_paths = {item["path"] for item in family_expected}
        family_records = [
            record
            for record in raw_records
            if record["file"] in family_paths
            and record["hierarchy"].startswith(
                direct_prefix_by_path.get(record["file"], "")
            )
        ]
        metrics: dict[str, Any] = {}
        uncovered: list[dict[str, Any]] = []
        for coverage_type in ("line", "branch", "toggle"):
            type_records = [
                record
                for record in family_records
                if record["type"] == coverage_type
            ]
            hit = sum(record["count"] > 0 for record in type_records)
            zero = [
                record for record in type_records if record["count"] == 0
            ]
            uncovered.extend(zero)
            metrics[coverage_type] = {
                "hit": hit,
                "total": len(type_records),
                "percent": (
                    round(100.0 * hit / len(type_records), 2)
                    if type_records
                    else 0.0
                ),
            }
        behavioral_closed = all(
            item["status"] == "passed" for item in family_observed
        )
        code_closed = all(
            metrics[coverage_type]["percent"] == 100.0
            for coverage_type in ("line", "branch", "toggle")
        )
        reports[family] = {
            "status": "closed" if behavioral_closed and code_closed else "blocked",
            "behavioral": {
                "expected_context_executions": len(family_expected),
                "passed": sum(
                    item["status"] == "passed" for item in family_observed
                ),
                "blocked": sum(
                    item["status"] == "blocked" for item in family_observed
                ),
                "failed": sum(
                    item["status"] == "failed" for item in family_observed
                ),
                "missing": sum(
                    item["status"] == "missing" for item in family_observed
                ),
                "executions": family_observed,
            },
            "code_coverage": metrics,
            "structurally_unreachable": [],
            "uncovered_records": uncovered,
        }

    extractor_paths = {
        target["path"]
        for target in targets
        if target["module"] == "cu_edge_data_read_extract_control"
    }
    extractor_records = [
        record
        for record in raw_records
        if record["file"] in extractor_paths
        and record["hierarchy"].startswith("TOP.tb_edge_extract_dut.dut")
    ]
    extractor_metrics = {}
    extractor_uncovered = []
    for coverage_type in ("line", "branch", "toggle"):
        type_records = [
            record
            for record in extractor_records
            if record["type"] == coverage_type
        ]
        hit = sum(record["count"] > 0 for record in type_records)
        zero = [record for record in type_records if record["count"] == 0]
        extractor_uncovered.extend(zero)
        extractor_metrics[coverage_type] = {
            "hit": hit,
            "total": len(type_records),
            "percent": (
                round(100.0 * hit / len(type_records), 2)
                if type_records
                else 0.0
            ),
        }
    reports["edge-read-extractor-detail"] = {
        "status": (
            "closed"
            if all(
                extractor_metrics[k]["percent"] == 100.0
                for k in ("line", "branch", "toggle")
            )
            else "blocked"
        ),
        "code_coverage": extractor_metrics,
        "structurally_unreachable": [],
        "uncovered_records": extractor_uncovered,
    }
    return reports


def prepare_artifacts() -> None:
    if ARTIFACT_ROOT.exists():
        shutil.rmtree(ARTIFACT_ROOT)
    (ARTIFACT_ROOT / "logs").mkdir(parents=True)


def completed_owner_line(
    status: str,
    family_reports: dict[str, Any],
) -> str | None:
    if status != "passed":
        return None
    if not all(
        family_reports.get(family, {}).get("status") == "closed"
        for family in OWNER_FAMILIES
    ):
        return None
    return "OWNERS:" + ",".join(OWNER_FAMILIES)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--suite",
        choices=("all", "models", "dut", "elaboration", "mutation"),
        default="all",
    )
    parser.add_argument(
        "--jobs",
        type=int,
        default=min(4, os.cpu_count() or 1),
    )
    parser.add_argument(
        "--allow-known-blockers",
        action="store_true",
        help="Return success when only explicitly classified production blockers fail.",
    )
    args = parser.parse_args()
    if args.jobs < 1:
        parser.error("--jobs must be positive")
    if shutil.which("verilator") is None:
        print("error: verilator is required", file=sys.stderr)
        return 1

    prepare_artifacts()
    scenarios = load_json(SCENARIOS_PATH)
    coverage_contract = load_json(COVERAGE_RULES_PATH)
    matrix = load_json(MATRIX_PATH)
    layouts = load_json(LAYOUTS_PATH)
    targets = collect_targets(scenarios, matrix)
    source_report, errors = verify_source_scope(scenarios, layouts, targets)
    capi_commit = current_capi_commit()
    if capi_commit != scenarios["capi_precis_commit"]:
        errors.append(
            "CAPI submodule commit mismatch: "
            f"expected={scenarios['capi_precis_commit']} actual={capi_commit}"
        )
    results: dict[str, Any] = {"source": source_report}
    blockers: list[dict[str, Any]] = []

    if args.suite in ("all", "elaboration"):
        elaboration = run_elaboration(targets, args.jobs)
        results["elaboration"] = elaboration
        failures = [item for item in elaboration if item["return_code"] != 0]
        for item in failures:
            missing_modules = set(item.get("missing_modules", []))
            if missing_modules and missing_modules <= {
                "fp_single_add_acc",
                "fp_single_mul",
            }:
                blockers.append(
                    {
                        "id": "float_vendor_model_manifest_gap",
                        "context": item["context"],
                        "module": item["module"],
                        "missing_modules": sorted(missing_modules),
                        "diagnostic": item["diagnostic"],
                        "log": item["log"],
                    }
                )
            else:
                errors.append(f"elaboration failed: {item['case']}")

    if args.suite in ("all", "models"):
        model_results, model_errors = run_models(scenarios, args.jobs)
        results["models"] = model_results
        errors.extend(model_errors)

    if args.suite in ("all", "mutation"):
        mutation_results, mutation_errors = run_mutations(scenarios, args.jobs)
        results["mutations"] = mutation_results
        errors.extend(mutation_errors)

    if args.suite in ("all", "dut"):
        filter_results, filter_errors = run_filter_duts(scenarios, args.jobs)
        extract_results, extract_blockers, extract_errors = run_extract_duts(
            scenarios, args.jobs
        )
        queue_results, queue_errors = run_queue_controller_duts(
            scenarios, args.jobs
        )
        scheduler_results, scheduler_blockers, scheduler_errors = (
            run_scheduler_family_duts(scenarios, args.jobs)
        )
        arbiter_results, arbiter_blockers, arbiter_errors = run_arbiter_duts(
            scenarios, args.jobs
        )
        reduction_results, reduction_errors = run_reduction_duts(
            scenarios, args.jobs
        )
        results["dut"] = {
            "vertex_filter": filter_results,
            "edge_extract": extract_results,
            "queue_controllers": queue_results,
            "scheduler_families": scheduler_results,
            "arbiter_primitive": arbiter_results,
            "sum_reduce": reduction_results,
        }
        blockers.extend(extract_blockers)
        blockers.extend(scheduler_blockers)
        blockers.extend(arbiter_blockers)
        errors.extend(filter_errors)
        errors.extend(extract_errors)
        errors.extend(queue_errors)
        errors.extend(scheduler_errors)
        errors.extend(arbiter_errors)
        errors.extend(reduction_errors)

    known_by_id = {
        item["id"]: item for item in scenarios["known_production_blockers"]
    }
    for blocker in blockers:
        blocker["specification"] = known_by_id[blocker["id"]]

    assertion_sites = collect_assertion_sites()
    code_coverage = collect_code_coverage(results)
    contract_checks = source_report["contract_checks"]
    mutations = results.get("mutations", [])
    family_reports = build_family_reports(
        scenarios,
        targets,
        results,
        blockers,
    )
    coverage_contract_errors: list[str] = []
    integration_identities: list[dict[str, Any]] = []
    if args.suite in ("all", "dut"):
        coverage_contract_errors, integration_identities = (
            apply_reachable_coverage(
                scenarios,
                targets,
                family_reports,
                coverage_contract,
            )
        )
        errors.extend(
            f"coverage contract: {error}"
            for error in coverage_contract_errors
        )
    coverage = {
        "source": {
            "module_declarations": source_report["module_declarations"],
            "distinct_source_hashes": source_report["distinct_source_hashes"],
            "context_executions": source_report["context_executions"],
            "expected_context_executions": scenarios[
                "expected_context_executions"
            ],
        },
        "functional": {
            "required_bins": scenarios["functional_bins"],
            "model_runs": results.get("models", []),
        },
        "code": code_coverage,
        "source_integrity": {
            "contract_total": len(contract_checks),
            "contract_passed": sum(
                1 for item in contract_checks if item["passed"]
            ),
            "contract_checks": contract_checks,
            "coverage_credit": False,
            "assertion_credit": False,
        },
        "assertions": {
            "testbench_sites": assertion_sites,
        },
        "mutations": {
            "total": len(mutations),
            "killed": sum(1 for item in mutations if item["killed"]),
            "results": mutations,
        },
        "families": family_reports,
        "coverage_contract": {
            "path": str(COVERAGE_RULES_PATH.relative_to(REPO_ROOT)),
            "errors": coverage_contract_errors,
            "integration_evidence_identity": integration_identities,
        },
    }

    write_json(ARTIFACT_ROOT / "results.json", results)
    write_json(ARTIFACT_ROOT / "coverage.json", coverage)
    write_json(ARTIFACT_ROOT / "family_coverage.json", family_reports)
    write_json(ARTIFACT_ROOT / "blockers.json", blockers)
    summary = {
        "status": (
            "failed"
            if errors
            else "blocked"
            if blockers
            or any(
                report["status"] != "closed"
                for report in family_reports.values()
            )
            else "passed"
        ),
        "suite": args.suite,
        "capi_precis_commit": capi_commit,
        "errors": errors,
        "known_production_blockers": len(blockers),
        "blocker_ids": sorted({item["id"] for item in blockers}),
        "family_status": {
            family: report["status"]
            for family, report in family_reports.items()
        },
        "source_context_executions": source_report["context_executions"],
        "source_distinct_hashes": source_report["distinct_source_hashes"],
        "mutation_score": {
            "killed": coverage["mutations"]["killed"],
            "total": coverage["mutations"]["total"],
        },
    }
    write_json(ARTIFACT_ROOT / "summary.json", summary)
    print(
        "AccelGraph engine unit coverage: "
        f"{summary['status']} "
        f"({summary['source_context_executions']} context executions, "
        f"{summary['source_distinct_hashes']} hashes, "
        f"{summary['known_production_blockers']} blocker observations)"
    )
    print(f"Artifacts: {ARTIFACT_ROOT}")
    owner_line = completed_owner_line(summary["status"], family_reports)
    if owner_line is not None:
        print(owner_line)
    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1
    if blockers and not args.allow_known_blockers:
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
