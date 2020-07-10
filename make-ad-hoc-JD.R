library(sp)
library(spdep)
library(rgdal)
library(igraph)
library(sharpshootR)
library(latticeExtra)
library(sf)

# input
ca614 <- readOGR('FGDB_CA614_update_2020_0619_TK.gdb', layer='ca614_a', stringsAsFactors = FALSE)
ca719 <- readOGR('FGDB_CA719_update_2020_0619_TK.gdb', layer='ca719_a', stringsAsFactors = FALSE)

# check
str(ca614@data)
str(ca719@data)

# check for symbol collisions
# --> 'W'
intersect(ca614$orig_musym, ca719$orig_musym)

# remove colliding symbols
ca614 <- ca614[ca614$orig_musym != 'W', ]
ca719 <- ca719[ca719$orig_musym != 'W', ]

## main question: which symbols are borrowed from the other SSA at the boundary?

# needle: vector of MUSYM in reference SSA
# haystack: vector of MUSYM in adjacent SSA
# label: label for borrowed source
# output is same length / order as needle
borrowedSymbol <- function(needle, haystack, label) {
  
  # empty vector of appropriate length
  b <- rep(NA, times=length(needle))
  
  # fine needles in haystack
  idx <- which(needle %in% unique(haystack))
  # tag with source
  b[idx] <- label
  
  return(b)
}

# symbols borrowed from CA719
ca614$b <- borrowedSymbol(ca614$MUSYM, ca719$orig_musym, 'CA719')

# symbols borrowed from CA614
ca719$b <- borrowedSymbol(ca719$MUSYM, ca614$orig_musym, 'CA614')


# check: frequency of borrowing, each instance is a delineation
(bs.ca614 <- sort(table(ca614$MUSYM[! is.na(ca614$b)]), decreasing = TRUE))
(bs.ca719 <- sort(table(ca719$MUSYM[! is.na(ca719$b)]), decreasing = TRUE))

## save simple report to file
cat('Borrowed Symbol Frequency\n', file='borrowed-symbols.txt')

cat('\nCA614 <--- CA719\n================\n', file='borrowed-symbols.txt', append = TRUE)
cat(sprintf("%s: %s", names(bs.ca614), bs.ca614), file='borrowed-symbols.txt', append = TRUE, sep='\n')

cat('\nCA719 <--- CA614\n================\n', file='borrowed-symbols.txt', append = TRUE)
cat(sprintf("%s: %s", names(bs.ca719), bs.ca719), file='borrowed-symbols.txt', append = TRUE, sep='\n')




## simplify and prepare for spatial join

#  add unique feature ID
ca614$id <- 1:nrow(ca614)
ca719$id <- 1:nrow(ca719)

vars <- c('id', 'AREASYMBOL', 'MUSYM', 'orig_musym', 'b')
ca614 <- ca614[, vars]
ca719 <- ca719[, vars]


# shorten names
names(ca614) <- c('id', 'SSA', 'MUSYM', 'o_musym', 'b')
names(ca719) <- c('id', 'SSA', 'MUSYM', 'o_musym', 'b')

# convert to sf
ca614.sf <- st_as_sf(ca614)
ca719.sf <- st_as_sf(ca719)


## note: st_touches() will create extra rows:
## * 1D (corners) touching
## * 2D (shared edges) touching
##
## use st_relate(): https://r-spatial.github.io/sf/reference/st_relate.html
##


## test case:
ca719.test <- ca719.sf[which(ca719.sf$id == 10613), ]
# single delineation
plot(ca719.test['MUSYM'])

# touching, any dimensionality
x <- st_join(
  ca719.test,
  ca614.sf,
  join = st_touches,
  suffix = c('.left', '.right'),
  left = FALSE
)

# 1D and 2D results, this is not what we want
nrow(x)

# touching, 1D along boundary only
x <- st_join(
  ca719.test,
  ca614.sf,
  join = st_relate, pattern = '****1****',
  suffix = c('.left', '.right'),
  left = FALSE
)

# this is correct
nrow(x)



## two joins required, all interesting information is in *.left columns

# CA614 -> CA719 join
# keep only touching features
g.1 <- st_join(
  ca614.sf,
  ca719.sf,
  join = st_relate, pattern = '****1****',
  suffix = c('.left', '.right'),
  left = FALSE
)

# CA719 -> CA614 join
# keep only touching features
g.2 <- st_join(
  ca719.sf,
  ca614.sf,
  join = st_relate, pattern = '****1****',
  suffix = c('.left', '.right'),
  left = FALSE
)

## double-check this:

# save a copy of join for error checking:
g.1.full <- g.1
g.2.full <- g.2


# left / right symbols do not match
idx <- which(g.1.full$MUSYM.left != g.1.full$MUSYM.right)
g.1.errors <- g.1.full[idx, ]

# remove false positives '*sv'
idx <- grep('sv', g.1.errors$MUSYM.right, invert = TRUE)
g.1.errors <- g.1.errors[idx, ]

plot(g.1.errors[c('MUSYM.left')])

# connotative label for flagged joins
g.1.errors$err <- sprintf("%s -> %s", g.1.errors$MUSYM.left, g.1.errors$MUSYM.right)

# save to SHP
g.1.errors <- as(g.1.errors, 'Spatial')
writeOGR(g.1.errors, dsn = '.', layer = 'errors', overwrite_layer = TRUE, driver='ESRI Shapefile')





# keep only those delineations with borrowed symbols
g.1 <- g.1[!is.na(g.1$b.left), ]
g.2 <- g.2[!is.na(g.2$b.left), ]

plot(g.1[, c('b.left')], main='Borrowed Symbols', key.pos=1)
plot(g.2[, c('b.left')], main='Borrowed Symbols', key.pos=1)

# check ids
plot(g.1[, c('id.left')], main='Borrowed Symbols', key.pos=1)
plot(g.2[, c('id.left')], main='Borrowed Symbols', key.pos=1)

# combine
z <- rbind(g.1, g.2)

# graphical check: OK
plot(z[, c('b.left')], main='Borrowed Symbols', key.pos=1)

# remove most .right columns by name
nm <- c('SSA.right', 'MUSYM.right', 'o_musym.right', 'b.right')

for(i in nm) {
  z[[i]] <- NULL
}

# check: OK
z


# this next part requires SP class
z.sp <- as(z, 'Spatial')

# save a copy
writeOGR(z.sp, dsn = '.', layer = 'joinDoc', overwrite_layer = TRUE, driver='ESRI Shapefile')






