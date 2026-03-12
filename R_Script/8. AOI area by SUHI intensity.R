#Author Name: Ibrahim Khalil
#Date: 10.09.2025
#Content Name: Making SUHI intensity of AOI
#------------------------------------------


library(terra)
library(dplyr)
library(tidyr)
library(ggplot2)

# Paths
root     <- "E:/Course&Class/SFRS"
ndvi_dir <- file.path(root, "_ndvi_clipped")
ndbi_dir <- file.path(root, "_indices_clipped")
lst_dir  <- file.path(root, "_lst_clipped")
out_dir  <- file.path(root, "_analysis")
aoi      <- vect(file.path(root, "n_shapefile", "AOI.shp"))

# Outputs
out_root <- file.path(root, "_suhi_class_results")
ras_dir  <- file.path(out_root, "rasters")
tab_dir  <- file.path(out_root, "tables")
plot_dir <- file.path(out_root, "plots")
dir.create(out_dir,  showWarnings = FALSE, recursive = TRUE)
dir.create(ras_dir,  showWarnings = FALSE, recursive = TRUE)
dir.create(tab_dir,  showWarnings = FALSE, recursive = TRUE)
dir.create(plot_dir, showWarnings = FALSE, recursive = TRUE)

# Match files by scene ID
ndvi_files <- list.files(ndvi_dir, pattern = "_NDVI_clipped\\.tif$", full.names = TRUE, recursive = TRUE)
ndbi_files <- list.files(ndbi_dir, pattern = "_NDBI_clipped\\.tif$", full.names = TRUE, recursive = TRUE)
lst_files  <- list.files(lst_dir,  pattern = "_LST_C_clipped\\.tif$",  full.names = TRUE, recursive = TRUE)

scene_id <- function(p){
  b <- basename(p)
  m <- regexpr("\\d{4}-\\d{2}-\\d{2}_LC0[89]_\\d{3}_\\d{3}", b)
  if (m[1] > 0) substr(b, m[1], m[1] + attr(m, "match.length") - 1) else gsub("(_NDVI|_NDBI|_LST).*", "", b)
}
idx_by_scene <- function(v) tapply(v, sapply(v, scene_id), function(x) x[1], simplify = TRUE)

NDVI <- idx_by_scene(ndvi_files)
NDBI <- idx_by_scene(ndbi_files)
LST  <- idx_by_scene(lst_files)
scenes <- sort(Reduce(intersect, list(names(LST), names(NDVI), names(NDBI))))

# Helpers
safe_mean  <- function(r){ v <- try(terra::global(r, "mean", na.rm = TRUE)[1,1], silent = TRUE); if (inherits(v, "try-error")) NA_real_ else v }
scene_date <- function(scene_id) substr(scene_id, 1, 10)

# Fixed SUHI class breaks (°C)
rcl <- matrix(c(
  -Inf, 0,   1,
  0,    2,   2,
  2,    4,   3,
  4,    6,   4,
  6,    Inf, 5
), ncol = 3, byrow = TRUE)
class_labels <- c("≤0 °C","0–2 °C","2–4 °C","4–6 °C",">6 °C")

# Per-scene processing
rows <- list()

