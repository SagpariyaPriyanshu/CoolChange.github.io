#!/usr/bin/env python3
"""Generate CoolChange API response guide PDF."""

from reportlab.lib.colors import Color, HexColor, white, black
from reportlab.lib.enums import TA_LEFT, TA_CENTER, TA_RIGHT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import (
    SimpleDocTemplate,
    Paragraph,
    Spacer,
    Table,
    TableStyle,
    Preformatted,
    PageBreak,
    KeepTogether,
    HRFlowable,
    ListFlowable,
    ListItem,
)

FONT = "/Library/Fonts/Arial Unicode.ttf"
pdfmetrics.registerFont(TTFont("Body", FONT))

NAVY = HexColor("#1B3A4B")
TEAL = HexColor("#2A6F7F")
SAND = HexColor("#F4F1EA")
RULE = HexColor("#D4CFC0")
INK = HexColor("#1F2933")
MUTED = HexColor("#5B6770")
CODE_BG = HexColor("#F7F3EC")
ROW_ALT = HexColor("#F8F6F1")
WARN = HexColor("#8A4B2F")

OUT = "/Users/type/Downloads/CoolChange_API_Response_Guide_EN.pdf"


def styles():
    s = getSampleStyleSheet()
    s.add(ParagraphStyle(
        "CoverKicker", fontName="Body", fontSize=9, textColor=TEAL,
        tracking=1.2, spaceAfter=8, alignment=TA_LEFT,
    ))
    s.add(ParagraphStyle(
        "CoverTitle", fontName="Body", fontSize=22, leading=28,
        textColor=NAVY, spaceAfter=6,
    ))
    s.add(ParagraphStyle(
        "CoverSub", fontName="Body", fontSize=11, leading=16,
        textColor=MUTED, spaceAfter=4,
    ))
    s.add(ParagraphStyle(
        "H1", fontName="Body", fontSize=14, leading=18,
        textColor=NAVY, spaceBefore=16, spaceAfter=8,
    ))
    s.add(ParagraphStyle(
        "H2", fontName="Body", fontSize=11.5, leading=15,
        textColor=TEAL, spaceBefore=12, spaceAfter=6,
    ))
    s.add(ParagraphStyle(
        "BodyText2", fontName="Body", fontSize=9.5, leading=14,
        textColor=INK, spaceAfter=6,
    ))
    s.add(ParagraphStyle(
        "BulletBody", fontName="Body", fontSize=9.5, leading=14,
        textColor=INK, leftIndent=12, spaceAfter=3,
    ))
    s.add(ParagraphStyle(
        "Caption", fontName="Body", fontSize=8, leading=12,
        textColor=MUTED, spaceAfter=8, spaceBefore=2,
    ))
    s.add(ParagraphStyle(
        "CodeBlock", fontName="Courier", fontSize=7.2, leading=10,
        textColor=INK, backColor=CODE_BG, leftIndent=6, rightIndent=6,
        spaceBefore=4, spaceAfter=8,
    ))
    s.add(ParagraphStyle(
        "Th", fontName="Body", fontSize=8, leading=11, textColor=white,
    ))
    s.add(ParagraphStyle(
        "Td", fontName="Body", fontSize=8, leading=11.5, textColor=INK,
    ))
    s.add(ParagraphStyle(
        "TdMuted", fontName="Body", fontSize=8, leading=11.5, textColor=MUTED,
    ))
    s.add(ParagraphStyle(
        "Footer", fontName="Body", fontSize=7.5, textColor=MUTED,
        alignment=TA_LEFT,
    ))
    s.add(ParagraphStyle(
        "Callout", fontName="Body", fontSize=9, leading=13.5,
        textColor=NAVY, leftIndent=8, rightIndent=8, spaceBefore=4, spaceAfter=8,
    ))
    return s


S = styles()


def P(text, style="BodyText2"):
    return Paragraph(text, S[style])


def bullet(items):
    out = []
    for item in items:
        out.append(Paragraph("•  " + item, S["BulletBody"]))
    return out


def code_block(text):
    return Preformatted(text.strip("\n"), S["CodeBlock"])


