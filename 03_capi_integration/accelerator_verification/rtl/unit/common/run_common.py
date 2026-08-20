#!/usr/bin/env python3
"""AccelGraph RTL unit suite for the graph common families.

Covers the routing-demux, sum-reduction and graph-package-contracts families of
03_capi_integration/accelerator_verification/rtl/manifests/coverage-plan.json.

The execution denominator is derived from the shared manifests, never from this
script: every distinct source hash of every in scope declaration is executed in
every active layout context, and the derived numbers are cross checked against
scenarios.json before anything is compiled.
"""

import argparse
import concurrent.futures
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

SCRIPT = Path(__file__).resolve()
UNIT_ROOT = SCRIPT.parent
REPO_ROOT = SCRIPT.parents[5]
MANIFEST_ROOT = REPO_ROOT / "03_capi_integration/accelerator_verification/rtl/manifests"
BUILD_ROOT = REPO_ROOT / "02_capi_graph/obj/rtl_unit_common"
SCENARIOS = UNIT_ROOT / "scenarios.json"
COVERAGE_SPEC = UNIT_ROOT / "coverage.json"
MAIN = UNIT_ROOT / "graph_common_main.cpp"

MODULE_FAMILIES = {
    "array_struct_type_demux_bus": "routing-demux",
    "demux_bus": "routing-demux",
    "sum_reduce": "sum-reduction",
}
PACKAGE_DECLARATIONS = ("WED_PKG", "GLOBALS_CU_PKG", "CU_PKG")

SUITES = {
    "routing-demux": {
        "top": "graph_routing_demux_tb",
        "tb": "graph_routing_demux_tb.sv",
        "declarations": ("array_struct_type_demux_bus", "demux_bus"),
        "pass_prefix": "PASS graph_routing_demux",
    },
    "sum-reduction": {
        "top": "graph_sum_reduce_tb",
        "tb": "graph_sum_reduce_tb.sv",
        "declarations": ("sum_reduce",),
        "pass_prefix": "PASS graph_sum_reduce",
    },
    "graph-package-contracts": {
        "top": "graph_package_contract_tb",
        "tb": "graph_package_contract_tb.sv",
        "declarations": PACKAGE_DECLARATIONS,
        "pass_prefix": "PASS graph_package_contracts",
    },
}

VERILATOR_FLAGS = [
    "--cc",
    "--exe",
    "--build",
    "--build-jobs",
    "1",
    "--timing",
    "--timescale",
    "1ns/1ps",
    "--assert",
    "-Wall",
    "-Wno-ASCRANGE",
    "-Wno-BLKSEQ",
    "-Wno-DECLFILENAME",
    "-Wno-EOFNEWLINE",
    "-Wno-IMPORTSTAR",
    "-Wno-UNUSEDPARAM",
    "-Wno-UNUSEDSIGNAL",
    "-Wno-WIDTHEXPAND",
    "-Wno-WIDTHTRUNC",
]


class Failure(Exception):
    pass


def fail(message):
    raise Failure(message)


