## requires sharpshootR >= 1.3.5

library(rgdal)
library(sharpshootR)
library(igraph)


x <- readOGR(dsn='CA630', layer = 'CA630_join_lines', stringsAsFactors = FALSE)

# get relationship from left / right musym
a <- joinAdjacency(x[x$l_musym == '5012', ])

a <- joinAdjacency(x[x$l_musym == '7085', ])

a <- joinAdjacency(x[x$l_musym == '5201', ])

a <- joinAdjacency(x)

par(mar=c(0,0,0,0))
r <- plotSoilRelationGraph(a, spanning.tree='max', edge.scaling.factor=1, vertex.scaling.factor = 2, edge.transparency = 0)


r <- plotSoilRelationGraph(a, spanning.tree=0.5, edge.scaling.factor=1, vertex.scaling.factor = 2, edge.transparency = 0)

# investigate linkages for select map units

E(r)$weight


