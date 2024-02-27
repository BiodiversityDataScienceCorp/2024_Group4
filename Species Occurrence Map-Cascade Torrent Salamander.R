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

salamanderBackbone<-name_backbone(name="Rhyacotriton cascadae")
speciesKey<-salamanderBackbone$usageKey

occ_download(pred("taxonKey", speciesKey), format="SIMPLE_CSV")

View(salamanderBackbone)

d <- occ_download_get('0022330-240216155721649', path="data/") %>%
  occ_download_import()

View(d)

write_csv(d, file="data/rawData.csv")

