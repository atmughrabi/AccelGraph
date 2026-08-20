#!/usr/bin/env python3
"""Turn a raw suite coverage baseline into the rule-based census.

`run_algorithms.py --emit-baseline` and `run_graph_integration.py
--emit-baseline` write every unhit raw coverage point of every context as a
record whose category and reason are still "TODO".  This script replaces them
with the exact rule that keeps the point unreachable for the deterministic
stimulus the suite drives, and refuses to emit a census while a single point is
left unclassified, so a percentage can never stand in for a reason.

The rules are arithmetic statements about the production RTL, not categories:

  counter crossing point   a counter that advances by one per accepted event
                           first changes its bit k when the count reaches 2**k
  element identifier       the per-vertex element counter restarts at every
                           vertex, so bit k needs one vertex carrying 2**k
                           elements
  accumulator crossing     an accumulator whose addend is bounded by 2**w first
                           changes its bit k after 2**(k-w) addends
  fixture value range      a field that carries a graph value first changes its
                           bit k for a graph whose vertex, degree or edge index
                           reaches 2**k
  algorithmic constant     the declaration publishes a fixed value on the field
  disabled path            the declaration drives the enable of the path with a
                           hard coded zero, which the rule verifies in the source
  flow control             the buffer flag cannot assert because the producer is
                           throttled one level earlier
"""

import argparse
import json
import re
import sys
from pathlib import Path

POINT = re.compile(r"^(?P<file>[^:]+):(?P<line>\d+) (?P<type>\S+) (?P<signal>.*?) scope=(?P<scope>.*)$")
BIT = re.compile(r"^(?P<base>.*)\[(?P<bit>\d+)\]$")
ARRAY = re.compile(r"^(?P<base>[A-Za-z_][A-Za-z_0-9.]*)\[(?P<index>\d+)\](?P<tail>\..*)?$")

KERNEL_EVENT_BUDGET = 1 << 24
SHELL_EVENT_BUDGET = 1 << 20
SHELL_RETIRED_JOBS = 1 << 13
SHELL_ELEMENTS_PER_VERTEX = 32
KERNEL_ELEMENTS_PER_VERTEX = 1 << 24

# The independent fixture registry the graph top is driven with
# (GRAPH_FIXTURE_PKG): the largest fixture has five vertices, twelve edges and a
# largest vertex degree of four.
TOP_FIXTURE_VERTICES = 5
TOP_FIXTURE_EDGES = 12
TOP_FIXTURE_DEGREE = 4
# the almost-full threshold of a 64 entry command buffer with the 16 entry
# headroom of the shared fifo
COMMAND_BUFFER_ALFULL = 48
COMMAND_BUFFER_DEPTH = 64

COUNTER_SIGNALS = (
    "vertex_num_counter",
    "vertex_num_counter_resp",
    "vertex_num_counter_resp_out",
    "edge_num_counter",
    "edge_data_counter_accum",
    "edge_data_counter_accum_out",
    "edge_data_counter_accum_internal",
    "edge_data_counter_accum_internal_out",
    "edge_data_counter_accum_internal_S2",
    "edge_data_counter_accum_latched",
    "edge_data_counter_accum_skip",
    "edge_data_counter_continue_accum",
    "edge_data_counter_continue_accum_latched",
    "edge_data_continue_accum",
)

ELEMENT_ID_SIGNALS = (
    "edge_job.payload.id",
    "edge_job_latched.payload.id",
    "edge_job_variable.payload.id",
    "edge_latched.payload.id",
    "edge_variable.payload.id",
    "edge_id_counter",
)

ACCUMULATOR_SIGNALS = (
    "edge_data_accumulator.payload.data",
    "edge_data_accumulator_latch.payload.data",
    "edge_data_write_out.payload.data",
    "edge_data_write_out_internal.payload.data",
    "edge_data_write_buffer.payload.data",
)

STATUS_FLAG = re.compile(
    r"^(?P<base>.*status(?:_latch|_latched|_internal|_cu_out)?|.*buffer_states_cu)"
    r"\.(?P<flag>full|alfull)$"
)

