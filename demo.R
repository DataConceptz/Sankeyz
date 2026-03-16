# =============================================================================
# SANKEYZ DEMO — Real-World Data Showcases
# =============================================================================
# All data sourced from publicly available statistics (IEA, IPCC, FAO, WHO).
# Values are approximate and rounded for clarity.
# =============================================================================

source("sankey.R")


# =============================================================================
# DEMO 1: Global CO2 Emissions by Sector (2022, GtCO2)
# Based on IEA/IPCC sector breakdowns (~37 Gt total energy-related CO2)
# =============================================================================

co2_links <- data.frame(
  source = c(
    # Fuel source -> Sector
    "Coal",          "Coal",          "Coal",
    "Oil",           "Oil",           "Oil",           "Oil",
    "Natural Gas",   "Natural Gas",   "Natural Gas",   "Natural Gas",
    "Cement & Other",
    # Sector -> End use
    "Power Generation",  "Power Generation",  "Power Generation",
    "Industry",          "Industry",
    "Transport",         "Transport",         "Transport",
    "Buildings",         "Buildings"
  ),
  target = c(
    "Power Generation",  "Industry",       "Buildings",
    "Transport",         "Power Generation","Industry",       "Buildings",
    "Power Generation",  "Industry",       "Buildings",      "Transport",
    "Industry",
    "Residential Elec",  "Commercial Elec","Industrial Elec",
    "Steel & Cement",    "Chemicals & Other",
    "Road",              "Aviation",       "Shipping",
    "Heating",           "Cooking & Other"
  ),
  value = c(
    # Coal: 15.1 Gt
    10.2,  3.8,   1.1,
    # Oil: 11.2 Gt
    7.9,   0.8,   1.4,   1.1,
    # Natural Gas: 7.8 Gt
    3.3,   2.0,   2.1,   0.4,
    # Cement & Other: 2.9 Gt
    2.9,
    # Power -> end use: 14.3 Gt
    5.1,   4.2,   5.0,
    # Industry -> end use: 10.1 Gt
    6.4,   3.7,
    # Transport -> end use: 8.3 Gt
    6.1,   1.1,   1.1,
    # Buildings -> end use: 4.3 Gt
    3.0,   1.3
  ),
  stringsAsFactors = FALSE
)

co2_colors <- c(
  "Coal"              = "#3D3D3D",
  "Oil"               = "#8B6914",
  "Natural Gas"       = "#D4A843",
  "Cement & Other"    = "#A0A0A0",
  "Power Generation"  = "#C0392B",
  "Industry"          = "#7F8C8D",
  "Transport"         = "#2980B9",
  "Buildings"         = "#27AE60",
  "Residential Elec"  = "#E67E22",
  "Commercial Elec"   = "#F39C12",
  "Industrial Elec"   = "#D35400",
  "Steel & Cement"    = "#5D6D7E",
  "Chemicals & Other" = "#85929E",
  "Road"              = "#1A5276",
  "Aviation"          = "#5DADE2",
  "Shipping"          = "#76D7C4",
  "Heating"           = "#E74C3C",
  "Cooking & Other"   = "#58D68D"
)

sankey(co2_links,
       node_colors = co2_colors,
       flow_style  = "gradient",
       flow_alpha  = 0.50,
       title       = "Global CO2 Emissions by Sector (2022, GtCO2)",
       label_cex   = 0.80,
       node_pad    = 0.018,
       node_width  = 0.028)

readline(prompt = "Press [Enter] for Demo 2...")


# =============================================================================
# DEMO 2: Global Primary Energy Flow (2022, EJ — Exajoules)
# Based on IEA World Energy Balances (~600 EJ total primary supply)
# =============================================================================

