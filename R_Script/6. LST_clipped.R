#Author Name: Ibrahim Khalil
#Date: 10.09.2025
#Content Name: Clip LST with AOI file
#-------------------------------------




library(terra)

# Paths
root    <- "E:/Course&Class/SFRS"
in_bt   <- file.path(root, "_bt_clipped")
in_emis <- file.path(root, "_emissivity_clipped")
out_lst <- file.path(root, "_lst_clipped"); dir.create(out_lst, FALSE, TRUE)

# Scenes present in both inputs
scenes <- intersect(
  list.dirs(in_bt,   recursive = FALSE, full.names = FALSE),
  list.dirs(in_emis, recursive = FALSE, full.names = FALSE)
)
scenes <- scenes[grepl("^20", scenes)]

# Constants for emissivity correction (Landsat 8 Band 10)
lambda <- 10.895e-6  # meters
c2     <- 1.4388e-2  # m*K

for (scn in scenes) {
  btf <- list.files(file.path(in_bt, scn),
                    pattern = "_BT_clipped\\.(tif|TIF)$",
                    full.names = TRUE, ignore.case = TRUE)
  ef  <- list.files(file.path(in_emis, scn),
                    pattern = "_emissivity_clipped\\.(tif|TIF)$",
                    full.names = TRUE, ignore.case = TRUE)
  if (!length(btf) || !length(ef)) next
  
  BT   <- rast(btf[1])   # Kelvin
  emis <- rast(ef[1])    # 0–1
  
  if (!compareGeom(BT, emis, stopOnError = FALSE)) {
    emis <- resample(emis, BT, method = "bilinear")
  }
  
  emis[emis <= 0] <- NA
  
  # LST in Kelvin, then Celsius
  LSTk <- BT / (1 + (lambda * BT / c2) * log(emis))
  LSTc <- LSTk - 273.15
  
  od <- file.path(out_lst, scn); dir.create(od, FALSE, TRUE)
  out <- file.path(od, paste0(scn, "_LST_C_clipped.tif"))
  writeRaster(LSTc, out, overwrite = TRUE,
              wopt = list(datatype = "FLT4S",
                          gdal = c("COMPRESS=LZW","TILED=YES","BIGTIFF=YES")))
}
