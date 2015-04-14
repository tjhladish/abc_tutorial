faceSum <- function(ndice, nfaces) { sum(sample(nfaces,ndice,replace=T)) }

trials <- function(ndice, nfaces, nrolls=10^3,target=7){ rolls <- replicate(nrolls,faceSum(ndice, nfaces)); sum(rolls==target)/nrolls }


ndice = 1:7
nfaces = 2:10
particles = as.data.frame(expand.grid(ndice, nfaces))
names(particles) = c('ndice', 'nfaces')
particles$likelihood = 0.0
particles$likelihood = mapply(trials, particles$ndice, particles$nfaces)
particles$posterior = particles$likelihood/sum(particles$likelihood)

pdf("dice_vs_faces.pdf", width=7, height=5.5)
par(mar=c(4.1,4.1,2,1))
image(nfaces, ndice, matrix(particles$posterior, nrow=length(nfaces), ncol=length(ndice), byrow=T), 
      col=grey.colors(255, start=1, end=0), ylab='Number of dice', xlab='Number of faces')
dev.off()
