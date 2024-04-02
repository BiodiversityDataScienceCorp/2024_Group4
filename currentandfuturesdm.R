# scripts for generating current and future Species Distribution Models

#### Start Current SDM ######
# 0. Load packages

source("src/packages.R")

# 1. Get occurrence Data 

# start with our data

#get our occurrence data, just lat/lon

occurrenceCoords<-read_csv("data/cleanData.csv") %>%
  dplyr::select( decimalLongitude, decimalLatitude)

#convert to spatial points for model 
occurrenceSpatialPts <- SpatialPoints(occurrenceCoords, 
                                      proj4string = CRS("+proj=longlat"))


# now get the climate data
# make sure RAM is bumped up

#this downloads 19 raster files, one for each climate variable
worldclim_global(var="bio", res=2.5, path="data/", version="2.1") 

# update .gitignore to prevent huge files getting pushed to github

#Here are the meanings of the bioclimatic variables (bio1 to bio19) provided by WorldClim:
#bio1: Mean annual temperature
#bio2: Mean diurnal range (mean of monthly (max temp - min temp))
#bio3: Isothermality (bio2/bio7) (* 100)
#bio4: Temperature seasonality (standard deviation *100)
#bio5: Max temperature of warmest month
#bio6: Min temperature of coldest month
#bio7: Temperature annual range (bio5-bio6)
#bio8: Mean temperature of wettest quarter
#bio9: Mean temperature of driest quarter
#bio10: Mean temperature of warmest quarter
#bio11: Mean temperature of coldest quarter
#bio12: Annual precipitation
#bio13: Precipitation of wettest month
#bio14: Precipitation of driest month
#bio15: Precipitation seasonality (coefficient of variation)
#bio16: Precipitation of wettest quarter
#bio17: Precipitation of driest quarter
#bio18: Precipitation of warmest quarter
#bio19: Precipitation of coldest quarter





#let's create a raster stack (stack of layers/variables)
#list of files
climList <- list.files(path = "data/wc2.1_2.5m/", 
                       pattern = ".tif$", 
                       full.names = T)



#create the raster stack from the files list
currentClimRasterStack <- raster::stack(climList)

# plot annual temperature, just to test
plot(currentClimRasterStack[[1]]) 


plot(occurrenceSpatialPts, add = TRUE) 




#2. Create pseudo-absence points

#mask is the raster object that determines the area we're interested in
mask <- raster(climList[[1]]) 

#drill down on where our data lives
geographicExtent <- extent(x = occurrenceSpatialPts)

# standardize random points for reproducibility

set.seed(45) 

#create psuedo-absence points
backgroundPoints <- randomPoints(mask = mask, 
                                 n = nrow(occurrenceCoords), #same n 
                                 ext = geographicExtent, 
                                 extf = 1.25, # draw a slightly larger area 
                                 warn = 0) 


#change column names
colnames(backgroundPoints) <- c("longitude", "latitude")


# 3. Convert occurrence and environmental data into format for model

# Data for observation sites (presence and background), with climate data

#create a grid of climate measurements, per occurrence point

occEnv <- na.omit(raster::extract(x = currentClimRasterStack, y = occurrenceCoords))

#create a grid of measurements for the pseudo absence points
absenceEnv<- na.omit(raster::extract(x = currentClimRasterStack, y = backgroundPoints))


#create a vector of presence/absence 
presenceAbsenceV <- c(rep(1, nrow(occEnv)), rep(0, nrow(absenceEnv))) 

#create a single data fram of presence/absence data by climate variable
presenceAbsenceEnvDf <- as.data.frame(rbind(occEnv, absenceEnv))


# 4. Create Current SDM with maxent


# If you get a Java error, restart R, and reload the packages
salamanderCurrentSDM <- dismo::maxent(x = presenceAbsenceEnvDf, ## env conditions
                                       p = presenceAbsenceV,   ## 1:presence or 0:absence
                                       path=paste("maxent_outputs"), #maxent output dir 
)                              