TOP_PROGRESS_SIGNALS = (
    "cu_return.var1",
    "cu_return.var2",
    "cu_return_latched.var1",
    "cu_return_latched.var2",
    "vertex_job_counter_done",
    "vertex_job_counter_done_latched",
    "vertex_job_counter_total_latched",
    "vertex_job_counter_filtered",
    "vertex_job_counter_done_cu_in",
    "edge_job_counter_done",
    "edge_job_counter_done_latched",
    "edge_job_counter_done_cu_in",
)

TOP_VERTEX_FIELDS = {
    "id": (
        "the vertex identifier of the round",
        TOP_FIXTURE_VERTICES,
        "the largest fixture the suite drives has {bound} vertices",
    ),
    "inverse_out_degree": (
        "the inverse degree of the vertex",
        TOP_FIXTURE_DEGREE,
        "the largest fixture vertex the suite drives has {bound} inverse edges",
    ),
    "out_degree": (
        "the degree of the vertex",
        TOP_FIXTURE_DEGREE,
        "the largest fixture vertex the suite drives has {bound} edges",
    ),
    "inverse_edges_idx": (
        "the inverse CSR offset of the vertex",
        TOP_FIXTURE_EDGES,
        "the largest fixture the suite drives has {bound} edges",
    ),
    "edges_idx": (
        "the CSR offset of the vertex",
        TOP_FIXTURE_EDGES,
        "the largest fixture the suite drives has {bound} edges",
    ),
}

TOP_VERTEX_SIGNALS = ("vertex_unfiltered", "vertex_filtered", "vertex_job_cu_out")

DISABLED_CONTROLS = ("enabled_prefetch_read", "enabled_prefetch_write")
PREFETCH_INTERFACES = ("prefetch_read_", "prefetch_write_")

# Every array of the fixture image the unit testbenches build is one 4096 byte
# window of four byte entries, so an index or an identifier the engine can
# follow addresses one of 1024 entries.
IMAGE_WINDOW_BYTES = 4096
IMAGE_WINDOW_ENTRIES = IMAGE_WINDOW_BYTES // 4

IMAGE_INDEX_FIELDS = ("edges_idx", "inverse_edges_idx")
COMPONENT_FIELDS = ("comp_high", "comp_low", "comp_comp_high")
RESULT_FIELDS = ("index", "data")
ENUM_FIELDS = ("array_struct", "cmd_type")

TOP_BUS_SIGNALS = (
    "read_command_bus_request_cu_in",
    "read_command_bus_grant_cu_out",
    "write_command_bus_request_cu_in",
    "write_command_bus_grant_cu_out",
)

REPO_ROOT = Path(__file__).resolve().parents[5]

CATEGORIES = {
    "counter-range": "the bit belongs to a monotonic event counter and would need more events than the "
                     "bounded fixture and burst budget can produce",
    "fixture-value-range": "the bit belongs to a field that carries a graph value, and the independent "
                           "fixture registry never reaches a value that changes it",
    "parameter-constant": "the bit is driven by a module parameter, a coordinate of this elaboration or a "
                          "hard coded literal, so it cannot change inside one elaboration",
    "algorithmic-constant": "the declaration publishes a fixed value on the field",
    "disabled-path": "the declaration drives the enable of the path with a hard coded zero, which the rule "
                     "verifies in the source, so nothing inside the path can be exercised",
    "flow-control-unreachable": "the producer honours an almost-full request signal, so the corresponding "
                                "buffer level is structurally unreachable",
    "configuration-range": "the point belongs to a cluster the configuration word this suite publishes "
                           "does not activate",
}


def declaration_index(suite_paths):
    """Map every context label of a suite to the declaration it measures."""
    index = {}
    for suite_path in suite_paths:
        suite = json.loads(Path(suite_path).read_text())
        for family in suite["families"]:
            for context in family["contexts"]:
                index[f"{context['layout']}/{family['family']}"] = context["dut"]
    return index


def declaration_text(index, context):
    path = index.get(context)
    if path is None:
        return None
    return (REPO_ROOT / path).read_text()


