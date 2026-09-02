#!/usr/bin/env python3
"""
Cool Change - builds the static bundle the front end loads directly.

    python3 data-pipeline/04_build_frontend_bundle.py

This exists so the front end can build the whole map -- See, Understand and
Simulate -- WITHOUT the database or the API being ready. The shapes here match
the API contract exactly, so swapping fetch("/data/x.json") for
fetch("/api/v1/x") later is a one-line change per call, not a rewrite.

The output is deliberately NOT committed: it is 24 MB of derived data that
this script regenerates from the seed files in one command. It is gitignored,
and delivered to the front end as a bundle.

Writes to frontend/public/data/:
    bootstrap.json     the colour scale, the fitted model, the 2050 bands
    meshblocks.json    the choropleth payload (array-of-arrays)
    areas.json         precomputed comparisons for the detail panel
    meshblocks.geojson copied in separately -- see the README

Geometry is NOT generated here. Produce it once with mapshaper:

    npx mapshaper "<raw>/meshblocks.geojson" \
        -filter-fields MB_CODE16 -simplify 8% keep-shapes \
        -o precision=0.00001 format=geojson frontend/public/data/meshblocks.geojson
"""
import csv
import json
import os

from _common import SEEDS, REPO, EXPECTED_BLOCKS

OUT = os.path.join(REPO, "frontend", "public", "data")


def read(name):
    with open(os.path.join(SEEDS, name), newline="") as f:
        return list(csv.DictReader(f))


def num(v):
    return None if v == "" else float(v)


def build_bootstrap():
    model = read("model_coefficient.csv")[0]
    return {
        "data_vintage": 2018,
        "n_blocks": EXPECTED_BLOCKS,
        "uhi_units": "°C above non-urban baseline",
        "scale": {"uhi_min": -8.0, "uhi_max": 17.0, "canopy_max": 80.0},
        "model": {
            "model_type": model["model_type"],
            "scope": "METRO",
            "slope": round(float(model["slope"]), 4),
            "intercept": round(float(model["intercept"]), 4),
            "pearson_r": round(float(model["pearson_r"]), 4),
            "r_squared": round(float(model["r_squared"]), 3),
            "n_blocks": int(model["n_blocks"]),
            "interpretation": (
                "Each 10 percentage points of extra canopy is associated with "
                "about 1.23 °C less summer surface heat."
            ),
        },
        # Metro-wide modal band per warming level. Per-block bands vary; the
        # variation is coarse (3-4 classes), so render banded classes.
        "projections": [
            {"warming_level": 1.2, "horizon_label": "Today",
             "days_label": "5-10", "days_lower": 5, "days_upper": 10},
            {"warming_level": 1.5, "horizon_label": "2030",
             "days_label": "10-15", "days_lower": 10, "days_upper": 15},
            {"warming_level": 2.0, "horizon_label": "2050",
             "days_label": "10-15", "days_lower": 10, "days_upper": 15},
            {"warming_level": 3.0, "horizon_label": "2050 high warming",
             "days_label": "15+", "days_lower": 15, "days_upper": None},
        ],
        "_note": (
            "Static development bundle generated from the seed data. Field "
            "shapes match the API contract. Replace with GET /api/v1/... "
            "once the API is live."
        ),
    }


def build_meshblocks(rows):
    """Array-of-arrays, exactly as API_CONTRACT.md section 2 specifies.

    At 54,239 rows, repeating three key names per row roughly triples the
    payload for no benefit, so `fields` names the positions instead.
    """
    return {
        "count": len(rows),
        "fields": ["mb_code16", "uhi_mean", "canopy_pct"],
        "rows": [[r["mb_code16"], round(float(r["uhi_mean"]), 2),
                  round(float(r["canopy_pct"]), 2)] for r in rows],
    }


def build_detail_index(rows):
    """Everything the block detail panel needs, keyed by mesh block code.

    Kept separate from the choropleth payload so the map's first paint does not
    have to wait for fields it does not draw with.
    """
    fields = ["sa2_name", "sa3_name", "lga_name", "uhi_mean", "canopy_pct",
              "grass_pct", "shrub_pct", "any_veg_pct", "tree_03_10_pct",
              "tree_10_15_pct", "tree_15plus_pct", "mb_category", "dwellings",
              "persons", "area_sqkm", "irsd_score", "irsd_decile"]
    text = {"sa2_name", "sa3_name", "lga_name", "mb_category"}
    ints = {"dwellings", "persons", "irsd_score", "irsd_decile"}

    def val(r, f):
        if f in text:
            return r[f]
        if r[f] == "":
            return None                      # SEIFA absent -- render nothing, never 0
        if f in ints:
            return int(float(r[f]))
        # area_sqkm needs more places: a small block is 0.0388 km2, and
        # rounding to 2 would flatten it to 0.04.
        return round(float(r[f]), 4 if f == "area_sqkm" else 2)

    return {
        "fields": fields,
        "blocks": {r["mb_code16"]: [val(r, f) for f in fields] for r in rows},
    }


def build_areas():
    out = {}
    for r in read("area_baseline.csv"):
        out.setdefault(r["scope"], {}).setdefault(r["area_type"], {})[r["area_code"]] = {
            "area_name": r["area_name"],
            "n_blocks": int(r["n_blocks"]),
            "uhi_mean": round(float(r["uhi_mean"]), 2),
            "uhi_p10": round(float(r["uhi_p10"]), 2),
            "uhi_p90": round(float(r["uhi_p90"]), 2),
            "canopy_mean": round(float(r["canopy_pct"] if "canopy_pct" in r else r["canopy_mean"]), 2),
            "canopy_p10": round(float(r["canopy_p10"]), 2),
            "canopy_p90": round(float(r["canopy_p90"]), 2),
            "coolest": {
                "mb_code16": r["coolest_mb_code"],
                "uhi_mean": round(float(r["coolest_uhi"]), 2),
                "canopy_pct": round(float(r["coolest_canopy_pct"]), 2),
            },
        }
    return out


def main():
    os.makedirs(OUT, exist_ok=True)
    rows = read("mesh_block.csv")
    assert len(rows) == EXPECTED_BLOCKS, f"expected {EXPECTED_BLOCKS}, got {len(rows)}"

    for name, payload in [
        ("bootstrap.json", build_bootstrap()),
        ("meshblocks.json", build_meshblocks(rows)),
        ("meshblock-detail.json", build_detail_index(rows)),
        ("areas.json", build_areas()),
    ]:
        p = os.path.join(OUT, name)
        with open(p, "w") as f:
            json.dump(payload, f, separators=(",", ":"), ensure_ascii=False)
        print(f"  {name:<26} {os.path.getsize(p)/1e6:>6.1f} MB")

    print("\nWritten to frontend/public/data/. Geometry is produced separately "
          "with mapshaper -- see the docstring at the top of this file.")


if __name__ == "__main__":
    main()
