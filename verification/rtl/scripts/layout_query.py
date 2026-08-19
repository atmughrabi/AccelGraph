#!/usr/bin/env python3

import argparse
import json
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[3]
LAYOUTS_PATH = REPO_ROOT / "verification/rtl/manifests/layouts.json"


def main():
    parser = argparse.ArgumentParser(description="Query an AccelGraph RTL layout")
    parser.add_argument("--active-ids", action="store_true")
    parser.add_argument("--active-layouts", action="store_true")
    parser.add_argument(
        "--field",
        default="id",
        choices=("id", "total_vertex_cus"),
    )
    parser.add_argument("layout", nargs="*")
    args = parser.parse_args()

    layouts = json.loads(LAYOUTS_PATH.read_text())["layouts"]
    if args.active_ids or args.active_layouts:
        if args.layout:
            parser.error("active layout queries do not accept layout fields")
        for layout in layouts:
            if layout["status"] == "active":
                if args.active_ids:
                    print(layout["id"])
                else:
                    print(
                        layout["algorithm"],
                        layout["data_structure"],
                        layout["direction"],
                        layout["precision"],
                    )
        return

    if len(args.layout) != 4:
        parser.error(
            "expected ALGORITHM DATA_STRUCTURE DIRECTION PRECISION"
        )
    keys = ("algorithm", "data_structure", "direction", "precision")
    requested = dict(zip(keys, args.layout))
    matches = [
        layout
        for layout in layouts
        if all(layout[key] == value for key, value in requested.items())
    ]
    if len(matches) != 1:
        parser.error("layout is missing or ambiguous")
    if matches[0]["status"] != "active":
        parser.error("layout is quarantined")
    print(matches[0][args.field])


if __name__ == "__main__":
    main()
