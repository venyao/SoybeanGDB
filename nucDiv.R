
# A function to calculate nucleotide diversity for different ecotypes using SNP data in a specified genomic region.
# Change to the directory of MaizeSNPDB using the setwd function of R.
# Usage: type the next three lines in R Console without the leading #
# source("Global.R")
# nuc.div.plot <- nucDiv(chr="chr12", nuc.start=5609599, nuc.end=5630626, step=20, groups=c("Glycine soja", "Improved cultivar"), numerator="Glycine soja", denominator="Improved cultivar", mutType = NULL)
# grid.draw(grid.arrange(nuc.div.plot[[1]], nuc.div.plot[[2]], ncol=1, heights=c(2.3, 1)))
# Then the nucleotide diversity in this region would be displayed in a plotting device.
# For more info, please check the Diversity menu of the MaizeSNPDB database.

nucDiv <- function(chr="chr12", nuc.start=5609599, nuc.end=5630626, step=20, 
                   groups=c("Glycine soja", "Improved cultivar"), numerator="Glycine soja", denominator="Improved cultivar",
                   mutType = NULL) {
  
  if ( exists("fetchSnpAllele") ){
  }else{
    source("fetchSnpAllele.R")
  }
  #library(pegas)
  data <- fetchSnpAllele(chr=chr, start=nuc.start, end=nuc.end, mutType = mutType)[[1]]
  
  gene.info$start <- as.numeric(gene.info$start)
  gene.info$end <- as.numeric(gene.info$end)
  data.L <- gsub("/.+", "", data)
  data.R <- gsub(".+/", "", data)
  colnames(data.L) <- paste0(colnames(data.L), ".L")
  colnames(data.R) <- paste0(colnames(data.R), ".R")
  dat.mat <- t(cbind(data.L, data.R))
  dat.mat[is.na(dat.mat)] <- "-"
  dat.bin <- ape::as.DNAbin(dat.mat)
  
  div.group <- lapply(unique(c(groups, numerator, denominator)), function(x){
    x.accession <- readLines(paste0("./data/", x, ".soya.txt"))
    x.accession.L <- paste0(x.accession, ".L")
    x.accession.R <- paste0(x.accession, ".R")
    dat <- dat.bin[rownames(dat.bin) %in% c(x.accession.L, x.accession.R), ]
    
    nuc.div <- lapply(seq(1, ncol(dat.bin), by=step), function(i){
      dat.i <- dat[, i:min(i+step-1, ncol(dat.bin))]
      
      # if(!is.matrix(dat.i)) {return(NULL)}
      div <- pegas::nuc.div(dat.i, pairwise.deletion = TRUE)
      
      return(div)
    })
    
    nuc.div.df <- do.call(rbind,  nuc.div)
    nuc.div.df <- data.frame(nuc.div.df, stringsAsFactors = FALSE)
  })
  
  div.group.df <- do.call(cbind, div.group)
  names(div.group.df) <- unique(c(groups, numerator, denominator))
  dat.pos <- as.numeric(substr(colnames(dat.mat), 3, 10))
  nuc.pos <- dat.pos[seq(1, ncol(dat.mat), by=step)][1:nrow(div.group.df)]
  div.group.df$pos <- nuc.pos
  
  diVTxt <<- div.group.df
  diVTxt <<- diVTxt[, c(ncol(diVTxt), 1:(ncol(diVTxt)-1))]
  names(diVTxt)[1] <<- "position"
  
  div.group.df.1 <- div.group.df[, c("pos", groups)]
  div.group.df.2 <- div.group.df[, c("pos", numerator, denominator)]
  
  div.group.df.1.long <- tidyr::gather(div.group.df.1, group, diversity, -pos)
  div.group.df.2.long <- tidyr::gather(div.group.df.2, group, diversity, -pos)
  
  nuc.chr <- substr(chr, 4, 5)
  nuc.gene.info <- gene.info
  nuc.gene.info$chr <- substr(nuc.gene.info$chr, 4, 5)
  nuc.gene.info <- nuc.gene.info[nuc.gene.info$chr==nuc.chr & 
                                 nuc.gene.info$start>=as.numeric(nuc.start) &
                                 nuc.gene.info$end<=as.numeric(nuc.end), ]
  
  ###order c("Glycine soja", "Landrace", "Improved cultivar")
  div.group.df.1.long$group <- factor(div.group.df.1.long$group, levels = c("Glycine soja", "Landrace", "Improved cultivar")[c("Glycine soja", "Landrace", "Improved cultivar") %in% unique(div.group.df.1.long$group)] )
  p1 <- ggplot2::ggplot(div.group.df.1.long) + ggplot2::geom_line(ggplot2::aes(x=pos, y=diversity, color=group))
  p1 <- p1 + ggplot2::xlab("") + ggplot2::ylab("Nucleotide diversity")
  p1 <- p1 + ggplot2::theme_classic() + ggplot2::ylim(-0.14, NA)
  p1 <- p1 + ggplot2::theme(legend.title = ggplot2::element_blank())
  p1 <- p1 + ggplot2::theme(legend.position = "top", legend.text = ggplot2::element_text(size = 15))
  p1 <- p1 + ggplot2::theme(text = ggplot2::element_text(size = 15))
  
  if (nrow(nuc.gene.info)>=1) {
    p1 <- p1 + ggplot2::geom_rect(ggplot2::aes(xmin=start, xmax=end, ymin=-0.05, ymax=-0.07), color="grey40", data = nuc.gene.info)
    p1 <- p1 + ggplot2::geom_text(ggplot2::aes(x=(start+end)/2, y=-0.12, label=id), angle=40, size=4, data = nuc.gene.info)
  }
  
  p1 <- p1 + ggplot2::theme(axis.ticks.x = ggplot2::element_blank(), axis.text.x = ggplot2::element_blank(),
                   axis.line.x = ggplot2::element_blank()) + ggplot2::guides(colour = ggplot2::guide_legend(override.aes = list(size=2)))
  
  div.group.df.2$value <- div.group.df.2[,numerator]/div.group.df.2[,denominator]
  
  p2 <- ggplot2::ggplot(div.group.df.2) + ggplot2::geom_line(ggplot2::aes(x=pos, y=value))
  p2 <- p2 + ggplot2::xlab("genomic position") + ggplot2::ylab(paste0(numerator, "/", denominator))
  p2 <- p2 + ggplot2::theme_classic()
  p2 <- p2 + ggplot2::theme(text = ggplot2::element_text(size = 15))
  
  gp1 <- ggplot2::ggplotGrob(p1)
  gp2 <- ggplot2::ggplotGrob(p2)
  maxWidth = grid::unit.pmax(gp1$widths[2:5], gp2$widths[2:5])
  gp1$widths[2:5] <- as.list(maxWidth)
  gp2$widths[2:5] <- as.list(maxWidth)
  
  return(list(gp1, gp2))
}