def table(headers, rows, col_widths):
    head = [Paragraph(h, S["Th"]) for h in headers]
    body = []
    for row in rows:
        body.append([Paragraph(c, S["Td"]) for c in row])
    data = [head] + body
    t = Table(data, colWidths=col_widths, repeatRows=1)
    cmds = [
        ("BACKGROUND", (0, 0), (-1, 0), NAVY),
        ("TEXTCOLOR", (0, 0), (-1, 0), white),
        ("FONTNAME", (0, 0), (-1, -1), "Body"),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("LEFTPADDING", (0, 0), (-1, -1), 6),
        ("RIGHTPADDING", (0, 0), (-1, -1), 6),
        ("TOPPADDING", (0, 0), (-1, -1), 5),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
        ("GRID", (0, 0), (-1, -1), 0.3, RULE),
        ("BACKGROUND", (0, 1), (-1, -1), white),
    ]
    for i in range(1, len(data)):
        if i % 2 == 0:
            cmds.append(("BACKGROUND", (0, i), (-1, i), ROW_ALT))
    t.setStyle(TableStyle(cmds))
    return t


def header_footer(canvas, doc):
    canvas.saveState()
    w, h = A4
    canvas.setFillColor(NAVY)
    canvas.rect(0, h - 12 * mm, w, 12 * mm, fill=1, stroke=0)
    canvas.setFillColor(white)
    canvas.setFont("Body", 8)
    canvas.drawString(18 * mm, h - 7.5 * mm, "Cool Change  ·  Story 0.3  ·  API Response Guide")
    canvas.drawRightString(w - 18 * mm, h - 7.5 * mm, "FOXES EAT IT")
    canvas.setFillColor(SAND)
    canvas.rect(0, 0, w, 12 * mm, fill=1, stroke=0)
    canvas.setFillColor(MUTED)
    canvas.setFont("Body", 8)
    canvas.drawString(18 * mm, 5 * mm, "How to create API responses  ·  30 Aug 2026")
    canvas.drawRightString(w - 18 * mm, 5 * mm, str(doc.page))
    canvas.restoreState()


def cover_header_footer(canvas, doc):
    canvas.saveState()
    w, h = A4
    canvas.setFillColor(NAVY)
    canvas.rect(0, h - 48 * mm, w, 48 * mm, fill=1, stroke=0)
    canvas.setFillColor(TEAL)
    canvas.rect(0, h - 51 * mm, w, 3 * mm, fill=1, stroke=0)
    canvas.setFillColor(white)
    canvas.setFont("Body", 9)
    canvas.drawString(22 * mm, h - 18 * mm, "COOL CHANGE  ·  ITERATION 1")
    canvas.setFont("Body", 20)
    canvas.drawString(22 * mm, h - 30 * mm, "How to Create API Responses")
    canvas.setFont("Body", 11)
    canvas.drawString(22 * mm, h - 40 * mm, "Story 0.3  ·  Read-only API contract for Yipu (backend) and Sheng (frontend)")
    canvas.setFillColor(SAND)
    canvas.rect(0, 0, w, 14 * mm, fill=1, stroke=0)
    canvas.setFillColor(MUTED)
    canvas.setFont("Body", 8)
    canvas.drawString(22 * mm, 6 * mm, "FOXES EAT IT  ·  30 August 2026  ·  Internal working spec")
    canvas.restoreState()


