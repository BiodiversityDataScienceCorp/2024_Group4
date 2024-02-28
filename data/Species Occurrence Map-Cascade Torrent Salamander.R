#installing packages
#list of packages
packages<-c("tidyverse", "rgbif", "usethis", "CoordinateCleaner", "leaflet", "mapview", "webshot2")

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

fData<-d %>%
  filter(!is.na(decimalLatitude),!is.na(decimalLongitude))

fData<-fData %>%
  filter(countryCode %in% c("US", "CA", "MX"))

fData<-fData %>%
  filter(! basisOfRecord %in% c("FOSSIL_SPECIMEN", "LIVING_SPECIMEN"))

fData<-fData %>%
  cc_sea(lon="decimalLongitude", lat="decimalLatitude")

fData<-fData %>%
  distinct(decimalLongitude, decimalLatitude,speciesKey, datasetKey,.keep_all = TRUE)


write_csv(d, file="data/cleanData.csv")

