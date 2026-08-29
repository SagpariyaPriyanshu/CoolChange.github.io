# Cool Change — data pipeline

Turns four public datasets into the CSVs the database loads. Owned by Yu.

## Why this exists

The API is a **read layer**. It never aggregates, never fits a model and never
joins at request time. Everything expensive happens here, offline, and the
result is a static table the database serves.

## Raw data

Raw files are **not committed** — about 140 MB. They live outside the repo:

```
~/Documents/FIT5120/Iteration 1/data/raw/
```

Override with `COOLCHANGE_RAW=/path/to/raw`. To fetch them from the original
sources:

```bash
python3 data-pipeline/download_data.py --geometry
```

| Code | Dataset | Licence |
|---|---|---|
| D1 | Metropolitan Melbourne Urban Heat Islands and Urban Vegetation 2018 (DTP Victoria) — heat AND vegetation on the same mesh blocks | CC BY 4.0 |
| D2 | ACS Temperature extremes, days per year ≥ 35 °C, by global warming level | CC BY 4.0 |
| D3 | ABS 2016 Census Mesh Block Counts (cat. 2074.0) | CC BY 4.0 |
| D4 | ABS SEIFA 2016, SA1 indexes (cat. 2033.0.55.001) | CC BY 4.0 |

## Running it

```bash
pip3 install pandas numpy shapely xlrd
python3 data-pipeline/01_block_count_check.py      # why n = 54,239, not 55,603
python3 data-pipeline/02_build_mesh_block.py       # D1 + D3 + D4  -> 3 CSVs
python3 data-pipeline/03_build_projections.py      # D2 spatial join -> 1 CSV
```

Then load into the database:

```bash
cd backend && npm run db:up && npm run migrate
cd src/db/seeds && psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f load_seeds.sql
```

## Outputs

| File | Rows | What |
|---|---|---|
| `mesh_block.csv` | 54,239 | the core table |
| `mesh_block_projection.csv` | 204,532 | per-block heat bands, 4 warming levels |
| `area_baseline.csv` | 744 | precomputed comparisons, ALL and RESIDENTIAL |
| `model_coefficient.csv` | 1 | the fitted canopy/heat relationship |

## Validation

`02_build_mesh_block.py` refuses to write anything unless every gate passes:

- 54,239 rows, `mb_code16` unique, no nulls in heat or canopy
- exactly 1,477 blocks without SEIFA — **0 would mean nulls were silently filled**
- 4,345,097 persons and 1,779,634 dwellings
- Pearson r within 0.02 of the published −0.585
- OLS slope within 0.01 of the published −0.1274

`load_seeds.sql` re-asserts the same facts inside the load transaction, so a bad
load aborts instead of half-applying.

## Traps we already hit

- **D3 is latin-1**, not utf-8, and its last five rows are ABS footer text that
  parse as rows with a null code. Left in, they look like duplicate keys.
- **D3's footer also says small Dwelling and Person counts are randomly
  adjusted** by the ABS for confidentiality. Block-level population is
  approximate by design. This belongs in the limitations panel.
- **D4 uses `-` for suppressed values.** Read naively they become the string
  `"-"` and silently pass a not-null check.
- **Do not use D1's `Shape_Area`.** It arrives in square degrees because the
  extract requests `outSR=4326`. Use D3's `AREA_ALBERS_SQKM`.
- **Do not use the standalone "Vegetation Cover 2018" product.** Its geometry is
  mesh blocks subdivided by road casement polygons, so `MB_CODE16` is not
  unique and a naive join fans out rows. The vegetation fields are already
  inside the heat file.
- **Parsing the 34 MB polygon file is the slow step**, so `03_` caches a
  representative point per block in `.cache/` (gitignored).

## Documents

| Doc | What |
|---|---|
| `../docs/BLOCK_COUNT_DISCREPANCY.md` | why 54,239 and not 55,603 |
| `../docs/DATA_PROCESSING_PLAN.md` | the join approach, decisions, provenance |
| `../docs/API_CONTRACT.md` | response shapes for FE and BE |
| `../backend/src/db/migrations/002_create_schema.sql` | the schema, heavily commented |
| `../backend/src/db/queries.sql` | verified SQL behind each endpoint |
