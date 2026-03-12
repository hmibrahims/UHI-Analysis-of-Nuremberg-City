#Author Name: Ibrahim Khalil
#Date: 10.09.2025
#Content Name: TOA reflectence to NDVI
#----------------------------------------


library(terra)

# Paths
root     <- "E:/Course&Class/SFRS"
in_ref   <- file.path(root, "_toa_reflectance_masked")
out_ndvi <- file.path(root, "_ndvi_masked"); dir.create(out_ndvi, FALSE, TRUE)

# Scene folders
scenes <- list.dirs(in_ref, recursive = FALSE, full.names = FALSE)
scenes <- scenes[grepl("^20", scenes)]

# NDVI calculation
for (scn in scenes) {
  ref_dir <- file.path(in_ref, scn)
  od      <- file.path(out_ndvi, scn); dir.create(od, FALSE, TRUE)
  
  f4 <- list.files(ref_dir, pattern = "_B4.*_toa\\.(tif|TIF)$", full.names = TRUE, ignore.case = TRUE)
  f5 <- list.files(ref_dir, pattern = "_B5.*_toa\\.(tif|TIF)$", full.names = TRUE, ignore.case = TRUE)
  if (!length(f4) || !length(f5)) next
  
  r4 <- rast(f4[1])
  r5 <- rast(f5[1])
  
  if (!compareGeom(r4, r5, stopOnError = FALSE)) {
    r5 <- resample(r5, r4, method = "bilinear")
  }
  
  ndvi <- (r5 - r4) / (r5 + r4)
  ndvi[(r5 + r4) == 0] <- NA
  ndvi <- clamp(ndvi, -1, 1)
  
  out_name <- file.path(od, paste0(scn, "_NDVI_toa_masked.tif"))
  writeRaster(ndvi, out_name, overwrite = TRUE,
              wopt = list(datatype = "FLT4S",
                          gdal = c("COMPRESS=LZW","TILED=YES")))
}