# 5. Plot the current SDM with ggplot


# bump up our bounding box
predictExtent <- 5 * geographicExtent 

#crops the geographic area 
geographicArea <- crop(currentClimRasterStack, predictExtent, snap = "in")


#make a raster layer for the map, combining everything
salamanderPredictPlot <- raster::predict(salamanderCurrentSDM, geographicArea) 


#create spacial pixels data frame
raster.spdf <- as(salamanderPredictPlot, "SpatialPixelsDataFrame")

#create data frame
salamanderPredictDf <- as.data.frame(raster.spdf)

#get world boundaries
wrld <- ggplot2::map_data("world")


#create bounding box
xmax <- max(salamanderPredictDf$x)
xmin <- min(salamanderPredictDf$x)
ymax <- max(salamanderPredictDf$y)
ymin <- min(salamanderPredictDf$y)

xmin<--125
xmax<--118.5
ggplot() +
  geom_polygon(data = wrld, mapping = aes(x = long, y = lat, group = group),
               fill = "grey75") +
  geom_raster(data = salamanderPredictDf, aes(x = x, y = y, fill = layer)) + 
  scale_fill_gradientn(colors = terrain.colors(10, rev = T)) +
  coord_fixed(xlim = c(xmin, xmax), ylim = c(ymin, ymax), expand = F) +#expand=F fixes margin
  scale_size_area() +
  borders("state") +
  borders("world", colour = "black", fill = NA) + 
  labs(title = "SDM of Rhyacotriton cascadae Under Current Climate Conditions",
       x = "longitude",
       y = "latitude",
       fill = "Environmental Suitability")+ 
  theme(legend.box.background=element_rect(),legend.box.margin=margin(5,5,5,5)) 

#save to file
ggsave("output/salamanderCurrentSdm.jpg",  width = 8, height = 6)

#### End Current SDM #########


#### Start Future SDM ########


# 6. Get Future Climate Projections

# CMIP6 is the most current and accurate modeling data
# More info: https://pcmdi.llnl.gov/CMIP6/

#downloading future climate data
futureClimateRaster <- cmip6_world("CNRM-CM6-1", "585", "2061-2080", var = "bioc", res=2.5, path="data/cmip6")

# 7. Prep for the model


names(futureClimateRaster)=names(currentClimRasterStack)


geographicAreaFutureC6 <- crop(futureClimateRaster, predictExtent)


# 8. Run the future SDM

salamanderFutureSDM <- raster::predict(salamanderCurrentSDM, geographicAreaFutureC6)


# 9. Plot the future SDM


salamanderFutureSDMDf <- as.data.frame(salamanderFutureSDM, xy=TRUE)


xmax <- max(salamanderFutureSDMDf$x)
xmin <- min(salamanderFutureSDMDf$x)
ymax <- max(salamanderFutureSDMDf$y)
ymin <- min(salamanderFutureSDMDf$y) 

xmin<--125
xmax<--118.5


ggplot() +
  geom_polygon(data = wrld, mapping = aes(x = long, y = lat, group = group),
               fill = "grey75") +
  geom_raster(data = salamanderFutureSDMDf, aes(x = x, y = y, fill = maxent)) + 
  scale_fill_gradientn(colors = terrain.colors(10, rev = T)) +
  coord_fixed(xlim = c(xmin, xmax), ylim = c(ymin, ymax), expand = F) +
  scale_size_area() +
  borders("state") +
  borders("world", colour = "black", fill = NA) + 
  labs(title = "Future SDM of Rhyacotriton cascadae Under CMIP6 Climate Conditions",
       x = "longitude",
       y = "latitude",
       fill = "Env Suitability") +
  theme(legend.box.background=element_rect(),legend.box.margin=margin(5,5,5,5)) 

ggsave("output/salamanderFutureSdm.jpg",  width = 8, height = 6)



##### END FUTURE SDM ######
