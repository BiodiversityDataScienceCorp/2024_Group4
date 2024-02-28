# Read in the data
data <- read.csv("data/cleanData.csv")

# Load libraries
library(leaflet)
library(mapview)
library(webshot2) # Needed to save the map!

# Generate occurrence map
map <- leaflet(options = leafletOptions(zoomControl = FALSE)) %>% # The options bit removes the zoom button
  
  # Add base map
  # More options here: https://leaflet-extras.github.io/leaflet-providers/preview/
  addProviderTiles("Esri.WorldTopoMap") %>%
  
  # Add occurrence points
  addCircleMarkers(data = data,
                   lat = ~decimalLatitude,
                   lng = ~decimalLongitude,
                   radius = 3,
                   color = "brown",
                   fillOpacity = 0.8) %>%
  
  # Add the legend / title
  addLegend(position = "topright",
            title = "Species Occurences from GBIF",
            labels = "Habronattus americanus",
            colors = "brown",
            opacity = 0)

# Save the map
mapshot2(map, file = "output/leafletTest.png")