for (scene in scenes) {
  date_str <- scene_date(scene)
  
  ndvi <- rast(NDVI[[scene]])
  ndbi <- rast(NDBI[[scene]])
  lst  <- rast(LST [[scene]])
  
  ndvi <- terra::project(ndvi, lst, method = "bilinear")
  ndbi <- terra::project(ndbi, lst, method = "bilinear")
  
  ndvi <- mask(crop(ndvi, aoi), aoi)
  ndbi <- mask(crop(ndbi, aoi), aoi)
  lst  <- mask(crop(lst,  aoi), aoi)
  if (ncell(lst) < 100) next
  
  ndvi_vals <- values(ndvi, na.rm = TRUE)
  ndbi_vals <- values(ndbi, na.rm = TRUE)
  if (length(ndvi_vals) < 100 || length(ndbi_vals) < 100) next
  
  q_low  <- 0.40; q_high <- 0.60
  ndvi_low  <- as.numeric(quantile(ndvi_vals, q_low,  na.rm = TRUE))
  ndvi_high <- as.numeric(quantile(ndvi_vals, q_high, na.rm = TRUE))
  ndbi_low  <- as.numeric(quantile(ndbi_vals, q_low,  na.rm = TRUE))
  ndbi_high <- as.numeric(quantile(ndbi_vals, q_high, na.rm = TRUE))
  
  urban_mask <- (ndvi <= ndvi_low)  & (ndbi >= ndbi_high)
  rural_mask <- (ndvi >= ndvi_high) & (ndbi <= ndbi_low)
  ov <- terra::global(urban_mask & rural_mask, "sum", na.rm = TRUE)[1,1]
  if (!is.na(ov) && ov > 0) rural_mask[urban_mask] <- FALSE
  
  upx <- terra::global(urban_mask, "sum", na.rm = TRUE)[1,1]
  rpx <- terra::global(rural_mask, "sum", na.rm = TRUE)[1,1]
  if (is.na(upx) || upx < 1000 || is.na(rpx) || rpx < 1000) {
    ndvi_low  <- as.numeric(quantile(ndvi_vals, 0.45, na.rm = TRUE))
    ndvi_high <- as.numeric(quantile(ndvi_vals, 0.55, na.rm = TRUE))
    ndbi_low  <- as.numeric(quantile(ndbi_vals, 0.45, na.rm = TRUE))
    ndbi_high <- as.numeric(quantile(ndbi_vals, 0.55, na.rm = TRUE))
    urban_mask <- (ndvi <= ndvi_low)  & (ndbi >= ndbi_high)
    rural_mask <- (ndvi >= ndvi_high) & (ndbi <= ndbi_low)
    rural_mask[urban_mask] <- FALSE
  }
  
  urban_mean <- safe_mean(mask(lst, urban_mask, maskvalues = 0, updatevalue = NA))
  rural_mean <- safe_mean(mask(lst, rural_mask, maskvalues = 0, updatevalue = NA))
  if (is.na(urban_mean) || is.na(rural_mean)) next
  
  suhi_full  <- lst - rural_mean
  writeRaster(suhi_full, file.path(out_dir, paste0(scene, "_SUHI_fullAOI.tif")), overwrite = TRUE)
  
  suhi_class <- classify(suhi_full, rcl, include.lowest = TRUE)
  writeRaster(suhi_class, file.path(ras_dir, paste0(scene, "_SUHI_class.tif")), overwrite = TRUE)
  
  cs <- cellSize(suhi_class, unit = "m")
  valid <- !is.na(suhi_class)
  class_ids <- 1:5
  area_km2 <- sapply(class_ids, function(cid){
    sum(values(cs * (suhi_class == cid) * valid), na.rm = TRUE) / 1e6
  })
  total_km2 <- sum(area_km2, na.rm = TRUE)
  pct_area  <- if (total_km2 > 0) 100 * area_km2 / total_km2 else rep(NA_real_, length(area_km2))
  
  rows[[scene]] <- tibble(
    scene    = scene,
    date     = as.Date(date_str),
    class_id = class_ids,
    class    = factor(class_labels[class_ids], levels = class_labels),
    area_km2 = round(area_km2, 3),
    pct_area = round(pct_area, 2)
  )
}

# Tables and plot
res_long <- bind_rows(rows) |> arrange(date, class)
write.csv(res_long, file.path(tab_dir, "suhi_AOI_area_by_class_long.csv"), row.names = FALSE)

res_wide <- res_long |>
  mutate(Year = as.integer(format(date, "%Y"))) |>
  select(Year, class, pct_area) |>
  pivot_wider(names_from = class, values_from = pct_area) |>
  arrange(Year)
write.csv(res_wide, file.path(tab_dir, "suhi_AOI_area_by_class_wide.csv"), row.names = FALSE)

if (nrow(res_long) > 0){
  p <- res_long |>
    group_by(date, class) |>
    summarise(pct_area = sum(pct_area), .groups = "drop") |>
    mutate(Year = as.integer(format(date, "%Y"))) |>
    ggplot(aes(x = Year, y = pct_area, fill = class)) +
    geom_col() +
    scale_fill_manual(values = c(
      "≤0 °C"="#4C78A8","0–2 °C"="#72B7B2","2–4 °C"="#8FD0C8",
      "4–6 °C"="#F2CF5B",">6 °C"="#D64F4B"
    ), breaks = class_labels) +
    labs(x = "Year", y = "Area (%)", fill = "SUHI class",
         title = "AOI area by SUHI intensity class (fixed °C breaks)") +
    theme_minimal(base_size = 12)
  
  ggsave(file.path(plot_dir, "suhi_AOI_area_by_class_stacked.png"),
         p, width = 10, height = 6, dpi = 150)
}
