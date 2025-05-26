

#' Function to connect RNA-seq data and genome annotation data
#'
#' This function merges RNA-seq count data with genome annotation information from a GTF file. It selects one random transcript per gene and summarizes exon information along with average gene expression across multiple RNA-seq samples.
#'
#' @param data_dir Path to the folder containing input data files.
#' @param gtf_filename Filename of the genome annotation GTF file (e.g., "Homo_sapiens.GRCh38.114.gtf.gz").
#' @param ctrl_filenames A character vector of RNA-seq count filenames.
#' @param output_filename Full path for the output Excel file.
#'
#' @return Writes an Excel file containing summarized exon and expression data. Also returns the resulting data frame invisibly.
#' @export
#'
#' @examples
#' \dontrun{
#' make_final_table(
#'   data_dir = "path/to/data_directory",
#'   gtf_filename = "your_annotation_file.gtf.gz",
#'   ctrl_filenames = c(
#'     "sample1_counts.tab.gz",
#'     "sample2_counts.tab.gz",
#'     "sample3_counts.tab.gz"
#'   ),
#'   output_filename = "path/to/output/final_table.xlsx"
#' )
#' }



make_final_table <- function(data_dir, gtf_filename, ctrl_filenames, output_filename) {
  library(dplyr)
  library(writexl)

  gtf_file <- file.path(data_dir, gtf_filename)
  ctrl_files <- file.path(data_dir, ctrl_filenames)

  ctrl_dfs <- lapply(ctrl_files, function(f) {
    df <- read.delim(f, header = TRUE, stringsAsFactors = FALSE)
    df <- df[, c("geneName", names(df)[2])]
    sample_id <- sub("GSE169614_(\\d+)_.*", "\\1", basename(f))
    colnames(df) <- c("gene", paste0("ctrl_", sample_id))
    df
  })

  merged_ctrl <- Reduce(function(x, y) merge(x, y, by = "gene", all = TRUE), ctrl_dfs)
  merged_ctrl_genes <- merged_ctrl[!grepl("^__", merged_ctrl$gene), ]
  final_ctrl <- data.frame(
    gene = merged_ctrl_genes$gene,
    avg_ctrl = rowMeans(merged_ctrl_genes[, grep("^ctrl_", names(merged_ctrl_genes))])
  )

  gtf <- read.delim(gtf_file, header = FALSE, sep = "\t", comment.char = "#", stringsAsFactors = FALSE,
                    col.names = c("seqname", "source", "feature", "start", "end", "score", "strand", "frame", "attr"))

  genes <- subset(gtf, feature == "gene")
  genes$gene_id <- ifelse(
    grepl("gene_id[[:space:]]*[^;]+;", genes$attr),
    sub(".*gene_id[[:space:]]*([^;]+);.*", "\\1", genes$attr),
    NA
  )
  genes$gene_name <- ifelse(
    grepl("gene_name[[:space:]]*[^;]+;", genes$attr),
    sub(".*gene_name[[:space:]]*([^;]+);.*", "\\1", genes$attr),
    NA
  )
  genes$gene_id <- trimws(genes$gene_id)
  gene_bounds <- genes[, c("gene_id", "gene_name", "start", "end")]

  exons <- subset(gtf, feature == "exon")
  exons$gene_id <- sub(".*gene_id[[:space:]]*([^;]+);.*", "\\1", exons$attr)
  exons$gene_id <- trimws(exons$gene_id)
  exons$exon_number <- as.integer(sub(".*exon_number[[:space:]]*([0-9]+).*", "\\1", exons$attr))
  exons$transcript_id <- sub(".*transcript_id ([^;]+);.*", "\\1", exons$attr)

  set.seed(42)
  transcript_per_gene <- exons |> distinct(gene_id, transcript_id) |> group_by(gene_id) |> slice_sample(n = 1) |> ungroup()

  exons_one_transcript <- exons %>%
    inner_join(transcript_per_gene, by = c("gene_id", "transcript_id"))

  exon_info <- merge(
    exons_one_transcript[, c("gene_id", "exon_number", "start", "end")],
    gene_bounds,
    by = "gene_id"
  )

  final_table <- merge(
    exon_info,
    final_ctrl,
    by.x = "gene_id",
    by.y = "gene",
    all.x = TRUE
  )[, c("start.x", "end.x", "start.y", "end.y", "exon_number", "gene_name", "avg_ctrl")]

  colnames(final_table)[1:2] <- c("exon_start", "exon_end")
  colnames(final_table)[3:4] <- c("gene_start", "gene_end")

  write_xlsx(final_table, output_filename)

  return(final_table)
}

#Exaample usage for Alecs paths
#make_final_table(
#data_dir = "C:/Users/fraga/OneDrive/Desktop/Advanced Bioinformatics/Data",
#gtf_filename = "Homo_sapiens.GRCh38.114.gtf.gz",
#ctrl_filenames = c(
#"GSE169614_52677_star.Homo_sapiens.GRCh38.78.htseq.counts.tab.gz",
#"GSE169614_52678_star.Homo_sapiens.GRCh38.78.htseq.counts.tab.gz",
#"GSE169614_52679_star.Homo_sapiens.GRCh38.78.htseq.counts.tab.gz"
#),
#output_filename = "C:/Users/fraga/OneDrive/Desktop/Advanced Bioinformatics/Code/Advanced_Bioinformatics/final_table.xlsx"
#)


