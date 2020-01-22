library(fslr)
library(tidyverse)
library(raster)
library(stars)
library(sf)
library(rmapshaper)
library(freesurfer)


mri_vol2surf("HarvardOxford-Cortical",
  outfile = "test.rh.mgh",
  opts = c("--mni152reg", "--hemi rh", "--projfrac 0.5"),
  verbose = TRUE)

mri_vol2surf("HarvardOxford-Cortical",
             outfile = "test.lh.mgh",
             opts = c("--mni152reg", "--hemi lh", "--projfrac 0.5"),
             verbose = TRUE)
# ^ This function doesn't seem to exist in the freesurfer package
# Trouble installing V8


OUTDIR="/Users/butellyn/Documents/hiLo/data/ggseg_miccai"
pics <- list.files(path=paste0(OUTDIR, "/miccaiPics"), full.names = TRUE)
pics <- pics[!(pics %in% grep("fsaverage_", pics, value=TRUE))]

region <- basename(pics)
region <- stringr::str_remove(region, "\\.tif")
origlabel <- region

hemi <- stringr::str_extract(region, "^.h")
region <- stringr::str_remove(region, "^.h_")
side <- stringr::str_extract(region, "...$")
region <- stringr::str_remove(region, "_...$")
origlabel <- stringr::str_remove(origlabel, "_...$")
mic.df <- tibble(area=region, hemi=hemi, side=side, label=origlabel)
mic.df <- mutate(mic.df, area=stringr::str_replace_all(area, "\\.+", " "))

rasterobjs <- map(pics, raster)
map_dbl(rasterobjs, cellStats, stat=max)

## check the maximum value
cellStats(rasterobjs[[1]], stat = max)
mkContours <- function(rstobj){
  mx <- raster::cellStats(rstobj, stat=max)
  # Filter out the blank images
  if (mx < 200) {
    return(NULL)
  }
  tmp.rst <- rstobj
  tmp.rst[tmp.rst == 0] <- NA

  ## levels = 50 is to remove the occasional edge point that has
  ## non zero hue.
  #cntr <- raster::rasterToPolygons(rstobj, fun = function(X)X>100, dissolve=TRUE)
  g <- sf::st_as_sf(sf::st_as_stars(tmp.rst), merge=TRUE, connect8=TRUE)
  ## Is it a multipolygon? Keep the biggest bit
  ## Small parts are usually corner connected single voxels
  if (nrow(g)>1) {
    gpa <- st_area(g)
    biggest <- which.max(gpa)
    g <- g[biggest,]
  }
  g <-st_sf(g)
  names(g)[[1]] <- "region"
  g$region <- names(rstobj)
  return(g)

}


contourobjs <- map(rasterobjs, mkContours)
kp <- !map_lgl(contourobjs, is.null)

contourobjsDF <- do.call(rbind, contourobjs)


mic.df <- filter(mic.df, kp)
mic.df <- bind_cols(contourobjsDF, mic.df)
## Now we need to place them into their own panes
## Bounding box for all
bball <- sf::st_bbox(mic.df)
mic.df <-  mutate(mic.df, geometry=geometry - bball[c("xmin", "ymin")])

## ifelse approach doesn't seem to work, so split it up
mic.dfA <- mic.df %>%
  filter(hemi=="lh", side=="med") %>%
  mutate(geometry=geometry+c(600,0))

mic.dfB <- mic.df %>%
  filter(hemi=="rh", side=="med") %>%
  mutate(geometry=geometry+c(2*600,0))

mic.dfC <- mic.df %>%
  filter(hemi=="rh", side=="lat") %>%
  mutate(geometry=geometry+c(3*600,0))

mic.dfD <- mic.df %>%
  filter(hemi=="lh", side=="lat")

mic.df.panes <- rbind(mic.dfD, mic.dfA, mic.dfB, mic.dfC)
#mic.df.panes.simple <- st_simplify(mic.df.panes, preserveTopology = TRUE, dTolerance=0.75)
mic.df.panes.simple <- rmapshaper::ms_simplify(mic.df.panes)

plot(mic.df.panes.simple)

library(ggseg)
library(ggsegExtra)

## Not sure whether the range of values really matters. The other atlases look like they
## may be giving the coordinates in physical units of some sort.
## Lets pretend each picture is 10cm square. Divide point values by 60 at the end.

mic.df.final <- mutate(mic.df.panes.simple,
                      id=1:nrow(mic.df.panes.simple),
                      coords = map(geometry, ~(st_coordinates(.x)[, c("X", "Y")])),
                      coords = map(coords, as.tibble),
                      coords = map(coords, ~mutate(.x, order=1:nrow(.x))))
mic.df.final$geometry <- NULL
mic.df.final <- unnest(mic.df.final, .drop=TRUE)
mic.df.final <- rename(mic.df.final, long=X, lat=Y)
ggseg(atlas=mic.df.final, mapping=aes(fill=area), color="white") +
  theme(legend.position = "none")

save(mic.df.panes.simple, mic.df.final, file="mic_atlases.Rda")
