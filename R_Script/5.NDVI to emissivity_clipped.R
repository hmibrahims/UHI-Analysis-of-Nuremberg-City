#Author Name: Ibrahim Khalil
#Date: 10.09.2025
#Content Name: Extracting Emissivity from NDVI
#------------------------------------------------




library(terra)

# Paths
root     <- "E:/Course&Class/SFRS"
in_ndvi  <- file.path(root, "_ndvi_clipped")
out_emis <- file.path(root, "_emissivity_clipped"); dir.create(out_emis, FALSE, TRUE)

# Scene folders
scenes <- list.dirs(in_ndvi, recursive = FALSE, full.names = FALSE)
scenes <- scenes[grepl("^20", scenes)]

for (scn in scenes) {
  ndvif <- list.files(file.path(in_ndvi, scn),
                      pattern = "NDVI.*_clipped\\.(tif|TIF)$",
                      full.names = TRUE, ignore.case = TRUE)
  if (!length(ndvif)) next
  
  ndvi <- rast(ndvif[1])
  
  # Emissivity via NDVI-threshold method
  emis <- classify(ndvi, rcl = matrix(c(-Inf, 0.2, 0.970,
                                        0.5,  Inf, 0.990),
                                      ncol = 3, byrow = TRUE))
  mid  <- ndvi >= 0.2 & ndvi <= 0.5
  Pv   <- ((ndvi - 0.2) / 0.3)^2
  emis[mid] <- 0.004 * Pv[mid] + 0.986
  
  # Optional water mask
  emis[ndvi < 0] <- NA
  
  # Save
  od <- file.path(out_emis, scn); dir.create(od, FALSE, TRUE)
  out_file <- file.path(od, paste0(scn, "_emissivity_clipped.tif"))
  writeRaster(emis, out_file, overwrite = TRUE,
              wopt = list(datatype = "FLT4S",
                          gdal = c("COMPRESS=LZW","TILED=YES","BIGTIFF=YES")))
}