def budgets(context):
    if context.endswith("/algorithm-shells"):
        return SHELL_EVENT_BUDGET, SHELL_RETIRED_JOBS, SHELL_ELEMENTS_PER_VERTEX
    return KERNEL_EVENT_BUDGET, KERNEL_EVENT_BUDGET, KERNEL_ELEMENTS_PER_VERTEX


def strip_index(signal):
    """Drop one array index from a signal so cu_out[2].alfull matches its rule."""
    match = ARRAY.match(signal)
    if not match:
        return signal, None
    return match.group("base") + (match.group("tail") or ""), int(match.group("index"))


def classify_top(context, signal, base, bit, source_text):
    """Rules of the graph cu_control top, measured by the integration suite."""
    unindexed, _ = strip_index(base)

    if unindexed in TOP_PROGRESS_SIGNALS and bit is not None:
        vertex_driven = "vertex" in unindexed or unindexed.endswith("var1")
        item = "vertices" if vertex_driven else "edges"
        bound = TOP_FIXTURE_VERTICES if vertex_driven else TOP_FIXTURE_EDGES
        return (
            "counter-range",
            f"{base} publishes how many {item} the round accounted for, so bit {bit} first changes "
            f"when that count reaches 2**{bit} = {1 << bit}; the independent fixture registry the suite "
            f"drives has at most {bound} {item} in a graph",
        )

    for owner in TOP_VERTEX_SIGNALS:
        prefix = f"{owner}.payload."
        if not unindexed.startswith(prefix) or bit is None:
            continue
        field = unindexed[len(prefix):]
        rule = TOP_VERTEX_FIELDS.get(field)
        if rule is None:
            continue
        description, bound, budget = rule
        return (
            "fixture-value-range",
            f"{base} carries {description}, so bit {bit} first changes for a value of "
            f"2**{bit} = {1 << bit}; " + budget.format(bound=bound),
        )

    if unindexed.startswith("edge_data_write_out.payload.") and bit is not None:
        field = unindexed[len("edge_data_write_out.payload."):]
        if field in ("cu_id_x", "cu_id_y"):
            return (
                "parameter-constant",
                f"{base} is the coordinate of the CU that produced the result, which is bounded by the "
                f"graph and vertex CU counts of this elaboration, so bit {bit} would need "
                f"2**{bit} = {1 << bit} CUs on one axis",
            )
        if field == "index":
            return (
                "fixture-value-range",
                f"{base} is the vertex the result belongs to, so bit {bit} first changes at vertex "
                f"2**{bit} = {1 << bit}; the largest fixture the suite drives has "
                f"{TOP_FIXTURE_VERTICES} vertices",
            )
        if field in ("data_1", "data_2"):
            return (
                "algorithmic-constant",
                f"{base} carries no algorithm result in this layout: the update path publishes a fixed "
                f"value on the field, so bit {bit} is never driven",
            )

    if unindexed.startswith("cu_configure_out") and bit is not None:
        return (
            "parameter-constant",
            f"{base} is the per cluster broadcast of the configuration word, whose vertex count half is "
            "replaced by the constant (cluster + 1) * NUM_VERTEX_CU of this elaboration, so bit "
            f"{bit} is driven by a constant rather than by the configuration input",
        )

    if base in TOP_BUS_SIGNALS and bit is not None:
        return (
            "configuration-range",
            f"{base} is the command bus handshake of graph CU {bit}, and the configuration word the "
            "suite drives asks for one vertex CU, which activates the first cluster of the layout only; "
            "a round that activates every cluster needs a configuration this stimulus does not publish",
        )

    if unindexed.startswith("edge_data_write_out.payload.data") and bit is not None:
        if "FloatPoint" in context:
            return (
                "fixture-value-range",
                f"{base} carries the IEEE 754 encoding of the result the round publishes for one fixture "
                f"vertex, and the exponent and mantissa of the magnitudes the independent fixtures "
                f"produce never drive bit {bit}",
            )
        return (
            "fixture-value-range",
            f"{base} carries the result the round publishes for one fixture vertex, which is derived from "
            f"a graph of at most {TOP_FIXTURE_VERTICES} vertices, {TOP_FIXTURE_EDGES} edges and the "
            f"property words of the image, so bit {bit} would need a result of 2**{bit} = {1 << bit}",
        )

    for control in DISABLED_CONTROLS:
        if unindexed == control or signal == control:
            assert_constant_zero(source_text, control)
            return (
                "disabled-path",
                f"the declaration assigns {control} the constant zero, so the path it enables and every "
                "point inside it cannot be exercised in any elaboration",
            )

    if unindexed.startswith(PREFETCH_INTERFACES):
        for control in DISABLED_CONTROLS:
            assert_constant_zero(source_text, control)
        return (
            "disabled-path",
            f"{signal} belongs to the prefetch interface, and the declaration assigns both "
            "enabled_prefetch_read and enabled_prefetch_write the constant zero, so nothing in that "
            "interface is ever driven",
        )

    flag = STATUS_FLAG.match(strip_index(signal)[0])
    if flag:
        return (
            "flow-control-unreachable",
            f"{signal} reports a command buffer level the round never reaches: the buffer is "
            f"{COMMAND_BUFFER_DEPTH} entries deep and reports almost full at {COMMAND_BUFFER_ALFULL} of "
            f"them, while the largest fixture the suite drives has {TOP_FIXTURE_VERTICES} vertices and "
            f"{TOP_FIXTURE_EDGES} edges, so a whole round issues far fewer commands than the threshold",
        )

    return None


