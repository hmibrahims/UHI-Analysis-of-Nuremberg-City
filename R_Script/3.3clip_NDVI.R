#Author Name: Ibrahim Khalil
#Date: 10.09.2025
#Content Name: Clip NDVI with AOI shapefile
#--------------------------------------------

library(terra)

# Paths
root     <- "E:/Course&Class/SFRS"
in_ndvi  <- file.path(root, "_ndvi_masked")
out_ndvi <- file.path(root, "_ndvi_clipped"); dir.create(out_ndvi, FALSE, TRUE)

# AOI
aoi <- vect(file.path(root, "n_shapefile", "AOI.shp"))

# Scene folders
scenes <- list.dirs(in_ndvi, recursive = FALSE, full.names = FALSE)
scenes <- scenes[grepl("^20", scenes)]

for (scn in scenes) {
  ndvif <- list.files(file.path(in_ndvi, scn), pattern = "NDVI.*\\.(tif|TIF)$",
                      full.names = TRUE, ignore.case = TRUE)
  if (!length(ndvif)) next
  
  ndvi <- rast(ndvif[1])
  
  # Clip and mask to AOI
  ndvi_clip <- mask(crop(ndvi, aoi), aoi)
  
  # Save
  od <- file.path(out_ndvi, scn); dir.create(od, FALSE, TRUE)
  out_file <- file.path(od, paste0(scn, "_NDVI_clipped.tif"))
  writeRaster(ndvi_clip, out_file, overwrite = TRUE,
              wopt = list(datatype = "FLT4S",
                          gdal = c("COMPRESS=LZW","TILED=YES","BIGTIFF=YES")))
}
