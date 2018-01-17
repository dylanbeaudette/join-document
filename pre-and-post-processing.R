
## TODO: join ID hash should include left/right map unit symbols
## TODO: save to folder with current date


library(rgdal)
library(sharpshootR)

## pre-processing: get the data from FGB and save as SHP in working dir

# SEKI
x <- readOGR(dsn='l:/NRCS/MLRAShared/CA792/ca792_spatial/FG_CA792_OFFICIAL.gdb', layer='ca792_a')
writeOGR(x, dsn='CA792', layer='ca792_official', driver = 'ESRI Shapefile', overwrite_layer = TRUE)

# CA630
x <- readOGR(dsn='l:/NRCS/MLRAShared/CA630/FG_CA630_OFFICIAL.gdb', layer='ca630_a')
writeOGR(x, dsn='CA630', layer='ca630_official', driver = 'ESRI Shapefile', overwrite_layer = TRUE)


## send to PostGIS / GRASS for the hard stuff



##
## post-processing: generate a join decision / line segment ID
##



#
# CA630
#

date <- '2018-01-17'
output <- paste0('l:/NRCS/MLRAShared/CA630/join-document/', date)

# load data from basho/GRASS
x <- readOGR(dsn='CA630', layer = 'CA630_join_lines', stringsAsFactors = FALSE)

# make a unique ID for joing decisions that should survive subsequent re-generation of the join document
x$jd_id <- generateLineHash(x)

# save new version to standard location
writeOGR(x, dsn=output, layer='join_lines', driver = 'ESRI Shapefile', overwrite_layer = TRUE)
write.csv(x@data, file=paste0(output, '/text-version.csv'), row.names=FALSE)

## not all that useful
# make network diagram:
a <- joinAdjacency(x)

pdf(file=paste0(output, '/network-diagram.pdf'), width = 12, height = 12)
par(mar=c(0,0,0,0))
plotSoilRelationGraph(a, spanning.tree='max', edge.scaling.factor=1, vertex.scaling.factor = 2, edge.transparency = 0)
dev.off()



# 
# # SEKI
# x <- readOGR(dsn='CA792', layer = 'join_lines', stringsAsFactors = FALSE)
# # make a unique ID for joing decisions that should survive subsequent re-generation of the join document
# x$jd_id <- generateLineHash(x)
# # save new version to standard location
# writeOGR(x, dsn='L:/CA792/join-document', layer='join_lines', driver = 'ESRI Shapefile', overwrite_layer = TRUE)
# write.csv(x@data, file='L:/CA792/join-document/text-version.csv', row.names=FALSE)
# 
# # make network diagram:
# a <- joinAdjacency(x)
# 
# pdf(file='L:/CA792/join-document/network-diagram.pdf', width = 12, height = 12)
# par(mar=c(0,0,0,0))
# plotSoilRelationGraph(a, spanning.tree='max', edge.scaling.factor=1, vertex.scaling.factor = 2, edge.transparency = 0)
# dev.off()