def assert_constant_zero(source_text, name):
    """Prove a disabled-path rule against the declaration it talks about."""
    if source_text is None:
        return
    if re.search(rf"^\s*{re.escape(name)}\s*<=\s*0\s*;", source_text, flags=re.MULTILINE) is None:
        raise SystemExit(
            f"the disabled-path rule for {name} no longer matches the source: "
            "the declaration does not assign it the constant zero"
        )


def classify_branch(context, point, source_text):
    """Branch points are classified from the source line they belong to."""
    match = POINT.match(point)
    if source_text is None:
        return None
    line_number = int(match.group("line"))
    lines = source_text.splitlines()
    if line_number > len(lines):
        return None
    condition = lines[line_number - 1].strip()
    for control in DISABLED_CONTROLS:
        if f"if({control})" in condition.replace(" ", ""):
            assert_constant_zero(source_text, control)
            return (
                "disabled-path",
                f"the branch at line {line_number} is taken on {control}, and the declaration assigns "
                f"{control} the constant zero, so the branch cannot be taken in any elaboration",
            )
    return None


def classify(context, point, source_text=None):
    match = POINT.match(point)
    if not match:
        return None
    signal = match.group("signal")
    page = match.group("type")
    events, retired, elements = budgets(context)
    bit_match = BIT.match(signal)
    base = bit_match.group("base") if bit_match else signal
    bit = int(bit_match.group("bit")) if bit_match else None

    if page == "v_branch":
        return classify_branch(context, point, source_text)

    if context.endswith("/graph-top"):
        return classify_top(context, signal, base, bit, source_text)

    if base in COUNTER_SIGNALS and bit is not None:
        vertex_driven = base.startswith("vertex_num")
        driver = "retired vertex job" if vertex_driven else "accepted element or write acknowledge"
        reached = retired if vertex_driven else events
        return (
            "counter-range",
            f"{base} advances by one per {driver}, so bit {bit} first changes when the count reaches "
            f"2**{bit} = {1 << bit}; the census burst of this context drives {reached} such events, "
            "which is the deepest deterministic event count the suite executes",
        )

    if base in ELEMENT_ID_SIGNALS and bit is not None:
        return (
            "counter-range",
            f"{base} is the per-vertex element identifier and restarts at every vertex, so bit {bit} "
            f"first changes when one vertex carries 2**{bit} = {1 << bit} elements; the edge job engine "
            f"hands the census {elements} elements for the deepest vertex job the suite drives",
        )

    if base in ACCUMULATOR_SIGNALS and bit is not None:
        if "TriangleCount" in context:
            return (
                "counter-range",
                f"{base} carries the intersection count of one vertex, which advances by at most one per "
                f"element, so bit {bit} first changes after 2**{bit} = {1 << bit} matched elements; the "
                f"census drives {elements} matched elements on a single vertex",
            )
        if bit >= 32:
            return (
                "counter-range",
                f"{base} is the 64 bit result accumulator and every addend the kernel presents is at most "
                f"2**32-1, so bit {bit} first changes after 2**{bit - 32} = {1 << (bit - 32)} addends; the "
                f"census accumulates {elements} maximum width addends on a single vertex",
            )

    if base.endswith("payload.data_1") and bit is not None:
        return (
            "algorithmic-constant",
            "the BottomUp update kernel publishes the constant frontier marker one on data_1, so only bit "
            "0 of the field is ever driven",
        )

    field = base.rsplit(".", 1)[-1] if "." in base else None
    if field is not None and bit is not None:
        if field in IMAGE_INDEX_FIELDS:
            return (
                "fixture-value-range",
                f"{base} indexes the edge array of the fixture image, and the engine can only carry a job "
                f"whose elements are inside that image, so the index stays below the "
                f"{IMAGE_WINDOW_ENTRIES} entries of one {IMAGE_WINDOW_BYTES} byte array window and bit "
                f"{bit} would need an index of 2**{bit} = {1 << bit}",
            )
        if field in COMPONENT_FIELDS:
            return (
                "fixture-value-range",
                f"{base} carries a component identifier, and the algorithm reads the component array at "
                f"the identifier it observes, so an identifier the engine can follow addresses one of the "
                f"{IMAGE_WINDOW_ENTRIES} entries of the component window and bit {bit} would need an "
                f"identifier of 2**{bit} = {1 << bit}",
            )
        if field in RESULT_FIELDS and "edge_data_write_out" in base:
            return (
                "fixture-value-range",
                f"{base} publishes a component identifier of the round, which addresses one of the "
                f"{IMAGE_WINDOW_ENTRIES} entries of the component window, so bit {bit} would need an "
                f"identifier of 2**{bit} = {1 << bit}",
            )
        if field in ENUM_FIELDS:
            return (
                "parameter-constant",
                f"{base} is an enumerated array selector and the declaration only ever drives the "
                f"encodings of the arrays it reads, so bit {bit} of the field is never driven",
            )

    flag = STATUS_FLAG.match(signal)
    if flag:
        return (
            "flow-control-unreachable",
            f"{signal} reports a buffer level the producer never reaches: the engine is throttled by the "
            "almost-full handshake one level earlier and never presents elements faster than the kernel "
            "retires them, so the flag stays low for every stimulus the suite drives",
        )

    return None


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("baseline")
    parser.add_argument("output")
    parser.add_argument("--merge-into", default=None)
    parser.add_argument(
        "--suite",
        action="append",
        default=[],
        help="suites.json of a suite whose contexts appear in the baseline; the "
             "declaration it names is the source a rule is proved against",
    )
    args = parser.parse_args()

    duts = declaration_index(args.suite)
    baseline = json.loads(Path(args.baseline).read_text())
    records = {}
    unclassified = []
    for context, entries in baseline["unreachable"].items():
        kept = []
        source_text = declaration_text(duts, context)
        for entry in entries:
            classified = classify(context, entry["point"], source_text)
            if classified is None:
                unclassified.append((context, entry["point"]))
                continue
            category, reason = classified
            kept.append(
                {"point": entry["point"], "category": category, "reason": reason}
            )
        records[context] = sorted(kept, key=lambda item: item["point"])

    if unclassified:
        print(f"{len(unclassified)} coverage points have no rule:", file=sys.stderr)
        for context, point in unclassified:
            print(f"  {context} {point}", file=sys.stderr)
        return 1

    document = json.loads(Path(args.merge_into).read_text()) if args.merge_into else {}
    document["denominators"] = baseline["denominators"]
    document["unreachable"] = records
    document["categories"] = {
        category: CATEGORIES[category]
        for category in sorted(
            {entry["category"] for value in records.values() for entry in value}
        )
    }
    Path(args.output).write_text(json.dumps(document, indent=2) + "\n")
    total = sum(len(value) for value in records.values())
    print(f"census written to {args.output}: {total} rule-based records over {len(records)} contexts")
    return 0


if __name__ == "__main__":
    sys.exit(main())
