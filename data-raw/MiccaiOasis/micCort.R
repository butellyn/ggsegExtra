load("mic_atlases.Rda")
library(tidyverse)
library(ggseg)

# Put in region names
lookup <- read.csv("/Users/butellyn/Documents/ggsegExtra/data-raw/MiccaiOasis/jlf_lookup.csv")
lookup <- lookup[94:201,]
lookup$ROI_INDEX <- lookup$ROI_INDEX - 99
rownames(lookup) <- 1:nrow(lookup)

for (i in lookup$ROI_INDEX) {
  istr <- paste0("_", i, "_")
  theserows <- which(c(mic.df.final$region %in% grep(istr, mic.df.final$region, value=TRUE)))
  roi <- strsplit(as.character(lookup[i, "ROI_NAME"]), "_")[[1]][2]
  mic.df.final[theserows, "region"] <- gsub(i, roi, mic.df.final[theserows[1], "region"])
  mic.df.final[theserows, "area"] <- roi
  mic.df.final[theserows, "label"] <- gsub(i, roi, mic.df.final[theserows[1], "label"])
}

micCort <- mic.df.final %>%
  mutate(hemi = case_when(hemi == "lh" ~ "left",
                          hemi == "rh" ~ "right"),
         side = case_when(side == "lat" ~ "lateral",
                          side == "med" ~ "medial"),
         area = ifelse(grepl("wall", area), NA, area),
         pos = NA,
         atlas = "micCort",
         )

         micCort$pos[1] <- list(x = 1)
         for(i in 1:nrow(micCort)){
           micCort$pos[[i]] = list(
             stacked = list(
               x = list(breaks = c(250, 900),
                        labels = c("lateral", "medial")),
               y = list(breaks = c(200,  600),
                        labels = c("left", "right")), labs = list(
                          y = "side", x = "hemisphere")),
             dispersed = list(
               x = list(
                 breaks = c(580, 1800),
                 labels = c("left", "right")),
               y = list(breaks = NULL, labels = ""),
               labs = list(y = NULL, x = "hemisphere")))
         }

#micCort <- micCort %>%
#  unnest(ggseg) %>% #Error: `ggseg` must evaluate to column positions or names, not a function
#  select(-.pos)



micCort <- as_ggseg_atlas(micCort)
usethis::use_data(micCort, internal = FALSE, overwrite = TRUE, compress = "xz")
