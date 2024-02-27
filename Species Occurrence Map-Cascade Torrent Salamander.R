#installing packages
#list of packages
packages<-c("tidyverse", "rgbif", "usethis", "CoordinateCleaner", "leaflet", "mapview")

#install packages not yet installed
installed_packages<-packages %in% rownames(installed.packages())
if(any(installed_packages==FALSE)){
  install.packages(packages[!installed_packages])
}

#packages loading, with library function
invisible(lapply(packages, library, character.only=TRUE))

usethis::edit_r_environ()