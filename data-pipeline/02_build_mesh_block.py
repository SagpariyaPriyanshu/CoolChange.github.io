#!/usr/bin/env python3
"""
Cool Change - Story 0.2
Joins D1 (heat + vegetation), D3 (census counts) and D4 (SEIFA) to mesh-block
level and writes the seed CSVs the database loads.

    python3 data-pipeline/02_build_mesh_block.py

Writes to backend/src/db/seeds/:
    mesh_block.csv         54,239 rows - the core table
    area_baseline.csv      precomputed comparisons, ALL and RESIDENTIAL scopes
    model_coefficient.csv  the fitted canopy/heat relationship

Every validation gate must pass or nothing is written.
"""
import os
import numpy as np
import pandas as pd

from _common import load_d1, load_d3, load_d4, SEEDS, EXPECTED_BLOCKS, Checks

# Benchmarks from Sun, Hurley, Amati et al. (2019), n = 55,603.
PUB_R, PUB_SLOPE = -0.585, -0.1274

MESH_BLOCK_COLUMNS = [
    "mb_code16", "sa1_code16", "sa2_code16", "sa2_name", "sa3_code16", "sa3_name",
    "lga_name", "uhi_mean", "canopy_pct", "grass_pct", "shrub_pct", "any_veg_pct",
    "shrub_tree_pct", "tree_03_10_pct", "tree_10_15_pct", "tree_15plus_pct",
    "mb_category", "dwellings", "persons", "area_sqkm", "irsd_score", "irsd_decile",
]


def build():
    print("Loading sources ...")
    d1, d3, d4 = load_d1(), load_d3(), load_d4()
    print(f"  D1 heat/vegetation : {len(d1):,} rows")
    print(f"  D3 census counts   : {len(d3):,} rows (all of Australia)")
    print(f"  D4 SEIFA SA1       : {len(d4):,} rows")

    print("\nJoining ...")
    df = d1.merge(d3, left_on="MB_CODE16", right_on="MB_CODE_2016", how="left", validate="1:1")
    print(f"  + D3 on MB_CODE16  : {df.MB_CATEGORY_NAME_2016.notna().sum():,} matched")
    df = df.merge(d4, left_on="SA1_MAIN16", right_on="SA1_11", how="left", validate="m:1")
    print(f"  + D4 on SA1_MAIN16 : {df.IRSD.notna().sum():,} matched "
          f"({df.IRSD.isna().sum():,} unmatched - expected, see below)")

    out = pd.DataFrame({
        "mb_code16": df.MB_CODE16,
        "sa1_code16": df.SA1_MAIN16,
        "sa2_code16": df.SA2_MAIN16,
        "sa2_name": df.SA2_NAME16,
        "sa3_code16": df.SA3_CODE16,
        "sa3_name": df.SA3_NAME16,
        "lga_name": df.LGA,
        "uhi_mean": df.UHI18_M.round(4),
        "canopy_pct": df.PERANYTREE.round(4),
        "grass_pct": df.PERGRASS.round(4),
        "shrub_pct": df.PERSHRUB.round(4),
        "any_veg_pct": df.PERANYVEG.round(4),
        "shrub_tree_pct": df.PERSHRBTRE.round(4),
        "tree_03_10_pct": df.PERTR03_10.round(4),
        "tree_10_15_pct": df.PERTR10_15.round(4),
        "tree_15plus_pct": df.PERTR15PL.round(4),
        "mb_category": df.MB_CATEGORY_NAME_2016,
        "dwellings": df.Dwelling.astype("Int64"),
        "persons": df.Person.astype("Int64"),
        # Albers area from the census file. NOT D1's Shape_Area, which arrives
        # in square DEGREES because the extract requests outSR=4326.
        "area_sqkm": df.AREA_ALBERS_SQKM.round(6),
        "irsd_score": df.IRSD.astype("Int64"),
        "irsd_decile": df.IRSD_dec.astype("Int64"),
    })[MESH_BLOCK_COLUMNS]

    # ---------------------------------------------------------------- gates
    print("\nValidation gates:")
    c = Checks()
    c.expect("row count", len(out), EXPECTED_BLOCKS)
    c.expect_true("mb_code16 unique", out.mb_code16.is_unique)
    c.expect_true("no nulls in uhi_mean / canopy_pct",
                  not out[["uhi_mean", "canopy_pct"]].isna().any().any())
    c.expect_true("no nulls in census columns",
                  not out[["mb_category", "dwellings", "persons", "area_sqkm"]].isna().any().any())
    # 1,477 = 1,345 blocks whose SA1 is absent from the SEIFA table entirely
    # (290 SA1s) + 132 blocks whose SA1 is listed but has its IRSD suppressed
    # as "-" (15 SA1s). Both are ABS confidentiality behaviour on very small
    # populations, not a broken join.
    c.expect("blocks with no usable SEIFA", int(out.irsd_score.isna().sum()), 1477)
    c.expect("total persons", int(out.persons.sum()), 4345097)
    c.expect("total dwellings", int(out.dwellings.sum()), 1779634)
    c.expect_true("all percentages within 0-100", bool(
        out[[col for col in out.columns if col.endswith("_pct")]]
        .apply(lambda s: s.between(0, 100)).all().all()))
    c.expect_true("area_sqkm strictly positive", bool((out.area_sqkm > 0).all()))

    # The SEIFA misses must be the ABS suppression story, not a broken join.
    miss = out[out.irsd_score.isna()]
    zero_pop_share = (miss.persons == 0).mean() * 100
    c.expect_true(f"SEIFA misses are mostly unpopulated blocks ({zero_pop_share:.1f}% have 0 residents)",
                  zero_pop_share > 80)

    # The relationship must reproduce the published study.
    r = float(np.corrcoef(out.canopy_pct, out.uhi_mean)[0, 1])
    slope, intercept = np.polyfit(out.canopy_pct, out.uhi_mean, 1)
    c.expect("Pearson r vs published -0.585", round(r, 4), PUB_R, tol=0.02)
    c.expect("OLS slope vs published -0.1274", round(float(slope), 4), PUB_SLOPE, tol=0.01)
    c.finish()

    os.makedirs(SEEDS, exist_ok=True)
    p = os.path.join(SEEDS, "mesh_block.csv")
    out.to_csv(p, index=False)
    print(f"\n  -> {p}  ({os.path.getsize(p)/1e6:.1f} MB)")

    write_model_coefficient(r, slope, intercept, len(out))
    write_area_baseline(out)
    return out