def sha256_file(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def load_json(path):
    return json.loads(Path(path).read_text())


def run(command, **kwargs):
    return subprocess.run(command, check=False, text=True, **kwargs)


# -----------------------------------------------------------------------------
# Manifest ingestion
# -----------------------------------------------------------------------------
def load_manifests():
    inventory_path = MANIFEST_ROOT / "rtl-inventory.json"
    matrix_path = MANIFEST_ROOT / "module-test-matrix.json"
    layouts_path = MANIFEST_ROOT / "layouts.json"
    plan_path = MANIFEST_ROOT / "coverage-plan.json"
    for path in (inventory_path, matrix_path, layouts_path, plan_path):
        if not path.is_file():
            fail(f"missing shared manifest {path}")

    inventory = load_json(inventory_path)
    matrix = load_json(matrix_path)
    layouts = load_json(layouts_path)
    plan = load_json(plan_path)

    if sha256_file(inventory_path) != matrix["rtl_inventory_sha256"]:
        fail("module-test-matrix.json was generated from a different rtl-inventory.json")
    if sha256_file(plan_path) != matrix["coverage_plan_sha256"]:
        fail("module-test-matrix.json was generated from a different coverage-plan.json")
    if inventory["schema_version"] != matrix["inventory_schema_version"]:
        fail("inventory schema version disagrees with the module test matrix")
    if plan["plan_id"] != matrix["plan_id"]:
        fail("coverage plan identity disagrees with the module test matrix")
    return inventory, matrix, layouts, plan


def active_layouts(layouts):
    active = {
        layout["id"]: layout
        for layout in layouts["layouts"]
        if layout["status"] == "active"
    }
    if not active:
        fail("no active layout in layouts.json")
    return active


def scope_from_matrix(matrix, active):
    """Returns the (declaration, hash, context) executions owned by this suite."""
    modules = []
    for entry in matrix["modules"]:
        if entry["module"] not in MODULE_FAMILIES:
            continue
        contexts = sorted(entry["contexts"])
        unknown = [context for context in contexts if context not in active]
        if unknown:
            fail(f"{entry['path']} is mapped to inactive contexts {unknown}")
        modules.append(
            {
                "declaration": entry["module"],
                "kind": "module",
                "path": entry["path"],
                "sha256": entry["sha256"],
                "family": MODULE_FAMILIES[entry["module"]],
                "suite": MODULE_FAMILIES[entry["module"]],
                "contexts": contexts,
                "test_id": entry["test_id"],
                "oracle_id": entry["oracle_id"],
            }
        )
    packages = []
    for entry in matrix["non_module_declarations"]:
        if entry["package"] not in PACKAGE_DECLARATIONS:
            fail(f"unexpected package declaration {entry['package']} in the matrix")
        contexts = sorted(entry["contexts"])
        unknown = [context for context in contexts if context not in active]
        if unknown:
            fail(f"{entry['path']} is mapped to inactive contexts {unknown}")
        packages.append(
            {
                "declaration": entry["package"],
                "kind": "package",
                "path": entry["path"],
                "sha256": entry["sha256"],
                "family": "graph-package-contracts",
                "suite": "graph-package-contracts",
                "contexts": contexts,
                "test_id": entry["test_id"],
                "oracle_id": entry["oracle_id"],
            }
        )
    entries = modules + packages
    if not entries:
        fail("the module test matrix contains no declaration for the graph common families")
    return entries


def check_sources(entries):
    for entry in entries:
        path = REPO_ROOT / entry["path"]
        if not path.is_file():
            fail(f"missing source {entry['path']}")
        digest = sha256_file(path)
        if digest != entry["sha256"]:
            fail(
                f"{entry['path']} no longer matches the manifest hash "
                f"({digest} != {entry['sha256']})"
            )


def check_inventory_scope(inventory, entries):
    """The inventory decides what is in scope; the matrix may not add or drop."""
    owned = set(MODULE_FAMILIES) | set(PACKAGE_DECLARATIONS)
    inventory_by_path = {record["path"]: record for record in inventory["files"]}
    inventory_paths = set()
    for record in inventory["files"]:
        names = {declaration["name"] for declaration in record["declarations"]}
        if not names & owned:
            continue
        if record["status"] != "active":
            continue
        inventory_paths.add(record["path"])
    matrix_paths = {entry["path"] for entry in entries}
    if inventory_paths != matrix_paths:
        fail(
            "the module test matrix and the RTL inventory disagree about the graph common "
            f"scope: {sorted(inventory_paths ^ matrix_paths)}"
        )
    for entry in entries:
        record = inventory_by_path[entry["path"]]
        if record["sha256"] != entry["sha256"]:
            fail(f"{entry['path']}: inventory and matrix hashes disagree")
        names = {declaration["name"] for declaration in record["declarations"]}
        if entry["declaration"] not in names:
            fail(f"{entry['path']}: the inventory does not declare {entry['declaration']}")
        membership = sorted({member["layout"] for member in record["build_membership"]})
        if membership != entry["contexts"]:
            fail(
                f"{entry['path']}: inventory build membership {membership} differs from the "
                f"matrix contexts {entry['contexts']}"
            )


def check_denominator(entries, active, scenarios):
    declared = scenarios["context_denominator"]
    executions = sum(len(entry["contexts"]) for entry in entries)
    hashes = {(entry["declaration"], entry["sha256"]) for entry in entries}
    if declared["active_contexts"] != len(active):
        fail(
            f"scenarios.json declares {declared['active_contexts']} active contexts, "
            f"the layout manifest has {len(active)}"
        )
    if declared["declaration_context_executions"] != executions:
        fail(
            f"scenarios.json declares {declared['declaration_context_executions']} context "
            f"executions, the module test matrix requires {executions}"
        )
    if declared["distinct_source_hashes"] != len(hashes):
        fail(
            f"scenarios.json declares {declared['distinct_source_hashes']} distinct source "
            f"hashes, the module test matrix has {len(hashes)}"
        )
    per_declaration = declared["per_declaration"]
    for name in sorted(MODULE_FAMILIES) + list(PACKAGE_DECLARATIONS):
        owned = [entry for entry in entries if entry["declaration"] == name]
        if not owned:
            fail(f"the module test matrix has no declaration named {name}")
        if name not in per_declaration:
            fail(f"scenarios.json does not declare the denominator of {name}")
        expected = per_declaration[name]
        actual_hashes = len({entry["sha256"] for entry in owned})
        actual_executions = sum(len(entry["contexts"]) for entry in owned)
        if expected["hashes"] != actual_hashes:
            fail(
                f"{name}: scenarios.json declares {expected['hashes']} hashes, the matrix has "
                f"{actual_hashes}"
            )
        if expected["context_executions"] != actual_executions:
            fail(
                f"{name}: scenarios.json declares {expected['context_executions']} context "
                f"executions, the matrix has {actual_executions}"
            )
        covered = set()
        for entry in owned:
            covered.update(entry["contexts"])
        if covered != set(active):
            missing = sorted(set(active) - covered)
            fail(f"{name} is not exercised in every active context, missing {missing}")
    return executions, len(hashes)


def check_scenario_tables(entries, scenarios, active):
    """Every hash in scope must own a reviewed contract, and vice versa."""
    by_declaration = {}
    for entry in entries:
        by_declaration.setdefault(entry["declaration"], {}).setdefault(
            entry["sha256"], set()
        ).update(entry["contexts"])

    tables = {
        "array_struct_type_demux_bus": scenarios["route_tables"],
        "CU_PKG": scenarios["cu_pkg_contracts"],
        "WED_PKG": scenarios["wed_pkg_contracts"],
    }
    for declaration, table in tables.items():
        observed = by_declaration[declaration]
        if set(table) != set(observed):
            fail(
                f"{declaration}: scenarios.json describes hashes {sorted(table)} but the "
                f"manifest requires {sorted(observed)}"
            )
        for digest, contract in table.items():
            if sorted(contract["layouts"]) != sorted(observed[digest]):
                fail(
                    f"{declaration} {digest[:12]}: scenarios.json layouts "
                    f"{sorted(contract['layouts'])} differ from the manifest contexts "
                    f"{sorted(observed[digest])}"
                )

    globals_contracts = scenarios["globals_cu_pkg_contracts"]
    if set(globals_contracts) != set(active):
        fail("scenarios.json does not describe GLOBALS_CU_PKG for every active layout")

    enum_by_hash = {
        digest: contract["array_struct_type"]
        for digest, contract in scenarios["cu_pkg_contracts"].items()
    }
    for digest, route in scenarios["route_tables"].items():
        for layout in route["layouts"]:
            cu_hash = cu_pkg_hash_for(entries, layout)
            literals = enum_by_hash[cu_hash]
            for name in route["destination_0"] + route["destination_1"]:
                if name not in literals:
                    fail(
                        f"route table {digest[:12]} references {name}, which the CU_PKG of "
                        f"{layout} does not declare"
                    )


def cu_pkg_hash_for(entries, layout):
    for entry in entries:
        if entry["declaration"] == "CU_PKG" and layout in entry["contexts"]:
            return entry["sha256"]
    fail(f"no CU_PKG declaration for {layout}")


def entry_for(entries, declaration, layout):
    for entry in entries:
        if entry["declaration"] == declaration and layout in entry["contexts"]:
            return entry
    fail(f"no {declaration} declaration for {layout}")


def package_chain(layout):
    """Package compilation order for a layout, taken from its shared manifest."""
    manifest = MANIFEST_ROOT / f"{layout}.f"
    if not manifest.is_file():
        fail(f"missing layout manifest {manifest}")
    chain = []
    for line in manifest.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        if line.endswith("_pkg.sv"):
            path = REPO_ROOT / line
            if not path.is_file():
                fail(f"{manifest.name} refers to a missing package source {line}")
            chain.append(path)
    if not chain:
        fail(f"{manifest.name} declares no package sources")
    return chain


# -----------------------------------------------------------------------------
# Contract extraction from the production sources
# -----------------------------------------------------------------------------
def parse_parameters(path):
    values = {}
    pattern = re.compile(
        r"^\s*parameter\s+(?:\[[^\]]*\]\s+)?([A-Za-z_][A-Za-z_0-9]*)\s*=\s*([^;]+);", re.M
    )
    for name, expression in pattern.findall(Path(path).read_text()):
        values[name] = expression.split("//")[0].strip()
    return values


def parse_functions(path):
    return re.findall(
        r"^\s*function\s+.*?\b([A-Za-z_][A-Za-z_0-9]*)\s*\(", Path(path).read_text(), re.M
    )


def check_package_inventories(entries, scenarios, active):
    profiles = scenarios["globals_cu_pkg_profiles"]
    for layout in sorted(active):
        contract = scenarios["globals_cu_pkg_contracts"][layout]
        globals_entry = entry_for(entries, "GLOBALS_CU_PKG", layout)
        parameters = parse_parameters(REPO_ROOT / globals_entry["path"])
        expected_names = set(profiles["base"])
        if contract["profile"] != "base":
            expected_names |= set(profiles[contract["profile"]])
        if set(parameters) != expected_names:
            missing = sorted(expected_names - set(parameters))
            extra = sorted(set(parameters) - expected_names)
            fail(
                f"{layout}: GLOBALS_CU_PKG parameter inventory changed, missing={missing} "
                f"unexpected={extra}"
            )
        for name, value in contract["constants"].items():
            if name not in parameters:
                fail(f"{layout}: GLOBALS_CU_PKG does not export {name}")
            if parameters[name] != str(value):
                fail(
                    f"{layout}: GLOBALS_CU_PKG {name} is {parameters[name]}, the precision "
                    f"contract declares {value}"
                )
        cu_entry = entry_for(entries, "CU_PKG", layout)
        cu_contract = scenarios["cu_pkg_contracts"][cu_entry["sha256"]]
        functions = parse_functions(REPO_ROOT / cu_entry["path"])
        if functions != cu_contract["functions"]:
            fail(
                f"{layout}: CU_PKG function inventory changed, {functions} != "
                f"{cu_contract['functions']}"
            )


def afu_constants():
    path = REPO_ROOT / (
        "01_capi_precis/01_capi_integration/accelerator_rtl/afu_pkgs/globals_afu_pkg.sv"
    )
    parameters = parse_parameters(path)
    for name in ("CU_ID_RANGE", "CACHELINE_SIZE"):
        if name not in parameters:
            fail(f"globals_afu_pkg.sv does not export {name}")
    return {name: int(parameters[name]) for name in ("CU_ID_RANGE", "CACHELINE_SIZE")}


def parse_wed_c_abi(scenarios):
    """Byte offsets of the packed host descriptor, straight from the C header."""
    spec = scenarios["wed_c_abi"]
    header = REPO_ROOT / spec["header"]
    if not header.is_file():
        fail(f"missing host descriptor header {spec['header']}")
    text = header.read_text()
    match = re.search(
        r"struct\s+__attribute__\(\(__packed__\)\)\s+" + spec["structure"] + r"\s*\{(.*?)\}\s*;",
        text,
        re.S,
    )
    if not match:
        fail(f"could not locate the packed C structure {spec['structure']}")
    body = match.group(1)
    fields = []
    for line in body.splitlines():
        line = line.split("//")[0].strip()
        if not line or line.startswith("//"):
            continue
        declaration = re.match(r"^([A-Za-z_][A-Za-z_0-9]*)\s*(\*?)\s*([A-Za-z_][A-Za-z_0-9]*)\s*;$",
                               line)
        if not declaration:
            fail(f"unsupported field declaration in {spec['structure']}: {line}")
        base, pointer, name = declaration.groups()
        c_type = f"{base} *" if pointer else base
        fields.append((name, c_type))
    declared = [(name, c_type) for name, c_type in spec["fields"]]
    if fields != declared:
        fail(
            f"{spec['structure']} in {spec['header']} no longer matches the reviewed ABI: "
            f"{fields} != {declared}"
        )
    layout = []
    offset = 0
    for name, c_type in fields:
        if c_type not in spec["type_bytes"]:
            fail(f"unknown C type {c_type} in {spec['structure']}")
        size = spec["type_bytes"][c_type]
        layout.append({"name": name, "offset": offset, "bytes": size})
        offset += size
    if offset != spec["total_bytes"]:
        fail(f"{spec['structure']} is {offset} bytes, the ABI contract declares "
             f"{spec['total_bytes']}")
    return layout


# -----------------------------------------------------------------------------
# Derived expectations
# -----------------------------------------------------------------------------
def selector_width(bus_width):
    if bus_width <= 1:
        return 1
    width = 0
    while (1 << width) < bus_width:
        width += 1
    return width


def resolve(value, symbols):
    if isinstance(value, int):
        return value
    if value not in symbols:
        fail(f"unknown symbolic width {value}")
    return symbols[value]


def sv_width(value):
    """SystemVerilog expression for a symbolic field width."""
    if isinstance(value, int):
        return str(value)
    if value == "ARRAY_STRUCT_TYPE_BITS":
        return "$bits(array_struct_type)"
    return value


def sv_fill(value):
    """All ones stimulus for a field, with an explicit cast for enumerations."""
    if value == "ARRAY_STRUCT_TYPE_BITS":
        return "array_struct_type'({$bits(array_struct_type){1'b1}})"
    return "'1"


def context_symbols(layout, layouts_by_id, scenarios, constants):
    symbols = {
        "NUM_GRAPH_CU_GLOBAL": layouts_by_id[layout]["graph_cus"],
        "NUM_VERTEX_CU_GLOBAL": layouts_by_id[layout]["vertex_cus_per_graph_cu"],
        "CU_ID_RANGE": constants["CU_ID_RANGE"],
        "ARRAY_STRUCT_TYPE_BITS": scenarios["symbolic_widths"]["ARRAY_STRUCT_TYPE_BITS"],
    }
    for name, value in scenarios["globals_cu_pkg_contracts"][layout]["constants"].items():
        symbols[name] = value
        if name.endswith("SIZE") or name.startswith("DATA_SIZE"):
            symbols[f"{name}_BITS"] = value * 8
    return symbols


def routing_bins(layout, scenarios, symbols, literals):
    total = 0
    for instance in scenarios["instances"]["demux_bus"]:
        bus = resolve(instance["bus_width"], symbols)
        width = selector_width(bus)
        space = 1 << width
        total += 2 * space + 4
        if space > bus:
            total += 1
    for _ in scenarios["instances"]["array_struct_type_demux_bus"]:
        total += 2 * len(literals) + 8
    return total


def reduction_bins(scenarios, symbols):
    total = 0
    for instance in scenarios["instances"]["sum_reduce"]:
        width_in = resolve(instance["data_width_in"], symbols)
        width_out = resolve(instance["data_width_out"], symbols)
        bus = resolve(instance["bus_width"], symbols)
        maximum = bus * ((1 << width_in) - 1)
        span = 1 << width_out
        total += 6
        if bus > 1:
            total += 1
        if maximum >= span - 1:
            total += 1
        if maximum >= span:
            total += 1
        if maximum >= (span << 1):
            total += 1
    return total


def package_bins(layout, scenarios, symbols, cu_contract, wed_contract):
    total = 24
    size = symbols["VERTEX_SIZE"]
    while size <= 128:
        total += 1
        size <<= 1
    total += len(cu_contract["endianness_functions"])
    if wed_contract["auxiliary_extension"]:
        total += 1
    profile = scenarios["globals_cu_pkg_contracts"][layout]["profile"]
    if profile != "base":
        total += 1
    return total


# -----------------------------------------------------------------------------
# Source generation
# -----------------------------------------------------------------------------
def generate_context_header(layout, layouts_by_id, scenarios, symbols, cu_contract,
                            route_table, bins):
    literals = cu_contract["array_struct_type"]
    destinations = {}
    for name in route_table["destination_0"]:
        destinations[name] = 0
    for name in route_table["destination_1"]:
        if name in destinations:
            fail(f"{name} is routed to two destinations by the scenario manifest")
        destinations[name] = 1
    lines = [
        "// Generated by run_common.py - do not edit.",
        f'localparam string CTX_LAYOUT = "{layout}";',
        f"localparam int CTX_GRAPH_CUS = {layouts_by_id[layout]['graph_cus']};",
        f"localparam int CTX_VERTEX_CUS = {layouts_by_id[layout]['vertex_cus_per_graph_cu']};",
        f"localparam int CTX_TOTAL_VERTEX_CUS = {layouts_by_id[layout]['total_vertex_cus']};",
        f"localparam int CTX_ROUTING_BINS = {bins['routing-demux']};",
        f"localparam int CTX_REDUCTION_BINS = {bins['sum-reduction']};",
        f"localparam int CTX_PACKAGE_BINS = {bins['graph-package-contracts']};",
        f"localparam int ROUTE_LITERAL_COUNT = {len(literals)};",
        "string route_literal_name [0:ROUTE_LITERAL_COUNT-1];",
        "int    route_literal_value[0:ROUTE_LITERAL_COUNT-1];",
        "int    route_literal_dest [0:ROUTE_LITERAL_COUNT-1];",
        "",
        "task automatic route_oracle_load();",
    ]
    for index, name in enumerate(literals):
        destination = destinations.get(name, -1)
        lines.append(
            f'\troute_literal_name[{index}] = "{name}";'
            f" route_literal_value[{index}] = {index};"
            f" route_literal_dest[{index}] = {destination};"
        )
    lines.append("endtask")
    lines.append("")
    return "\n".join(lines)


def generate_package_oracle(layout, scenarios, symbols, cu_contract, wed_contract, wed_layout):
    request_bits = wed_contract["request_bits"]
    lines = [
        "// Generated by run_common.py - do not edit.",
        f"localparam int EXPECT_WED_BITS = {request_bits};",
        "",
        "task automatic oracle_check_wed_field_spans();",
        "\tWED_request probe;",
    ]
    offset_bits = 0
    for field in wed_layout:
        lines.append("\tprobe = '0;")
        lines.append(f"\tprobe.{field['name']} = '1;")
        lines.append(
            f'\tharness_check_span("WED_request.{field["name"]}", probe, $bits(WED_request), '
            f"{field['offset'] * 8}, {field['bytes'] * 8});"
        )
        offset_bits = (field["offset"] + field["bytes"]) * 8
    for name in wed_contract["auxiliary_extension"]:
        lines.append("\tprobe = '0;")
        lines.append(f"\tprobe.{name} = '1;")
        lines.append(
            f'\tharness_check_span("WED_request.{name}", probe, $bits(WED_request), '
            f"{offset_bits}, 64);"
        )
        offset_bits += 64
    if offset_bits != request_bits:
        fail(
            f"{layout}: descriptor field table covers {offset_bits} bits, the contract declares "
            f"{request_bits}"
        )
    lines.append("endtask")
    lines.append("")
    lines.append("task automatic oracle_check_wed_map(input WED_request request);")
    for field in wed_layout:
        lines.append(
            f'\tharness_check_bits("map.{field["name"]}", '
            f"expected_field({field['offset']}, {field['bytes']}), request.{field['name']}, "
            "pattern_name);"
        )
    for name in wed_contract["auxiliary_extension"]:
        lines.append(
            f'\tharness_check_bits("map.{name}", \'0, request.{name}, pattern_name);'
        )
    if wed_contract["auxiliary_extension"]:
        lines.append('\tharness_cover("wed_auxiliary_extension");')
    lines.append("endtask")
    lines.append("")

    lines.append("task automatic oracle_check_precision_constants();")
    for name, value in scenarios["globals_cu_pkg_contracts"][layout]["constants"].items():
        lines.append(
            f'\tharness_check_int("{name}", {value}, {name}, "precision contract of {layout}");'
        )
    lines.append('\tharness_cover("globals_precision_constants");')
    profile = scenarios["globals_cu_pkg_contracts"][layout]["profile"]
    if profile == "bfs_parent":
        lines.append(
            '\tharness_check_int("DATA_SIZE_READ_PARENT_BITS", DATA_SIZE_READ_PARENT * 8, '
            'DATA_SIZE_READ_PARENT_BITS, "derived width identity broken");'
        )
        lines.append(
            '\tharness_check_int("DATA_SIZE_WRITE_PARENT_BITS", DATA_SIZE_WRITE_PARENT * 8, '
            'DATA_SIZE_WRITE_PARENT_BITS, "derived width identity broken");'
        )
        lines.append('\tharness_cover("globals_parent_constants");')
    elif profile == "weighted":
        lines.append(
            '\tharness_check_int("EDGE_WEIGHT_SIZE_BITS", EDGE_WEIGHT_SIZE * 8, '
            'EDGE_WEIGHT_SIZE_BITS, "derived width identity broken");'
        )
        lines.append(
            '\tharness_check_int("CACHELINE_EDGE_WEIGHT_NUM", CACHELINE_SIZE / EDGE_WEIGHT_SIZE, '
            'CACHELINE_EDGE_WEIGHT_NUM, "cacheline population identity broken");'
        )
        lines.append('\tharness_cover("globals_edge_weight_constants");')
    lines.append("endtask")
    lines.append("")

    literals = cu_contract["array_struct_type"]
    lines.append("task automatic oracle_check_enum_contract();")
    lines.append("\tarray_struct_type literal;")
    lines.append(
        f'\tharness_check_int("array_struct_type literal count", {len(literals)}, literal.num(), '
        '"selector enumeration changed");'
    )
    lines.append("\tliteral = literal.first();")
    for index, name in enumerate(literals):
        lines.append(
            f'\tharness_check_string("array_struct_type[{index}]", "{name}", literal.name(), '
            '"selector enumeration order changed");'
        )
        lines.append(
            f'\tharness_check_int("array_struct_type[{index}] encoding", {index}, int\'(literal), '
            '"selector enumeration encoding changed");'
        )
        lines.append("\tliteral = literal.next();")
    lines.append('\tharness_cover("cu_enum_contract");')
    lines.append("endtask")
    lines.append("")

    lines.append("task automatic oracle_check_type_layout();")
    for type_name, fields in cu_contract["types"].items():
        lines.append("\tbegin")
        lines.append(f"\t\t{type_name} probe;")
        total_bits = sum(resolve(width, symbols) for _, width in fields)
        lines.append(
            f'\t\tharness_check_int("$bits({type_name})", {total_bits}, $bits({type_name}), '
            '"packed type width changed");'
        )
        offset = "0"
        for name, width in fields:
            lines.append("\t\tprobe = '0;")
            lines.append(f"\t\tprobe.{name} = {sv_fill(width)};")
            lines.append(
                f'\t\tharness_check_span("{type_name}.{name}", probe, $bits({type_name}), '
                f"{offset}, {sv_width(width)});"
            )
            offset = f"({offset} + {sv_width(width)})"
        lines.append("\tend")
    for wrapper, payload in cu_contract["wrappers"].items():
        payload_bits = sum(
            resolve(width, symbols) for _, width in cu_contract["types"][payload]
        )
        lines.append("\tbegin")
        lines.append(f"\t\t{wrapper} probe;")
        lines.append(
            f'\t\tharness_check_int("$bits({wrapper})", {payload_bits + 1}, $bits({wrapper}), '
            '"interface wrapper width changed");'
        )
        lines.append("\t\tprobe = '0;")
        lines.append("\t\tprobe.valid = 1'b1;")
        lines.append(
            f'\t\tharness_check_span("{wrapper}.valid", probe, $bits({wrapper}), 0, 1);'
        )
        lines.append("\t\tprobe = '0;")
        lines.append("\t\tprobe.payload = '1;")
        lines.append(
            f'\t\tharness_check_span("{wrapper}.payload", probe, $bits({wrapper}), 1, '
            f"$bits({payload}));"
        )
        lines.append("\tend")
    lines.append('\tharness_cover("cu_type_layout");')
    lines.append("endtask")
    lines.append("")

    lines.append("task automatic oracle_check_endianness(input int kind);")
    lines.append("\tlogic [0:HARNESS_WIDE_BITS-1] stimulus;")
    lines.append("\tlogic [0:HARNESS_WIDE_BITS-1] expected;")
    lines.append("\tlogic [0:HARNESS_WIDE_BITS-1] actual;")
    lines.append("\tlogic [0:HARNESS_WIDE_BITS-1] restored;")
    for function, size_symbol in cu_contract["endianness_functions"].items():
        lines.append(f"\tstimulus = byte_pattern(kind, {size_symbol});")
        lines.append(f"\texpected = reverse_bytes(stimulus, {size_symbol});")
        lines.append(f"\tactual   = {function}(stimulus);")
        lines.append(f"\trestored = {function}(actual);")
        lines.append(
            f'\tharness_check_bits("{function}", expected, actual, "byte order contract");'
        )
        lines.append(
            f'\tharness_check_bits("{function} involution", stimulus, restored, '
            '"byte order contract");'
        )
        lines.append(f'\tharness_cover("{function}_boundary");')
    lines.append("endtask")
    lines.append("")

    lines.append("task automatic oracle_declare_bins();")
    for function in cu_contract["endianness_functions"]:
        lines.append(f'\tharness_declare_bin("{function}_boundary");')
    if wed_contract["auxiliary_extension"]:
        lines.append('\tharness_declare_bin("wed_auxiliary_extension");')
    if profile == "bfs_parent":
        lines.append('\tharness_declare_bin("globals_parent_constants");')
    elif profile == "weighted":
        lines.append('\tharness_declare_bin("globals_edge_weight_constants");')
    lines.append("endtask")
    lines.append("")
    return "\n".join(lines)


# -----------------------------------------------------------------------------
# Compilation and execution
# -----------------------------------------------------------------------------
def compile_and_run(job, verilator, coverage):
    build_dir = job["build_dir"]
    build_dir.mkdir(parents=True, exist_ok=True)
    command = [verilator] + VERILATOR_FLAGS
    if coverage:
        command += ["--coverage-line", "--coverage-toggle"]
    command += [
        "--top-module",
        job["top"],
        "--Mdir",
        str(build_dir),
        f"+incdir+{job['generated_dir']}",
        f"+incdir+{UNIT_ROOT}",
        "-CFLAGS",
        f'-DVTOP_HEADER=\\"V{job["top"]}.h\\" -DVTOP_TYPE=V{job["top"]}',
    ]
    command += [str(path) for path in job["sources"]]
    command += [str(UNIT_ROOT / job["tb"]), str(MAIN)]
    compiled = run(command, capture_output=True, cwd=str(build_dir))
    if compiled.returncode:
        return {
            "job": job,
            "stage": "compile",
            "returncode": compiled.returncode,
            "output": compiled.stdout + compiled.stderr,
        }
    executed = run(
        [str(build_dir / f"V{job['top']}")], capture_output=True, cwd=str(build_dir)
    )
    return {
        "job": job,
        "stage": "run",
        "returncode": executed.returncode,
        "output": executed.stdout + executed.stderr,
    }


# -----------------------------------------------------------------------------
# Coverage
# -----------------------------------------------------------------------------
COVERAGE_RECORD = re.compile(r"^C '(.*)' (\d+)$")


def parse_coverage(path, sources):
    wanted = {str(source) for source in sources}
    points = {}
    for line in Path(path).read_bytes().decode("latin1").splitlines():
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


def summarise_coverage(points):
    summary = {}
    for (source, page, _line, _column, _name, _scope), count in points.items():
        bucket = summary.setdefault(Path(source).name, {}).setdefault(
            page, {"found": 0, "hit": 0}
        )
        bucket["found"] += 1
        bucket["hit"] += 1 if count > 0 else 0
    return summary


def unhit_points(points):
    return sorted(
        f"{Path(source).name}:{line} {page} {name} scope={scope}"
        for (source, page, line, _column, name, scope), count in points.items()
        if count == 0
    )


# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------
def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--jobs", type=int, default=min(16, os.cpu_count() or 4))
    parser.add_argument(
        "--emit-baseline",
        metavar="PATH",
        help="write the observed coverage denominators for review; never used as an input",
    )
    parser.add_argument(
        "--only-context",
        action="append",
        default=[],
        help="debug helper; the run is reported as partial and exits nonzero",
    )
    parser.add_argument(
        "--skip-mutations",
        action="store_true",
        help="debug helper; the run is reported as partial and exits nonzero",
    )
    arguments = parser.parse_args()
    partial = bool(arguments.only_context) or arguments.skip_mutations

    verilator = os.environ.get("VERILATOR", "verilator")
    required = os.environ.get("RTL_VERIFICATION_REQUIRED") == "1"
    resolved = shutil.which(verilator)
    version = 0
    if resolved:
        probe = run([resolved, "--version"], capture_output=True)
        match = re.search(r"Verilator\s+(\d+)", probe.stdout) if not probe.returncode else None
        version = int(match.group(1)) if match else 0
    if not resolved or version < 5:
        if required:
            fail("Verilator 5 or newer is required")
        print("SKIP graph_common_unit: install Verilator 5 or set RTL_VERIFICATION_REQUIRED=1")
        return 0

    inventory, matrix, layouts, plan = load_manifests()
    active = active_layouts(layouts)
    layouts_by_id = active
    entries = scope_from_matrix(matrix, active)
    check_sources(entries)
    check_inventory_scope(inventory, entries)
    scenarios = load_json(SCENARIOS)
    coverage_spec = load_json(COVERAGE_SPEC)
    executions, hashes = check_denominator(entries, active, scenarios)
    check_scenario_tables(entries, scenarios, active)
    check_package_inventories(entries, scenarios, active)
    constants = afu_constants()
    wed_layout = parse_wed_c_abi(scenarios)

    contexts = sorted(active)
    selected = contexts
    if arguments.only_context:
        selected = [context for context in contexts if context in arguments.only_context]
        if not selected:
            fail("no active context matched --only-context")

    shutil.rmtree(BUILD_ROOT, ignore_errors=True)
    BUILD_ROOT.mkdir(parents=True)

    jobs = []
    context_state = {}
    for layout in selected:
        symbols = context_symbols(layout, layouts_by_id, scenarios, constants)
        cu_entry = entry_for(entries, "CU_PKG", layout)
        wed_entry = entry_for(entries, "WED_PKG", layout)
        struct_entry = entry_for(entries, "array_struct_type_demux_bus", layout)
        cu_contract = scenarios["cu_pkg_contracts"][cu_entry["sha256"]]
        wed_contract = scenarios["wed_pkg_contracts"][wed_entry["sha256"]]
        route_table = scenarios["route_tables"][struct_entry["sha256"]]
        literals = cu_contract["array_struct_type"]
        bins = {
            "routing-demux": routing_bins(layout, scenarios, symbols, literals),
            "sum-reduction": reduction_bins(scenarios, symbols),
            "graph-package-contracts": package_bins(
                layout, scenarios, symbols, cu_contract, wed_contract
            ),
        }
        generated_dir = BUILD_ROOT / "generated" / layout
        generated_dir.mkdir(parents=True, exist_ok=True)
        (generated_dir / "graph_common_context.svh").write_text(
            generate_context_header(
                layout, layouts_by_id, scenarios, symbols, cu_contract, route_table, bins
            )
        )
        (generated_dir / "graph_package_oracle.svh").write_text(
            generate_package_oracle(
                layout, scenarios, symbols, cu_contract, wed_contract, wed_layout
            )
        )
        chain = package_chain(layout)
        context_state[layout] = {
            "symbols": symbols,
            "bins": bins,
            "chain": chain,
            "generated_dir": generated_dir,
        }
        for suite, definition in SUITES.items():
            if suite == "graph-package-contracts":
                dut_sources = [REPO_ROOT / entry_for(entries, name, layout)["path"]
                               for name in PACKAGE_DECLARATIONS]
                sources = list(chain)
            else:
                dut_sources = [
                    REPO_ROOT / entry_for(entries, name, layout)["path"]
                    for name in definition["declarations"]
                ]
                sources = list(chain) + dut_sources
            jobs.append(
                {
                    "kind": "production",
                    "layout": layout,
                    "suite": suite,
                    "top": definition["top"],
                    "tb": definition["tb"],
                    "sources": sources,
                    "dut_sources": dut_sources,
                    "generated_dir": generated_dir,
                    "build_dir": BUILD_ROOT / "production" / layout / suite,
                    "pass_prefix": definition["pass_prefix"],
                }
            )

    results = []
    with concurrent.futures.ThreadPoolExecutor(max_workers=arguments.jobs) as pool:
        futures = [pool.submit(compile_and_run, job, verilator, True) for job in jobs]
        for future in concurrent.futures.as_completed(futures):
            results.append(future.result())

    executions_run = []
    observed_coverage = {}
    observed_unreachable = {}
    coverage_failures = []
    total_checks = 0
    total_bins = 0
    for result in sorted(results, key=lambda item: (item["job"]["layout"], item["job"]["suite"])):
        job = result["job"]
        label = f"{job['layout']}/{job['suite']}"
        if result["returncode"]:
            fail(f"{label} failed during {result['stage']}\n{result['output']}")
        if job["pass_prefix"] not in result["output"]:
            fail(f"{label} did not report a pass line\n{result['output']}")
        match = re.search(r"checks=(\d+) bins=(\d+)/(\d+)", result["output"])
        if not match:
            fail(f"{label} did not report evidence\n{result['output']}")
        checks, bins_hit, bins_total = (int(value) for value in match.groups())
        if bins_hit != bins_total:
            fail(f"{label} covered {bins_hit} of {bins_total} functional bins")
        expected_bins = context_state[job["layout"]]["bins"][job["suite"]]
        if bins_total != expected_bins:
            fail(
                f"{label} reported {bins_total} functional bins, the manifest derived "
                f"denominator is {expected_bins}"
            )
        total_checks += checks
        total_bins += bins_total

        coverage_data = job["build_dir"] / "coverage.dat"
        if not coverage_data.is_file():
            fail(f"{label} produced no coverage data")
        points = parse_coverage(coverage_data, job["dut_sources"])
        if not points:
            fail(f"{label} produced no coverage point for the declarations under test")
        observed_coverage[label] = summarise_coverage(points)
        missing = unhit_points(points)
        observed_unreachable[label] = missing
        waived_entries = coverage_spec["unreachable"].get(label, [])
        for entry in waived_entries:
            if not entry.get("reason"):
                coverage_failures.append(
                    f"{label} declares the unreachable point {entry.get('point')} without a reason"
                )
        waived = [entry["point"] for entry in waived_entries]
        unexpected = [point for point in missing if point not in waived]
        if unexpected:
            coverage_failures.append(
                f"{label} left reachable coverage points unexercised: {unexpected}"
            )
        stale = [point for point in waived if point not in missing]
        if stale:
            coverage_failures.append(
                f"{label} declares unreachable coverage points that are exercised: {stale}"
            )
        executions_run.append(
            {
                "context": job["layout"],
                "suite": job["suite"],
                "declarations": [path.name for path in job["dut_sources"]],
                "checks": checks,
                "functional_bins": bins_total,
            }
        )

    if arguments.emit_baseline:
        Path(arguments.emit_baseline).write_text(
            json.dumps(
                {"denominators": observed_coverage, "unreachable": observed_unreachable},
                indent=2,
                sort_keys=True,
            )
            + "\n"
        )

    expected_coverage = coverage_spec["denominators"]
    if not arguments.only_context:
        if set(expected_coverage) != set(observed_coverage):
            coverage_failures.append(
                "coverage denominator table does not describe the executed suites: "
                f"{sorted(set(expected_coverage) ^ set(observed_coverage))}"
            )
    for label, observed in sorted(observed_coverage.items()):
        if label not in expected_coverage:
            coverage_failures.append(f"{label} has no pinned coverage denominator")
        elif observed != expected_coverage[label]:
            coverage_failures.append(
                f"{label} coverage denominator changed\nexpected={expected_coverage[label]}\n"
                f"observed={observed}"
            )
    if coverage_failures:
        fail("\n".join(coverage_failures))

    mutations_detected = []
    if not arguments.skip_mutations:
        mutation_jobs = build_mutation_jobs(entries, scenarios, selected, context_state)
        declared = sum(
            len(items) for items in scenarios["sensitivity"]["mutations"].values()
        )
        expected_mutations = declared_mutation_count(entries, scenarios, selected)
        if len(mutation_jobs) != expected_mutations:
            fail(
                f"prepared {len(mutation_jobs)} mutants, the sensitivity contract requires "
                f"{expected_mutations}"
            )
        mutation_results = []
        with concurrent.futures.ThreadPoolExecutor(max_workers=arguments.jobs) as pool:
            futures = [
                pool.submit(compile_and_run, job, verilator, False) for job in mutation_jobs
            ]
            for future in concurrent.futures.as_completed(futures):
                mutation_results.append(future.result())
        for result in sorted(
            mutation_results, key=lambda item: item["job"]["mutation"]
        ):
            job = result["job"]
            label = job["mutation"]
            if result["stage"] == "compile" and result["returncode"]:
                fail(f"mutant {label} did not compile\n{result['output']}")
            if result["returncode"] == 0:
                fail(f"mutant {label} was not detected")
            if job["diagnostic"] not in result["output"]:
                fail(
                    f"mutant {label} failed for the wrong reason, expected "
                    f"'{job['diagnostic']}'\n{result['output']}"
                )
            mutations_detected.append(label)
        if not partial and declared != len(
            {job["declaration_mutation"] for job in mutation_jobs}
        ):
            fail("the mutation catalogue and the executed mutants disagree")

    summary = {
        "schema_version": 1,
        "family_group": "graph-common",
        "plan_id": plan["plan_id"],
        "result": "partial" if partial else "pass",
        "contexts": selected,
        "declaration_context_executions": {
            "expected": executions,
            "executed": sum(
                len(execution["declarations"]) for execution in executions_run
            ),
        },
        "distinct_source_hashes": hashes,
        "simulator_builds": len(jobs),
        "checks": total_checks,
        "functional_bins": {"hit": total_bins, "total": total_bins, "percent": 100.0},
        "code_coverage": observed_coverage,
        "not_applicable": coverage_spec["not_applicable"],
        "unreachable": coverage_spec["unreachable"],
        "mutations_detected": sorted(mutations_detected),
        "executions": sorted(
            executions_run, key=lambda item: (item["context"], item["suite"])
        ),
        "reproduction": "03_capi_integration/accelerator_verification/rtl/unit/common/run_common.py",
    }
    (BUILD_ROOT / "summary.json").write_text(json.dumps(summary, indent=2) + "\n")

    executed_declarations = summary["declaration_context_executions"]["executed"]
    if not partial and executed_declarations != executions:
        fail(
            f"executed {executed_declarations} declaration contexts, the manifest requires "
            f"{executions}"
        )

    status = "PARTIAL" if partial else "PASS"
    if not partial:
        print("OWNERS:graph-package-contracts,routing-demux,sum-reduction")
    print(
        f"{status} graph_common_unit contexts={len(selected)}/{len(contexts)} "
        f"declaration_contexts={executed_declarations}/{executions} hashes={hashes} "
        f"builds={len(jobs)} checks={total_checks} bins={total_bins}/{total_bins} "
        f"mutants={len(mutations_detected)}"
    )
    return 1 if partial else 0


def declared_mutation_count(entries, scenarios, selected):
    catalogue = scenarios["sensitivity"]["mutations"]
    total = 0
    for declaration, items in catalogue.items():
        hashes = {
            entry["sha256"]
            for entry in entries
            if entry["declaration"] == declaration
            and any(context in selected for context in entry["contexts"])
        }
        total += len(hashes) * len(items)
    return total


def build_mutation_jobs(entries, scenarios, selected, context_state):
    catalogue = scenarios["sensitivity"]["mutations"]
    jobs = []
    for declaration, items in sorted(catalogue.items()):
        owned = [entry for entry in entries if entry["declaration"] == declaration]
        by_hash = {}
        for entry in owned:
            by_hash.setdefault(entry["sha256"], []).append(entry)
        for digest, group in sorted(by_hash.items()):
            representative = None
            for entry in group:
                for context in sorted(entry["contexts"]):
                    if context in selected:
                        representative = (entry, context)
                        break
                if representative:
                    break
            if representative is None:
                continue
            entry, context = representative
            suite = entry["suite"]
            definition = SUITES[suite]
            source_text = (REPO_ROOT / entry["path"]).read_text()
            for item in items:
                matches = re.findall(item["pattern"], source_text)
                if len(matches) != 1:
                    fail(
                        f"mutation {item['id']} matches {len(matches)} times in "
                        f"{entry['path']}; the anchor is no longer unique"
                    )
                mutated = re.sub(item["pattern"], item["replacement"], source_text)
                if mutated == source_text:
                    fail(f"mutation {item['id']} did not change {entry['path']}")
                label = f"{declaration}-{item['id']}-{digest[:8]}"
                mutation_root = BUILD_ROOT / "mutation" / label
                source_dir = mutation_root / "src"
                source_dir.mkdir(parents=True, exist_ok=True)
                mutated_path = source_dir / Path(entry["path"]).name
                mutated_path.write_text(mutated)
                state = context_state[context]
                if suite == "graph-package-contracts":
                    sources = list(state["chain"])
                else:
                    sources = list(state["chain"]) + [
                        REPO_ROOT / entry_for(entries, name, context)["path"]
                        for name in definition["declarations"]
                    ]
                original = REPO_ROOT / entry["path"]
                sources = [mutated_path if path == original else path for path in sources]
                if mutated_path not in sources:
                    fail(f"mutation {item['id']} did not replace {entry['path']} in the build")
                jobs.append(
                    {
                        "kind": "mutation",
                        "mutation": label,
                        "declaration_mutation": f"{declaration}:{item['id']}",
                        "layout": context,
                        "suite": suite,
                        "top": definition["top"],
                        "tb": definition["tb"],
                        "sources": sources,
                        "dut_sources": [mutated_path],
                        "generated_dir": state["generated_dir"],
                        "build_dir": mutation_root / "build",
                        "pass_prefix": definition["pass_prefix"],
                        "diagnostic": item["diagnostic"],
                    }
                )
    return jobs


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Failure as error:
        print(f"FAIL graph_common_unit {error}", file=sys.stderr)
        sys.exit(1)