def build():
    W = 174 * mm
    story = []

    story.append(Spacer(1, 42 * mm))
    story.append(P(
        "There is no standalone <font color='#2A6F7F'>API_CONTRACT.md</font> in the repo. "
        "Yu shipped two partial artefacts: <font name='Courier' size='8'>queries.sql</font> (what to query) "
        "and <font name='Courier' size='8'>04_build_frontend_bundle.py</font> (the static JSON Sheng consumes first). "
        "Those two shapes do not match. This document unifies them into one implementable response contract: "
        "<b>JSON in this spec is the source of truth; SQL comes from Yu’s queries.sql</b>.",
        "BodyText2",
    ))
    story.append(P(
        "Readers: Yipu (implements the API) · Sheng (wires the frontend) · Yu (checks fields match the database row).",
        "Caption",
    ))

    story.append(P("0. What exists and what is missing", "H1"))
    story.append(table(
        ["Source", "What it has", "What it lacks"],
        [
            ["queries.sql", "SQL for each endpoint (pg $1 parameters)", "Not HTTP JSON; detail split into 4 queries"],
            ["04_build_frontend_bundle.py", "Static JSON for bootstrap / meshblocks / areas", "No /search; detail is a 50k-row index"],
            ["src/routes/api.js", "Scaffold placeholder only", "No /api/v1 routes yet"],
            ["API_CONTRACT.md", "Mentioned in schema comments", "File is not in git"],
        ],
        [38 * mm, 68 * mm, 68 * mm],
    ))

    story.append(P("1. How to create an API response", "H1"))
    story.append(P(
        "Every endpoint follows the same steps. Do not dump database rows with <font name='Courier' size='8'>res.json(rows)</font>.",
    ))
    steps = [
        "<b>Pick the route</b> — use only the paths listed below. Prefix is always <font name='Courier' size='8'>/api/v1</font>.",
        "<b>Run Yu’s SQL</b> — copy queries from <font name='Courier' size='8'>backend/src/db/queries.sql</font>, with pg <font name='Courier' size='8'>$1</font> parameters. At request time do not JOIN extra tables, aggregate, or fit a model.",
        "<b>Shape the contract JSON</b> — lists are array-of-arrays; detail and comparisons are objects. Field names, nesting, and null semantics must match the examples here.",
        "<b>Set flags on the server</b> — zero population, null SEIFA, projection fallback, already-coolest block. Return booleans; do not make the frontend guess.",
        "<b>Never return geometry</b> — the frontend loads static GeoJSON and joins on <font name='Courier' size='8'>mb_code16</font>.",
        "<b>Use one error envelope</b> — see section 3. Do not mix string errors and object errors across routes.",
    ]
    story.extend(bullet(steps))

    story.append(P("Why lists are not arrays of objects", "H2"))
    story.append(P(
        "There are 54,239 city-wide rows. Repeating the keys <font name='Courier' size='8'>mb_code16 / uhi_mean / canopy_pct</font> on every row roughly triples the payload. "
        "The contract names columns once in <font name='Courier' size='8'>fields</font> and puts values only in <font name='Courier' size='8'>rows</font>. "
        "Sheng’s static bundle already uses this shape, so after the API matches it the frontend swap is "
        "<font name='Courier' size='8'>fetch('/data/meshblocks.json')</font> → "
        "<font name='Courier' size='8'>fetch('/api/v1/meshblocks')</font>."
    ))

    story.append(P("2. Principles (apply on every route)", "H1"))
    story.extend(bullet([
        "The API is a <b>read layer</b>. Expensive work is finished offline in Yu’s pipeline.",
        "<font name='Courier' size='8'>uhi_mean</font> is a deviation from the non-urban baseline (°C), not an absolute temperature.",
        "The colour scale comes from <font name='Courier' size='8'>app_config</font> and is shared across scenarios. Do not recompute the domain from visible data when switching to 2050 (US1.1.3).",
        "Warming levels are discrete: 1.2 / 1.5 / 2.0 / 3.0. <b>3.0 is a scenario</b>, not a later year (US3.2.3).",
        "Projections are <b>bands</b> only (days_label / lower / upper), never a point number of days (US3.2.4).",
        "Comparisons default to <font name='Courier' size='8'>scope=RESIDENTIAL</font>. Copy must say “average residential block in Wyndham”, never “Wyndham’s average”.",
        "Source data has <b>no postcode</b>. Do not build backend postcode search for US1.2.1; suburb search uses SA2 names.",
    ]))

    story.append(P("3. Error envelope", "H1"))
    story.append(code_block('''
{ "error": { "code": "NOT_FOUND", "message": "Mesh block 20123456789 was not found." } }
'''))
    story.append(table(
        ["HTTP", "code", "When to use"],
        [
            ["404", "NOT_FOUND", "mb_code16 or area does not exist"],
            ["404", "OUTSIDE_MELBOURNE", "Click / coordinates outside metro Melbourne (US1.2.4)"],
            ["400", "BAD_REQUEST", "Missing parameter, illegal warming_level, illegal area_type"],
            ["503", "PROJECTION_UNAVAILABLE", "Projection tables failed to read (US3.1.4)"],
            ["500", "INTERNAL", "Unexpected error; log details, never return a stack trace"],
        ],
        [22 * mm, 52 * mm, 100 * mm],
    ))
    story.append(P(
        "Success is always 200. An empty search is also 200 with <font name='Courier' size='8'>results: []</font> — not 404.",
        "Caption",
    ))

    story.append(PageBreak())
    story.append(P("4. Endpoint contract", "H1"))

    story.append(P("4.1  GET /api/v1/bootstrap", "H2"))
    story.append(P(
        "Loaded once per page and cached in memory. Compose Yu’s three queries "
        "(app_config, model_coefficient, projection_metro) into <b>one object</b>. "
        "Do not return the three tables side by side. Shape matches static <font name='Courier' size='8'>bootstrap.json</font>."
    ))
    story.append(code_block('''
{
  "data_vintage": 2018,
  "n_blocks": 54239,
  "uhi_units": "°C above non-urban baseline",
  "scale": { "uhi_min": -8.0, "uhi_max": 17.0, "canopy_max": 80.0 },
  "model": {
    "model_type": "OLS_GLOBAL",
    "scope": "METRO",
    "slope": -0.1229,
    "intercept": 10.0507,
    "pearson_r": -0.5706,
    "r_squared": 0.326,
    "n_blocks": 54239
  },
  "projections": [
    { "warming_level": 1.2, "horizon_label": "Today",
      "days_label": "5-10", "days_lower": 5, "days_upper": 10 },
    { "warming_level": 1.5, "horizon_label": "2030",
      "days_label": "10-15", "days_lower": 10, "days_upper": 15 },
    { "warming_level": 2.0, "horizon_label": "2050",
      "days_label": "10-15", "days_lower": 10, "days_upper": 15 },
    { "warming_level": 3.0, "horizon_label": "2050 high warming",
      "days_label": "15+", "days_lower": 15, "days_upper": null }
  ]
}
'''))
    story.append(P(
        "Assembly: <font name='Courier' size='8'>uhi_scale_min/max</font> → scale; "
        "the active METRO model → model; four projection_metro rows sorted by warming_level. "
        "An open-ended band (15+) must use JSON <font name='Courier' size='8'>null</font> for <font name='Courier' size='8'>days_upper</font>, not 0.",
        "Caption",
    ))

    story.append(P("4.2  GET /api/v1/meshblocks", "H2"))
    story.append(P(
        "City-wide choropleth (US1.1.1). Optional query <font name='Courier' size='8'>?lga=Melton (C)</font>. "
        "SQL: <font name='Courier' size='8'>SELECT mb_code16, uhi_mean, canopy_pct FROM mesh_block</font>. "
        "<b>No geometry, no vegetation breakdown.</b>"
    ))
    story.append(code_block('''
{
  "count": 54239,
  "fields": ["mb_code16", "uhi_mean", "canopy_pct"],
  "rows": [
    ["20102100101", 8.42, 12.3]
  ]
}
'''))
    story.append(P(
        "Round numbers to 2 decimal places, matching the static bundle. count must equal rows.length. "
        "If the LGA does not match, return count=0 and empty rows — not 404.",
        "Caption",
    ))

    story.append(P("4.3  GET /api/v1/meshblocks/:mb_code16", "H2"))
    story.append(P(
        "Detail panel after a map tap. The static bundle is a 50k-row index; the API returns <b>one object</b> on demand. "
        "Compose Yu’s four queries (block / comparisons / coolest / projections) into the structure below."
    ))
    story.append(code_block('''
{
  "block": {
    "mb_code16": "20102100101",
    "sa2_name": "Melton",
    "sa3_name": "Melton - Bacchus Marsh",
    "lga_name": "Melton (C)",
    "uhi_mean": 8.42,
    "canopy_pct": 4.74,
    "grass_pct": 11.2,
    "shrub_pct": 6.1,
    "any_veg_pct": 22.0,
    "tree_03_10_pct": 3.1,
    "tree_10_15_pct": 1.0,
    "tree_15plus_pct": 0.6,
    "mb_category": "Residential",
    "dwellings": 42,
    "persons": 118,
    "area_sqkm": 0.0388,
    "irsd_score": 912,
    "irsd_decile": 3
  },
  "flags": {
    "no_published_population": false,
    "already_coolest_in_lga": false
  },
  "comparisons": [
    {
      "area_type": "LGA",
      "area_name": "Melton (C)",
      "scope": "RESIDENTIAL",
      "uhi_mean": 9.10,
      "canopy_mean": 5.20,
      "uhi_delta": -0.68,
      "canopy_delta": -0.46
    },
    {
      "area_type": "METRO",
      "area_name": "Metropolitan Melbourne",
      "scope": "RESIDENTIAL",
      "uhi_mean": 8.36,
      "canopy_mean": 13.30,
      "uhi_delta": 0.06,
      "canopy_delta": -8.56
    }
  ],
  "coolest_in_lga": {
    "mb_code16": "20102100999",
    "uhi_mean": 1.12,
    "canopy_pct": 3.96
  },
  "projections": [
    {
      "warming_level": 2.0,
      "horizon_label": "2050",
      "days_label": "10-15",
      "days_lower": 10,
      "days_upper": 15,
      "is_fallback": false
    }
  ]
}
'''))

    story.append(P("Detail field rules (must run on the server)", "H2"))
    story.append(table(
        ["Rule", "What to do", "AC"],
        [
            ["No population", "persons === 0 or null → flags.no_published_population = true. The panel must not show “0 people”.", "US2.1.4"],
            ["Missing SEIFA", "Keep irsd_score / irsd_decile as JSON null. Never fill with 0.", "1,477 blocks are valid nulls"],
            ["Delta sign", "uhi_delta = this block − comparison area. Positive = hotter.", "US2.2"],
            ["Already coolest", "block.mb_code16 === coolest_in_lga.mb_code16 → already_coolest_in_lga = true", "US2.2.4"],
            ["Coolest ≠ more trees", "Wyndham counter-example: the coolest block has less canopy. Do not write causal copy.", "Copy / frontend"],
            ["Projection fallback", "No row in mesh_block_projection → is_fallback=true, figures from projection_metro, UI must say city-wide", "US3.2.5"],
            ["Area precision", "Keep 4 decimal places on area_sqkm (0.0388 must not become 0.04)", "US2.1.5"],
            ["Panel matches DB", "Fields inside block are the raw row. Do not recompute at request time.", "US2.1.5"],
        ],
        [32 * mm, 102 * mm, 40 * mm],
    ))

    story.append(PageBreak())
    story.append(P("4.4  GET /api/v1/areas/:area_type/:area_code", "H2"))
    story.append(P(
        "Precomputed comparisons. Query <font name='Courier' size='8'>?scope=RESIDENTIAL</font> (default). "
        "area_type ∈ METRO | LGA | SA3 | SA2. For an LGA, area_code is the name, e.g. <font name='Courier' size='8'>Melton (C)</font>."
    ))
    story.append(code_block('''
{
  "area_type": "LGA",
  "area_code": "Melton (C)",
  "area_name": "Melton (C)",
  "scope": "RESIDENTIAL",
  "n_blocks": 1840,
  "uhi_mean": 9.10,
  "uhi_p10": 6.2,
  "uhi_p90": 12.4,
  "canopy_mean": 5.20,
  "canopy_p10": 1.1,
  "canopy_p90": 11.8,
  "coolest": {
    "mb_code16": "20102100999",
    "uhi_mean": 1.12,
    "canopy_pct": 3.96
  }
}
'''))
    story.append(P(
        "Fold SQL columns coolest_mb_code / coolest_uhi / coolest_canopy_pct into the nested object coolest, "
        "matching static areas.json. Unknown area → 404 NOT_FOUND.",
        "Caption",
    ))

    story.append(P("4.5  GET /api/v1/search?q=", "H2"))
    story.append(P(
        "Search SA2 names (suburbs) only, prefix match, max 10 rows. The static bundle has no search endpoint. "
        "SQL already has a LOWER(sa2_name) index. Empty q or fewer than 2 characters → 400 BAD_REQUEST."
    ))
    story.append(code_block('''
{
  "query": "melt",
  "results": [
    { "sa2_code16": "213011338", "sa2_name": "Melton",
      "lga_name": "Melton (C)", "n_blocks": 412 }
  ]
}
'''))
    story.append(P(
        "No matches: 200 + results: []. This endpoint does not decide “outside Melbourne” — "
        "if frontend geocode falls outside the metro, call lookup or show OUTSIDE_MELBOURNE (US1.2.4). "
        "A new search clearing the previous selection is frontend state, not an API concern (US1.2.5).",
        "Caption",
    ))

    story.append(P("4.6  Optional  GET /api/v1/lookup?lng=&amp;lat=", "H2"))
    story.append(P(
        "Only once <font name='Courier' size='8'>mesh_block_geometry</font> is loaded. This is the one job PostGIS earns. "
        "Hit: <font name='Courier' size='8'>{ \"mb_code16\": \"20102100101\" }</font>. "
        "Miss: 404 OUTSIDE_MELBOURNE. Iteration 1 can skip this; the frontend can point-in-polygon on static GeoJSON."
    ))

    story.append(P("5. How the two partial artefacts line up", "H1"))
    story.append(table(
        ["Resource", "Follow", "When implementing"],
        [
            ["/bootstrap", "Composed bootstrap.json object", "Do not return three tables"],
            ["/meshblocks list", "meshblocks.json fields + rows", "Geometry never in JSON"],
            ["/meshblocks/:id", "The object in section 4.3", "Do not ship the 50k-row bundle index"],
            ["/areas/...", "queries.sql + nested coolest", "Default RESIDENTIAL"],
            ["/search", "queries.sql only", "No postcode"],
        ],
        [42 * mm, 62 * mm, 70 * mm],
    ))

    story.append(P("6. Suggested implementation order", "H1"))
    story.extend(bullet([
        "Merge 002_create_schema.sql, queries.sql, and seeds from <font name='Courier' size='8'>data-analysis</font> into the <font name='Courier' size='8'>backend</font> branch.",
        "Locally run <font name='Courier' size='8'>npm run migrate</font> + <font name='Courier' size='8'>load_seeds.sql</font>. Develop against real seeds, not hand-written fake blocks.",
        "Add <font name='Courier' size='8'>src/routes/v1/</font>: bootstrap.js, meshblocks.js, areas.js, search.js, mounted at /api/v1 in index.js.",
        "Each route: query → mapper → JSON. Unit-test the mapper (delta, flags, null, fallback).",
        "Lock the keys in this spec with Jest + supertest; pick one known mb_code16 for US2.1.5.",
        "Sheng keeps static JSON until fields match, then changes URLs only. Swap DATABASE_URL when Savio’s cloud DB is ready.",
    ]))

    story.append(P("7. Mapping to acceptance criteria", "H1"))
    story.append(table(
        ["AC", "Which response"],
        [
            ["US1.1.1 Render all mesh blocks", "GET /meshblocks — 54,239 rows"],
            ["US1.1.2 / 1.1.3 Legend units + fixed scale", "GET /bootstrap uhi_units and scale"],
            ["US1.2.1 Search by suburb", "GET /search (no postcode)"],
            ["US1.2.2 Select a block by tap", "GET /meshblocks/:id, or frontend GeoJSON + the same API"],
            ["US1.2.4 Outside metropolitan Melbourne", "404 OUTSIDE_MELBOURNE"],
            ["US2.1.1 / 2.1.5 Vegetation, heat, match DB row", "block object as stored"],
            ["US2.1.4 No published population", "flags.no_published_population"],
            ["US2.2.1 Three comparators", "comparisons (LGA + METRO) + coolest_in_lga"],
            ["US2.2.4 Already the coolest", "flags.already_coolest_in_lga"],
            ["US3.1.1–3.1.3 2050 toggle + fixed scale", "bootstrap.projections + fixed scale"],
            ["US3.1.4 Failed projection layer", "503 PROJECTION_UNAVAILABLE"],
            ["US3.2.1 / 3.2.2 Block band updates with warming level", "projections[] four levels"],
            ["US3.2.5 Outside every projection polygon", "is_fallback: true"],
        ],
        [62 * mm, 112 * mm],
    ))

    story.append(P("8. Explicitly out of scope (Iteration 1)", "H1"))
    story.extend(bullet([
        "No GeoJSON / WKT / coordinate arrays in the response.",
        "No postcode search.",
        "No OLS / GWR at request time; slope comes only from model_coefficient.",
        "No LGA average computed at request time; read area_baseline only.",
        "Do not treat 3.0 as “a further 2050”.",
    ]))

    story.append(Spacer(1, 8 * mm))
    story.append(HRFlowable(width="100%", thickness=0.6, color=TEAL, spaceAfter=8))
    story.append(P(
        "This is the Iteration 1 working contract. If a field conflicts with a later Yu seed, the database row and US2.1.5 win — sync Sheng before changing JSON. "
        "Sources: origin/data-analysis backend/src/db/queries.sql and data-pipeline/04_build_frontend_bundle.py.",
        "Caption",
    ))

    doc = SimpleDocTemplate(
        OUT,
        pagesize=A4,
        leftMargin=18 * mm,
        rightMargin=18 * mm,
        topMargin=22 * mm,
        bottomMargin=18 * mm,
        title="Cool Change — How to Create API Responses",
        author="FOXES EAT IT / Yipu Tang",
        subject="Story 0.3 read-only API response contract",
    )
    doc.build(story, onFirstPage=cover_header_footer, onLaterPages=header_footer)
    print(OUT)


if __name__ == "__main__":
    build()
