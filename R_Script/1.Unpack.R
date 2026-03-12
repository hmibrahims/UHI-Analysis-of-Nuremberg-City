#Author Name: Ibrahim Khalil
#Date: 10.09.2025
#Content Name: Unpacking .tar files
#----------------------------------------


setwd("E:/Course&Class/SFRS")

zip_files_list <- list.files(pattern = "\\.tar$")

if (length(zip_files_list) == 0) {
  stop("No .tar files found in the directory.")
}

for (zip in zip_files_list) {
  filename <- substr(basename(zip), 1, nchar(basename(zip)) - 4)
  
  year  <- substr(filename, 18, 21)
  month <- substr(filename, 22, 23)
  day   <- substr(filename, 24, 25)
  path  <- substr(filename, 11, 13)
  row   <- substr(filename, 14, 16)
  sat   <- substr(filename, 1, 4)
  
  outname <- paste0(year, "-", month, "-", day, "_", sat, "_", path, "_", row)
  
  untar(zip, exdir = outname)
}
