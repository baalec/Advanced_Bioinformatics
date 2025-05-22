#' Match sgRNAs to exons and annotate control values
#'
#' @param exon_gene_path  Path to your exon/gene table (Excel)
#' @param sgrna_data_path Path to your sgRNA results (Excel)
#' @param genome_fasta_path Path to the genome FASTA file
#' @param output_path   Path where the annotated sgRNA Excel should be written
#'
#' @returns Invisibly returns the final annotated data frame
#' @export
#'
#' @examples
#' \dontrun{
#' match_sgrna_to_exons(exon_gene_path,sgrna_data_path,genome_fasta_path,output_path)
#' }

match_sgrna_to_exons <- function(exon_gene_path,
                                 sgrna_data_path,
                                 genome_fasta_path,
                                 output_path) {
  # 1) Load libraries
  library(readxl)       # read Excel
  library(dplyr)        # data manipulation
  library(Biostrings)   # sequence handling
  library(writexl)      # write Excel

  # 2) Read inputs
  exon_gene_df <- read_excel(exon_gene_path)
  sgrna_df     <- read_excel(sgrna_data_path)
  genome       <- readDNAStringSet(genome_fasta_path, format="fasta")

  # 3) Find matched genes
  genes_exon  <- unique(exon_gene_df$gene_name)
  genes_sgrna <- unique(sgrna_df$Gene)
  matched     <- intersect(genes_exon, genes_sgrna)

  # 4) Filter to matched
  exon_gene_df <- exon_gene_df %>% filter(gene_name %in% matched)
  sgrna_df     <- sgrna_df     %>% filter(Gene      %in% matched)

  cat("Matched", length(matched), "of", length(genes_exon), "genes.\n")

  # 5) Extract last 10 bases of each sgRNA
  sgrna_df <- sgrna_df %>%
    mutate(sgrna_last12 = substr(sgrna, nchar(sgrna)-9, nchar(sgrna)))

  # 6) Build chromosome name map
  chr_map <- setNames(names(genome), sub(" .*", "", names(genome)))

  # 7) Helper to find exon(s) given a genomic position
  find_exons_for_pos <- function(pos, exons) {
    hits <- exons %>% filter(exon_start <= pos & exon_end >= pos)
    if(nrow(hits)==0) return(NA_character_)
    paste(hits$exon_number, collapse=",")
  }

  # 8) Prepare output column
  sgrna_df$matched_exons <- NA_character_

  # 9) Loop through sgRNAs
  N <- nrow(sgrna_df)
  for(i in seq_len(N)) {
    if(i %% 1000 == 0) cat("Processing", i, "of", N, "sgRNAs...\n")

    gene      <- sgrna_df$Gene[i]
    sgrna_seq <- sgrna_df$sgrna_last12[i]

    ginfo <- exon_gene_df %>% filter(gene_name==gene)
    if(nrow(ginfo)==0) next

    chr        <- unique(ginfo$chromosome)
    gstart     <- unique(ginfo$gene_start)
    gend       <- unique(ginfo$gene_end)
    if(length(chr)!=1 || length(gstart)!=1 || length(gend)!=1) next

    full_chr   <- chr_map[as.character(chr)]
    if(is.na(full_chr)) next

    chr_seq    <- genome[[full_chr]]
    gene_seq   <- subseq(chr_seq, start=gstart, end=gend)

    hits       <- start(matchPattern(sgrna_seq, gene_seq))
    if(length(hits)==0) next

    exons_all <- vapply(hits,
                        function(h) find_exons_for_pos(gstart + h - 1, ginfo),
                        FUN.VALUE=character(1))
    exons_uni <- unique(unlist(strsplit(paste(exons_all, collapse=","),",")))
    sgrna_df$matched_exons[i] <- paste(exons_uni, collapse=",")
  }

  # 10) Add avg_ctrl (one value per gene)
  avg_ctrl_df <- exon_gene_df %>%
    distinct(gene_name, .keep_all=TRUE) %>%
    select(gene_name, avg_ctrl)
  sgrna_df <- left_join(sgrna_df, avg_ctrl_df,
                        by=c("Gene"="gene_name"))

  # 11) Write out and return
  write_xlsx(sgrna_df, output_path)
  cat("Written results to:\n", output_path, "\n")
  invisible(sgrna_df)
}
