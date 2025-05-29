#' Count exact 5-bp matches of a random motif in a random chromosome
#'
#' @param fasta_path Path to a genome FASTA file (DNAStringSet format)
#' @return Integer: number of exact 5-bp matches found
#' @export
#' @examples
#' count_random_5mer_overlaps(
#'   "C:/Users/fraga/OneDrive/Desktop/Advanced Bioinformatics/Data/
#'    Homo_sapiens.GRCh38.dna.primary_assembly.fa"
#' )
count_random_5mer_overlaps <- function(fasta_path) {
  library(Biostrings)
  library(IRanges)
  library(GenomicRanges)

  # Load genome
  genome <- readDNAStringSet(fasta_path)

  # Pick one chromosome at random
  chr_name <- sample(names(genome), 1)
  cat("Selected chromosome:", chr_name, "\n")
  chr_seq <- genome[[chr_name]]
  chr_len <- length(chr_seq)

  # Generate a random 5-mer motif
  random_5mer <- paste0(
    sample(c("A","C","G","T"), 5, replace = TRUE),
    collapse = ""
  )
  cat("Random 5-mer motif:", random_5mer, "\n")

  # Build subject windows: every 5-bp interval across chr
  subject_windows <- IRanges(start = 1:(chr_len - 4), width = 5)

  # Find all exact matches (matchPattern → IRanges)
  matches      <- matchPattern(random_5mer, chr_seq)
  query_ranges <- as(matches, "IRanges")

  # Count overlaps
  hits  <- findOverlaps(query_ranges, subject_windows)
  n_hits <- length(hits)
  cat("Number of exact overlaps found:", n_hits, "\n")

  # Return the count
  return(n_hits)
}

  #example:  count_random_5mer_overlaps("C:/Users/fraga/OneDrive/Desktop/Advanced Bioinformatics/Data/Homo_sapiens.GRCh38.dna.primary_assembly.fa")