def write_model_coefficient(r, slope, intercept, n):
    rows = [{
        "model_type": "OLS_GLOBAL", "scope_type": "METRO", "scope_code": "METRO",
        "slope": round(float(slope), 6), "intercept": round(float(intercept), 6),
        "pearson_r": round(float(r), 6), "r_squared": round(float(r) ** 2, 6),
        "n_blocks": n, "is_active": "true",
        "notes": (f"Global OLS on all {n:,} blocks. Benchmark (Sun et al. 2019, "
                  f"n=55,603): slope -0.1274, r -0.585, R2 0.34. Association, "
                  f"not a controlled experiment."),
    }]
    p = os.path.join(SEEDS, "model_coefficient.csv")
    pd.DataFrame(rows).to_csv(p, index=False)
    print(f"  -> {p}")
    print(f"     slope {slope:.4f} degC per canopy point  "
          f"({slope*10:.3f} per 10 points), r {r:.4f}, R2 {r**2:.3f}")


def write_area_baseline(mbk):
    """Precomputed comparisons. Rebuild whenever mesh_block is rebuilt."""
    levels = [
        ("METRO", lambda d: pd.Series("METRO", index=d.index), lambda d: pd.Series("Metropolitan Melbourne", index=d.index)),
        ("LGA",   lambda d: d.lga_name,   lambda d: d.lga_name),
        ("SA3",   lambda d: d.sa3_code16, lambda d: d.sa3_name),
        ("SA2",   lambda d: d.sa2_code16, lambda d: d.sa2_name),
    ]
    frames = []
    for scope in ("ALL", "RESIDENTIAL"):
        src = mbk if scope == "ALL" else mbk[mbk.mb_category == "Residential"]
        for area_type, code_of, name_of in levels:
            d = src.assign(_code=code_of(src), _name=name_of(src))
            g = d.groupby("_code", sort=True)
            agg = g.agg(
                area_name=("_name", "first"),
                n_blocks=("uhi_mean", "size"),
                uhi_mean=("uhi_mean", "mean"),
                uhi_p10=("uhi_mean", lambda s: s.quantile(0.10)),
                uhi_p90=("uhi_mean", lambda s: s.quantile(0.90)),
                canopy_mean=("canopy_pct", "mean"),
                canopy_p10=("canopy_pct", lambda s: s.quantile(0.10)),
                canopy_p90=("canopy_pct", lambda s: s.quantile(0.90)),
            ).reset_index().rename(columns={"_code": "area_code"})

            coolest = d.loc[g.uhi_mean.idxmin(), ["_code", "mb_code16", "uhi_mean", "canopy_pct"]]
            coolest = coolest.rename(columns={
                "_code": "area_code", "mb_code16": "coolest_mb_code",
                "uhi_mean": "coolest_uhi", "canopy_pct": "coolest_canopy_pct"})
            agg = agg.merge(coolest, on="area_code")
            agg.insert(0, "area_type", area_type)
            agg.insert(3, "scope", scope)
            frames.append(agg)

    out = pd.concat(frames, ignore_index=True)
    for col in ("uhi_mean", "uhi_p10", "uhi_p90", "canopy_mean", "canopy_p10",
                "canopy_p90", "coolest_uhi", "coolest_canopy_pct"):
        out[col] = out[col].round(4)
    out = out[["area_type", "area_code", "area_name", "scope", "n_blocks",
               "uhi_mean", "uhi_p10", "uhi_p90", "canopy_mean", "canopy_p10",
               "canopy_p90", "coolest_mb_code", "coolest_uhi", "coolest_canopy_pct"]]

    assert out.n_blocks.min() > 0, "an area ended up with zero blocks"
    assert not out.duplicated(["area_type", "area_code", "scope"]).any(), "duplicate PK"

    p = os.path.join(SEEDS, "area_baseline.csv")
    out.to_csv(p, index=False)
    print(f"  -> {p}  ({len(out):,} rows: "
          + ", ".join(f"{k} {v}" for k, v in out.area_type.value_counts().items()) + ")")


if __name__ == "__main__":
    build()
    print("\nDone.")