energy_links <- data.frame(
  source = c(
    # Primary source -> Conversion
    "Crude Oil",     "Crude Oil",
    "Coal",          "Coal",
    "Natural Gas",   "Natural Gas",   "Natural Gas",
    "Nuclear",
    "Hydro",
    "Wind & Solar",
    "Biomass",       "Biomass",
    # Conversion -> Final use
    "Refineries",    "Refineries",    "Refineries",
    "Power Plants",  "Power Plants",  "Power Plants",  "Power Plants",
    "Direct Use",    "Direct Use",    "Direct Use",
    # Losses
    "Power Plants",
    "Refineries"
  ),
  target = c(
    "Refineries",    "Direct Use",
    "Power Plants",  "Direct Use",
    "Power Plants",  "Direct Use",    "Refineries",
    "Power Plants",
    "Power Plants",
    "Power Plants",
    "Power Plants",  "Direct Use",
    "Transport",     "Industry",      "Petrochemicals",
    "Industry",      "Residential",   "Commercial",    "Transport",
    "Industry",      "Residential",   "Commercial",
    "Conversion Loss",
    "Conversion Loss"
  ),
  value = c(
    # Crude Oil: 184 EJ
    170,   14,
    # Coal: 161 EJ
    115,   46,
    # Natural Gas: 141 EJ
    62,    65,   14,
    # Nuclear: 30 EJ
    30,
    # Hydro: 15 EJ
    15,
    # Wind & Solar: 32 EJ
    32,
    # Biomass: 55 EJ
    22,    33,
    # Refineries -> end use: 184 EJ out (~160 useful)
    95,    38,    27,
    # Power Plants -> end use: ~276 in, ~100 out (rest is loss)
    35,    42,    28,    5,
    # Direct use: 158 EJ
    82,    50,    26,
    # Losses
    166,
    24
  ),
  stringsAsFactors = FALSE
)

energy_colors <- c(
  "Crude Oil"        = "#2C2C2C",
  "Coal"             = "#5C4033",
  "Natural Gas"      = "#E8A838",
  "Nuclear"          = "#9B59B6",
  "Hydro"            = "#3498DB",
  "Wind & Solar"     = "#2ECC71",
  "Biomass"          = "#8B4513",
  "Refineries"       = "#E67E22",
  "Power Plants"     = "#C0392B",
  "Direct Use"       = "#1ABC9C",
  "Transport"        = "#2980B9",
  "Industry"         = "#7F8C8D",
  "Residential"      = "#27AE60",
  "Commercial"       = "#F1C40F",
  "Petrochemicals"   = "#8E44AD",
  "Conversion Loss"  = "#BDC3C7"
)

sankey(energy_links,
       node_colors = energy_colors,
       flow_style  = "gradient",
       flow_alpha  = 0.45,
       title       = "Global Primary Energy Flow (2022, Exajoules)",
       label_cex   = 0.78,
       node_pad    = 0.016,
       node_width  = 0.030,
       relaxation_iters = 50)

readline(prompt = "Press [Enter] for Demo 3...")


# =============================================================================
# DEMO 3: Global Freshwater Withdrawal & Use (km3/yr)
# Based on FAO AQUASTAT / UN World Water Development Report
# Total withdrawal ~4,000 km3/year
# =============================================================================

water_links <- data.frame(
  source = c(
    # Source -> Withdrawal type
    "Surface Water",   "Surface Water",   "Surface Water",
    "Groundwater",     "Groundwater",     "Groundwater",
    "Desalination",
    # Sector -> Outcome
    "Agriculture",     "Agriculture",
    "Industry",        "Industry",
    "Municipal",       "Municipal"
  ),
  target = c(
    "Agriculture",     "Industry",        "Municipal",
    "Agriculture",     "Industry",        "Municipal",
    "Municipal",
    "Consumptive Use", "Return Flow",
    "Consumptive Use", "Return Flow",
    "Consumptive Use", "Return Flow"
  ),
  value = c(
    # Surface: ~3,000 km3
    2100,  520,  280,
    # Ground: ~950 km3
    620,   200,  130,
    # Desalination: ~15 km3
    15,
    # Agriculture: 2720 -> ~1600 consumed, ~1120 return
    1600,  1120,
    # Industry: 720 -> ~120 consumed, ~600 return
    120,   600,
    # Municipal: 425 -> ~85 consumed, ~340 return
    85,    340
  ),
  stringsAsFactors = FALSE
)

water_colors <- c(
  "Surface Water"    = "#1E90FF",
  "Groundwater"      = "#4169E1",
  "Desalination"     = "#00CED1",
  "Agriculture"      = "#228B22",
  "Industry"         = "#FF8C00",
  "Municipal"        = "#DC143C",
  "Consumptive Use"  = "#8B0000",
  "Return Flow"      = "#87CEEB"
)

sankey(water_links,
       node_colors = water_colors,
       flow_style  = "gradient",
       flow_alpha  = 0.50,
       title       = "Global Freshwater Withdrawal & Use (km3/year)",
       label_cex   = 0.90,
       node_pad    = 0.025,
       node_width  = 0.032,
       value_labels = TRUE)

readline(prompt = "Press [Enter] for Demo 4...")


# =============================================================================
# DEMO 4: Global Food System — From Farm to Fork (Mt/yr)
# Based on FAO Food Balance Sheets & UNEP Food Waste Index
# Approximate values for major crop/livestock flows
# =============================================================================

