### Create color table
### "idx","labels","hex"
###
### Ellyn Butler
### January 10, 2020

library('RColorBrewer')
library('gplots')

#df <- read.csv("/jlf_lookup.csv")


######### GGSEG style, not working #########

#df$hex <- sample(col2hex(grDevices::colors()[grep('gr(a|e)y', grDevices::colors(), invert = T)]), 201)
#colnames(df) <- c("idx", "labels", "hex")


#write.csv(df, "ho.annot.ctab", row.names=FALSE)

######### Freesurfer style #########

df <- read.csv("jlf_lookup.csv")
df <- df[df$ROI_INDEX %in% 100:207,]
rownames(df) <- 1:nrow(df)
df <- df[!(df$ROI_INDEX %in% c(110, 111, 126, 127, 130, 131, 158, 159, 188, 189)),]
rownames(df) <- 1:nrow(df)

# Try re-indexing starting at 0... allowing skipped integers (HOPEFULLY WILL WORK!)
df$ROI_NAME <- as.character(df$ROI_NAME)
df$ROI_INDEX <- df$ROI_INDEX - 99

unrow <- c(0, "unknown")
df <- rbind(unrow, df)

df$R <- sample.int(256, 99)
df$G <- sample.int(256, 99)
df$B <- sample.int(256, 99)
df$A <- 0

df$ROI_INDEX <- as.integer(df$ROI_INDEX)


write.table(df, "miccaiCtab.txt", row.names=FALSE, col.names=FALSE)

df_R <- df[c(1, seq(2, nrow(df), 2)),]
df_L <- df[c(1, seq(3, nrow(df), 2)),]

# Try giving indices that don't match image
df_R$ROI_INDEX <- 0:(nrow(df_R)-1)
df_L$ROI_INDEX <- 0:(nrow(df_L)-1)

write.table(df_R, "miccaiCtab_R.txt", row.names=FALSE, col.names=FALSE)
write.table(df_L, "miccaiCtab_L.txt", row.names=FALSE, col.names=FALSE)
