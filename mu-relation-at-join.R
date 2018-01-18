## requires sharpshootR >= 1.3.5

library(rgdal)
library(sharpshootR)
library(igraph)

# load join document
x <- readOGR(dsn='CA630', layer = 'CA630_join_lines', stringsAsFactors = FALSE)

# get relationship from left / right musym

# select mu
par(mar=c(0,0,0,0), mfcol=c(1,3))
mu.set <- c('5012', '5201', '7085')

for(i in mu.set) {
  a <- joinAdjacency(x[which(x$l_musym == i), ])
  
  g <- plotSoilRelationGraph(a, edge.scaling.factor=1, vertex.scaling.factor = 2, edge.transparency = 0)
  title(i, line=-2)
}