food_links <- data.frame(
  source = c(
    # Production -> Processing
    "Cropland",       "Cropland",       "Cropland",
    "Pastureland",
    "Fisheries",
    # Processing -> Distribution
    "Food Crops",     "Food Crops",
    "Animal Feed",    "Animal Feed",
    "Livestock",      "Livestock",
    "Seafood",
    # Distribution -> Consumption
    "Processing",     "Processing",     "Processing",
    "Harvest Loss",
    "Meat & Dairy",
    # Waste streams
    "Processing",
    "Retail",
    "Households",
    "Food Services"
  ),
  target = c(
    "Food Crops",     "Animal Feed",    "Biofuels & Fiber",
    "Livestock",
    "Seafood",
    "Processing",     "Harvest Loss",
    "Livestock",      "Harvest Loss",
    "Meat & Dairy",   "Manure & Waste",
    "Processing",
    "Retail",         "Food Services",  "Households",
    "Food Waste",
    "Retail",
    "Food Waste",
    "Food Waste",
    "Food Waste",
    "Food Waste"
  ),
  value = c(
    # Cropland: ~9,800 Mt
    5400,  3200,  1200,
    # Pastureland -> Livestock
    2600,
    # Fisheries
    180,
    # Food Crops -> Processing & Loss
    4800,  600,
    # Animal Feed -> Livestock & Loss
    2900,  300,
    # Livestock -> Products
    780,   4520,
    # Seafood -> Processing
    160,
    # Processing -> Distribution
    2200,  1400,  2000,
    # Harvest loss -> waste
    900,
    # Meat & Dairy -> Retail
    700,
    # Processing waste
    340,
    # Retail waste
    190,
    # Household waste
    570,
    # Food service waste
    260
  ),
  stringsAsFactors = FALSE
)

food_colors <- c(
  "Cropland"         = "#228B22",
  "Pastureland"      = "#9ACD32",
  "Fisheries"        = "#4682B4",
  "Food Crops"       = "#DAA520",
  "Animal Feed"      = "#D2B48C",
  "Biofuels & Fiber" = "#8FBC8F",
  "Livestock"        = "#CD853F",
  "Seafood"          = "#5F9EA0",
  "Harvest Loss"     = "#BC8F8F",
  "Processing"       = "#FF8C00",
  "Meat & Dairy"     = "#B22222",
  "Manure & Waste"   = "#A0522D",
  "Retail"           = "#6A5ACD",
  "Food Services"    = "#DB7093",
  "Households"       = "#20B2AA",
  "Food Waste"       = "#808080"
)

sankey(food_links,
       node_colors = food_colors,
       flow_style  = "gradient",
       flow_alpha  = 0.42,
       title       = "Global Food System: Farm to Fork (Mt/year)",
       label_cex   = 0.75,
       node_pad    = 0.014,
       node_width  = 0.026,
       relaxation_iters = 50)

readline(prompt = "Press [Enter] for Demo 5...")


# =============================================================================
# DEMO 5: Global Burden of Disease — Risk Factors to Outcomes (Million DALYs)
# Based on IHME Global Burden of Disease Study 2019
# =============================================================================

disease_links <- data.frame(
  source = c(
    # Behavioral risks -> Metabolic risks / Direct disease
    "Poor Diet",        "Poor Diet",        "Poor Diet",
    "Tobacco Use",      "Tobacco Use",      "Tobacco Use",
    "Alcohol Use",      "Alcohol Use",
    "Physical Inactivity",
    "Unsafe Sex",
    # Environmental risks
    "Air Pollution",    "Air Pollution",    "Air Pollution",
    "Unsafe Water",
    # Metabolic risks -> Disease
    "High Blood Pressure",  "High Blood Pressure",
    "High Blood Sugar",     "High Blood Sugar",
    "High BMI",             "High BMI",
    "High Cholesterol",
    # Direct disease -> Outcome
    "Cardiovascular",   "Cardiovascular",
    "Cancer",           "Cancer",
    "Respiratory",      "Respiratory",
    "Diabetes Comp.",
    "Infectious Disease","Infectious Disease"
  ),
  target = c(
    "High Blood Pressure", "High Blood Sugar",  "Cancer",
    "Cancer",              "Respiratory",        "Cardiovascular",
    "Cancer",              "Infectious Disease",
    "High BMI",
    "Infectious Disease",
    "Respiratory",         "Cardiovascular",     "Cancer",
    "Infectious Disease",
    "Cardiovascular",      "Stroke",
    "Diabetes Comp.",      "Cardiovascular",
    "Cardiovascular",      "Diabetes Comp.",
    "Cardiovascular",
    "Death",               "Disability",
    "Death",               "Disability",
    "Death",               "Disability",
    "Disability",
    "Death",               "Disability"
  ),
  value = c(
    # Poor Diet
    47,   28,   12,
    # Tobacco
    22,   18,   12,
    # Alcohol
    8,    6,
    # Physical Inactivity
    14,
    # Unsafe Sex
    26,
    # Air Pollution
    18,   22,   5,
    # Unsafe Water
    35,
    # High BP
    65,   32,
    # High Blood Sugar
    24,   18,
    # High BMI
    22,   16,
    # High Cholesterol
    28,
    # CVD -> Outcome: ~165
    82,   83,
    # Cancer -> Outcome: ~47
    30,   17,
    # Respiratory -> Outcome: ~36
    16,   20,
    # Diabetes -> Outcome: ~40
    40,
    # Infectious -> Outcome: ~67
    38,   29
  ),
  stringsAsFactors = FALSE
)

