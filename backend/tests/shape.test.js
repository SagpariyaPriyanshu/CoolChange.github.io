const {
  round2,
  round4,
  shapeFlags,
  shapeBlock,
  shapeBootstrap,
  shapeMeshblockList,
} = require("../src/services/shape");

describe("shape helpers", () => {
  test("round2 and round4", () => {
    expect(round2(8.424)).toBe(8.42);
    expect(round4(0.03881)).toBe(0.0388);
    expect(round2(null)).toBeNull();
  });

  test("no published population when persons is 0", () => {
    const flags = shapeFlags({ mb_code16: "1", persons: 0 }, { mb_code16: "2" });
    expect(flags.no_published_population).toBe(true);
    expect(flags.already_coolest_in_lga).toBe(false);
  });

  test("already coolest when codes match after trim", () => {
    const flags = shapeFlags(
      { mb_code16: "20102100101", persons: 10 },
      { mb_code16: "20102100101" }
    );
    expect(flags.already_coolest_in_lga).toBe(true);
  });

  test("SEIFA stays null", () => {
    const block = shapeBlock({
      mb_code16: "20102100101",
      sa2_name: "Melton",
      sa3_name: "Melton - Bacchus Marsh",
      lga_name: "Melton (C)",
      uhi_mean: 8.424,
      canopy_pct: 4.741,
      grass_pct: 11.2,
      shrub_pct: 6.1,
      any_veg_pct: 22,
      tree_03_10_pct: 3.1,
      tree_10_15_pct: 1,
      tree_15plus_pct: 0.6,
      mb_category: "Residential",
      dwellings: 42,
      persons: 118,
      area_sqkm: 0.03881,
      irsd_score: null,
      irsd_decile: null,
    });
    expect(block.irsd_score).toBeNull();
    expect(block.irsd_decile).toBeNull();
    expect(block.area_sqkm).toBe(0.0388);
    expect(block.uhi_mean).toBe(8.42);
  });

  test("meshblock list is array-of-arrays", () => {
    const payload = shapeMeshblockList([
      { mb_code16: "20102100101", uhi_mean: 8.42, canopy_pct: 12.3 },
    ]);
    expect(payload).toEqual({
      count: 1,
      fields: ["mb_code16", "uhi_mean", "canopy_pct"],
      rows: [["20102100101", 8.42, 12.3]],
    });
  });

  test("bootstrap composes config, model, projections", () => {
    const payload = shapeBootstrap({
      configRows: [
        { key: "data_vintage", value: "2018" },
        { key: "n_blocks", value: "54239" },
        { key: "uhi_units", value: "°C above non-urban baseline" },
        { key: "uhi_scale_min", value: "-8.0" },
        { key: "uhi_scale_max", value: "17.0" },
        { key: "canopy_scale_max", value: "80.0" },
      ],
      modelRow: {
        model_type: "OLS_GLOBAL",
        slope: -0.122852,
        intercept: 10.050744,
        pearson_r: -0.570602,
        r_squared: 0.325586,
        n_blocks: 54239,
      },
      projectionRows: [
        {
          warming_level: "3.0",
          horizon_label: "2050 high warming",
          days_label: "15+",
          days_lower: 15,
          days_upper: null,
        },
      ],
    });
    expect(payload.n_blocks).toBe(54239);
    expect(payload.scale).toEqual({ uhi_min: -8, uhi_max: 17, canopy_max: 80 });
    expect(payload.model.slope).toBe(-0.1229);
    expect(payload.projections[0].days_upper).toBeNull();
    expect(payload.projections[0].warming_level).toBe(3);
  });
});
