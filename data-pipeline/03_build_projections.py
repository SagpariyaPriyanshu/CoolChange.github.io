#!/usr/bin/env python3
"""
Cool Change - Story 0.2
Spatial join: which projected "days >= 35 C" band does each mesh block fall in,
at each global warming level?

    python3 data-pipeline/03_build_projections.py            # both stages
    python3 data-pipeline/03_build_projections.py centroids  # stage 1 only
    python3 data-pipeline/03_build_projections.py join       # stage 2 only

Stage 1 parses the 34 MB polygon file once and caches a representative point
per mesh block, because that parse is the slow part.
Stage 2 does the point-in-polygon lookup against the ACS bands.

Writes backend/src/db/seeds/mesh_block_projection.csv

A mesh block with NO ROW in the output falls outside every ACS polygon. That is
US3.2.5 and it is expected for coastal blocks -- the API falls back to the
city-wide figure in projection_metro.
"""
import json
import os
import sys

import pandas as pd
from shapely.geometry import shape, Point
from shapely.strtree import STRtree

from _common import raw, GEOM, D2, SEEDS, CACHE, EXPECTED_BLOCKS

CENTROIDS = os.path.join(CACHE, "mesh_block_points.csv")

# Agreed mapping of warming level to the horizon we present.
HORIZON = {1.2: "Today", 1.5: "2030", 2.0: "2050", 3.0: "2050 high warming"}
STATISTIC = "50.0"          # median of the model ensemble; a STRING in the source


def stage_centroids():
    if os.path.exists(CENTROIDS):
        print(f"[1/2] cached: {CENTROIDS}")
        return
    print("[1/2] Parsing mesh block polygons (34 MB, slow, runs once) ...")
    with open(raw(GEOM)) as f:
        gj = json.load(f)
    rows = []
    for feat in gj["features"]:
        code = feat["properties"]["MB_CODE16"]
        # representative_point() is guaranteed to sit INSIDE the polygon;
        # a centroid can fall outside a concave or multi-part block.
        p = shape(feat["geometry"]).representative_point()
        rows.append((str(code), round(p.x, 6), round(p.y, 6)))
    os.makedirs(CACHE, exist_ok=True)
    df = pd.DataFrame(rows, columns=["mb_code16", "lon", "lat"])
    df.to_csv(CENTROIDS, index=False)
    print(f"      {len(df):,} points -> {CENTROIDS}")


def stage_join():
    pts = pd.read_csv(CENTROIDS, dtype={"mb_code16": str})
    print(f"[2/2] {len(pts):,} mesh block points loaded")

    with open(raw(D2)) as f:
        acs = json.load(f)["features"]

    bands = {}
    for feat in acs:
        p = feat["properties"]
        if p["variable"] != "txge35" or str(p["statistic"]) != STATISTIC:
            continue
        lvl = float(p["dimension"])
        label = p["label"]
        lower = int(p["value"])
        upper = None
        if "-" in label:
            upper = int(label.split("-")[1])
        bands.setdefault(lvl, []).append((shape(feat["geometry"]), label, lower, upper))

    print("      ACS polygons per warming level: "
          + ", ".join(f"{k}={len(v)}" for k, v in sorted(bands.items())))

    points = [Point(xy) for xy in zip(pts.lon, pts.lat)]
    out = []
    for lvl in sorted(bands):
        geoms = [b[0] for b in bands[lvl]]
        tree = STRtree(geoms)
        hits = 0
        for i, pt in enumerate(points):
            for j in tree.query(pt):
                if geoms[j].contains(pt):
                    _, label, lower, upper = bands[lvl][j]
                    out.append((pts.mb_code16.iat[i], lvl, label, lower, upper))
                    hits += 1
                    break
        outside = len(points) - hits
        print(f"      level {lvl}: {hits:,} matched, {outside:,} outside every polygon")

    df = pd.DataFrame(out, columns=["mb_code16", "warming_level",
                                    "days_label", "days_lower", "days_upper"])
    df["days_upper"] = df.days_upper.astype("Int64")

    print("\n      band distribution (this is the finding for the front end):")
    for lvl in sorted(df.warming_level.unique()):
        vc = df[df.warming_level == lvl].days_label.value_counts()
        print(f"        {lvl} ({HORIZON[lvl]}): "
              + ", ".join(f"{k} x{v:,}" for k, v in vc.items()))

    assert df.mb_code16.nunique() <= EXPECTED_BLOCKS
    assert not df.duplicated(["mb_code16", "warming_level"]).any(), "duplicate PK"

    os.makedirs(SEEDS, exist_ok=True)
    p = os.path.join(SEEDS, "mesh_block_projection.csv")
    df.to_csv(p, index=False)
    print(f"\n      -> {p}  ({len(df):,} rows, {os.path.getsize(p)/1e6:.1f} MB)")

    missing = EXPECTED_BLOCKS - df.mb_code16.nunique()
    if missing:
        print(f"      {missing:,} blocks have no projection row at all -> US3.2.5 "
              f"fallback to projection_metro.")


if __name__ == "__main__":
    stage = sys.argv[1] if len(sys.argv) > 1 else "all"
    if stage in ("centroids", "all"):
        stage_centroids()
    if stage in ("join", "all"):
        stage_join()
    print("Done.")
