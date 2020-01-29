load("mic_atlases.Rda")
library(tidyverse)
library(ggseg)

# Put in region names
lookup <- read.csv("/Users/butellyn/Documents/hiLo/data/hilo_images/jlf_lookup/jlf_lookup.csv")
lookup <- lookup[94:201,]
lookup$ROI_INDEX <- lookup$ROI_INDEX - 99
rownames(lookup) <- 1:nrow(lookup)

for (i in lookup$ROI_INDEX) {
  istr <- paste0("_", i, "_")
  theserows <- rownames(mic.df.final[mic.df.final$region %in% grep(istr, mic.df.final$region, value=TRUE),])
  mic.df.final$region <- gsub("100", mic.df.final$region


}


micCort <- mic.df.final %>%
  mutate(hemi = case_when(hemi == "lh" ~ "left",
                          hemi == "rh" ~ "right"),
         side = case_when(side == "lat" ~ "lateral",
                          side == "med" ~ "medial"),
         area = ifelse(grepl("wall", area), NA, area),
         pos = NA,
         atlas = "micCort",
         area = gsub(" division", "", area),
         area = gsub("anterior", "ant.", area),
         area = gsub("posterior", "post.", area),
         area = gsub(" formerly Supplementary Motor Cortex ", "", area),
         area = gsub("Inferior", "Inf.", area),
         area = gsub("inferior", "inf.", area),
         area = gsub("Superior", "Sup.", area),
         area = gsub("Lateral", "Lat.", area),
         area = gsub("Middle", "Mid.", area),
         area = gsub(" part", "", area),
         )


micCort <- micCort %>%
  unnest(ggseg) %>%
  select(-.pos)
micCort <- as_ggseg_atlas(micCort)
usethis::use_data(micCort, internal = FALSE, overwrite = TRUE, compress = "xz")
