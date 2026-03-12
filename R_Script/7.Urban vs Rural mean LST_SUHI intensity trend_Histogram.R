#Author Name: Ibrahim Khalil
#Date: 10.09.2025
#Content Name: Creating Urban_Rural mean LST, LST trend,SUHI intensity and Histogram
#--------------------------------------------------------------------------------------


library(terra)
library(dplyr)
library(ggplot2)
library(tidyr)

# Paths
root     <- "E:/Course&Class/SFRS"
ndvi_dir <- file.path(root, "_ndvi_clipped")
ndbi_dir <- file.path(root, "_indices_clipped")
lst_dir  <- file.path(root, "_lst_clipped")
out_dir  <- file.path(root, "_analysis")
mask_dir <- file.path(root, "_maps_hotspots", "masks")
aoi      <- vect(file.path(root, "n_shapefile", "AOI.shp"))

dir.create(out_dir,  showWarnings = FALSE, recursive = TRUE)
dir.create(mask_dir, showWarnings = FALSE, recursive = TRUE)
hist_dir <- file.path(out_dir, "histograms")
dir.create(hist_dir, showWarnings = FALSE, recursive = TRUE)

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

# Per-scene processing
summary_list <- list()

for (scene in scenes) {
  date_str <- scene_date(scene)
  
  ndvi <- rast(NDVI[[scene]])
  ndbi <- rast(NDBI[[scene]])
  lst  <- rast(LST[[scene]])
  
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
  
  urban_lst <- mask(lst, urban_mask, maskvalues = 0, updatevalue = NA)
  rural_lst <- mask(lst, rural_mask, maskvalues = 0, updatevalue = NA)
  
  urban_mean <- safe_mean(urban_lst)
  rural_mean <- safe_mean(rural_lst)
  if (is.na(urban_mean) || is.na(rural_mean)) next
  
  suhi_val <- urban_mean - rural_mean
  
  set.seed(1)
  urban_vals <- values(urban_lst, na.rm = TRUE)
  rural_vals <- values(rural_lst, na.rm = TRUE)
  if (length(urban_vals) > 200000) urban_vals <- sample(urban_vals, 200000)
  if (length(rural_vals) > 200000) rural_vals <- sample(rural_vals, 200000)
  
  if (length(urban_vals) > 0 && length(rural_vals) > 0) {
    df_hist <- data.frame(
      LST = c(urban_vals, rural_vals),
      Class = c(rep("Urban", length(urban_vals)), rep("Rural", length(rural_vals)))
    )
    
    p_hist <- ggplot(df_hist, aes(x = LST, fill = Class)) +
      geom_histogram(alpha = 0.6, position = "identity", bins = 30) +
      scale_fill_manual(values = c("Urban" = "#D64F4B", "Rural" = "#1f77b4")) +
      geom_vline(xintercept = urban_mean, linetype = "dashed", linewidth = 0.7, color = "#D64F4B") +
      geom_vline(xintercept = rural_mean, linetype = "dashed", linewidth = 0.7, color = "#1f77b4") +
      labs(title = paste("Urban vs Rural LST —", date_str),
           x = "LST (°C)", y = "Pixel count", fill = NULL) +
      theme_minimal(base_size = 12)
    
    ggsave(filename = file.path(hist_dir, paste0(scene, "_LST_histogram.png")),
           plot = p_hist, width = 8, height = 5, dpi = 150)
  }
  
  summary_list[[length(summary_list) + 1]] <- data.frame(
    Scene = scene,
    Date  = as.Date(date_str),
    Urban_LST = round(urban_mean, 2),
    Rural_LST = round(rural_mean, 2),
    SUHI      = round(suhi_val, 2),
    stringsAsFactors = FALSE
  )
}

# Summary table and plots
if (length(summary_list) > 0) {
  summary_df <- bind_rows(summary_list) %>% arrange(Date)
  write.csv(summary_df, file.path(out_dir, "SUHI_summary.csv"), row.names = FALSE)
  
  p_suhi <- ggplot(summary_df, aes(x = Date, y = SUHI)) +
    geom_line(color = "#D64F4B", linewidth = 1) +
    geom_point(size = 2, color = "#A23A35") +
    labs(title = "Time Series of SUHI Intensity (Urban − Rural, °C)", x = NULL, y = "SUHI (°C)") +
    theme_minimal(base_size = 12)
  ggsave(filename = file.path(out_dir, "SUHI_time_series.png"),
         plot = p_suhi, width = 8, height = 5, dpi = 150)
  
  df_long <- summary_df %>%
    pivot_longer(cols = c("Urban_LST", "Rural_LST"), names_to = "Class", values_to = "LST")
  
  p_lsts <- ggplot(df_long, aes(x = Date, y = LST, color = Class, group = Class)) +
    geom_line(linewidth = 1) +
    geom_point(size = 2) +
    scale_color_manual(values = c("Urban_LST"="#D64F4B", "Rural_LST"="#1f77b4"),
                       breaks = c("Urban_LST","Rural_LST"),
                       labels = c("Urban mean LST", "Rural mean LST")) +
    labs(title = "Urban vs Rural Mean LST (°C)", x = NULL, y = "Mean LST (°C)", color = NULL) +
    theme_minimal(base_size = 12)
  ggsave(filename = file.path(out_dir, "Urban_Rural_LST_plot.png"),
         plot = p_lsts, width = 8, height = 5, dpi = 150)
}