disease_colors <- c(
  "Poor Diet"           = "#E74C3C",
  "Tobacco Use"         = "#8B4513",
  "Alcohol Use"         = "#9B59B6",
  "Physical Inactivity" = "#E67E22",
  "Unsafe Sex"          = "#C0392B",
  "Air Pollution"       = "#95A5A6",
  "Unsafe Water"        = "#3498DB",
  "High Blood Pressure" = "#E74C3C",
  "High Blood Sugar"    = "#F39C12",
  "High BMI"            = "#D35400",
  "High Cholesterol"    = "#C0392B",
  "Cardiovascular"      = "#922B21",
  "Cancer"              = "#6C3483",
  "Respiratory"         = "#2E86C1",
  "Diabetes Comp."      = "#D4AC0D",
  "Infectious Disease"  = "#1E8449",
  "Stroke"              = "#CB4335",
  "Death"               = "#1C1C1C",
  "Disability"          = "#7F8C8D"
)

sankey(disease_links,
       node_colors      = disease_colors,
       flow_style       = "gradient",
       flow_alpha       = 0.40,
       title            = "Global Burden of Disease: Risk Factors to Outcomes (Million DALYs, 2019)",
       label_cex        = 0.70,
       node_pad         = 0.012,
       node_width       = 0.024,
       relaxation_iters = 60,
       title_cex        = 1.1)


# =============================================================================
# Save all diagrams to PNG
# =============================================================================

cat("\nSaving all diagrams to PNG...\n")

sankey_save(co2_links,     file = "sankey_co2.png",
            node_colors = co2_colors, flow_style = "gradient",
            flow_alpha = 0.50,
            title = "Global CO2 Emissions by Sector (2022, GtCO2)",
            label_cex = 0.80, node_pad = 0.018, node_width = 0.028,
            width = 16, height = 9, res = 250)
cat("  -> sankey_co2.png\n")

sankey_save(energy_links,  file = "sankey_energy.png",
            node_colors = energy_colors, flow_style = "gradient",
            flow_alpha = 0.45,
            title = "Global Primary Energy Flow (2022, Exajoules)",
            label_cex = 0.78, node_pad = 0.016, node_width = 0.030,
            relaxation_iters = 50,
            width = 16, height = 9, res = 250)
cat("  -> sankey_energy.png\n")

sankey_save(water_links,   file = "sankey_water.png",
            node_colors = water_colors, flow_style = "gradient",
            flow_alpha = 0.50,
            title = "Global Freshwater Withdrawal & Use (km3/year)",
            label_cex = 0.90, node_pad = 0.025, node_width = 0.032,
            value_labels = TRUE,
            width = 14, height = 8, res = 250)
cat("  -> sankey_water.png\n")

sankey_save(food_links,    file = "sankey_food.png",
            node_colors = food_colors, flow_style = "gradient",
            flow_alpha = 0.42,
            title = "Global Food System: Farm to Fork (Mt/year)",
            label_cex = 0.75, node_pad = 0.014, node_width = 0.026,
            relaxation_iters = 50,
            width = 16, height = 9, res = 250)
cat("  -> sankey_food.png\n")

sankey_save(disease_links, file = "sankey_disease.png",
            node_colors = disease_colors, flow_style = "gradient",
            flow_alpha = 0.40,
            title = "Global Burden of Disease: Risk Factors to Outcomes (Million DALYs, 2019)",
            label_cex = 0.70, node_pad = 0.012, node_width = 0.024,
            relaxation_iters = 60, title_cex = 1.1,
            width = 18, height = 10, res = 250)
cat("  -> sankey_disease.png\n")

cat("\nAll demos complete!\n")
