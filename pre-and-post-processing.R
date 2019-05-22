
## TODO: join ID hash should include left/right map unit symbols

library(rgdal)
library(sharpshootR)

## pre-processing: get the data from FGB and save as SHP in working dir

# SEKI
x <- readOGR(dsn='l:/NRCS/MLRAShared/CA792/ca792_spatial/FG_CA792_OFFICIAL.gdb', layer='ca792_a')
writeOGR(x, dsn='CA792', layer='ca792_official', driver = 'ESRI Shapefile', overwrite_layer = TRUE)

# CA630
x <- readOGR(dsn='l:/NRCS/MLRAShared/CA630/Archived_OFFICIAL_DB/final/FG_CA630_GIS_2018.gdb', layer='ca630_a')
writeOGR(x, dsn='CA630', layer='ca630_official', driver = 'ESRI Shapefile', overwrite_layer = TRUE)


## send to PostGIS / GRASS for the hard stuff



##
## post-processing: generate a join decision / line segment ID
##

# toggle this for selecting surveys
ssa <- 'CA792'
line_file <- sprintf('%s_join_lines', ssa)

date <- Sys.Date()
output <- sprintf('l:/NRCS/MLRAShared/%s/join-document/%s', ssa, date)

# load data from basho/GRASS
x <- readOGR(dsn=ssa, layer = line_file, stringsAsFactors = FALSE)

# make a unique ID for joing decisions that should survive subsequent re-generation of the join document
# this function tests for collisions
x$jd_id <- generateLineHash(x)

# add left/right musymbols to join ID
x$jd_id <- sprintf("%s-%s-%s", x$l_musym, x$r_musym, x$jd_id)

# save new version to standard location
writeOGR(x, dsn=output, layer='join_lines', driver = 'ESRI Shapefile', overwrite_layer = TRUE)
write.csv(x@data, file=paste0(output, '/text-version.csv'), row.names=FALSE)


## TODO: symbolize vertices differently depending on inside/outside of SSA

## make network diagram:
a <- joinAdjacency(x)

pdf(file=paste0(output, '/network-diagram.pdf'), width = 30, height = 30)
par(mar=c(0,0,0,0))
plotSoilRelationGraph(a, , edge.scaling.factor=1, vertex.scaling.factor = 2, edge.col = 'black')
dev.off()


