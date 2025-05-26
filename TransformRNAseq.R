# Paths and file lists
data_dir <- "C:/Users/fraga/OneDrive/Desktop/Advanced Bioinformatics/Data"
gtf_file <- file.path(data_dir, "Homo_sapiens.GRCh38.114.gtf.gz")
ctrl_files <- c(
  "GSE169614_52677_star.Homo_sapiens.GRCh38.78.htseq.counts.tab.gz",
  "GSE169614_52678_star.Homo_sapiens.GRCh38.78.htseq.counts.tab.gz",
  "GSE169614_52679_star.Homo_sapiens.GRCh38.78.htseq.counts.tab.gz"
)

# 1. Read & merge control counts → final_ctrl
ctrl_dfs <- lapply(ctrl_files, function(f) {
  df <- read.delim(file.path(data_dir, f), header=TRUE, stringsAsFactors=FALSE)
  df <- df[, c("geneName", names(df)[2])]
  sample_id <- sub("GSE169614_(\\d+)_.*", "\\1", f)
  colnames(df) <- c("gene", paste0("ctrl_", sample_id))
  df
})
merged_ctrl <- Reduce(function(x, y) merge(x, y, by="gene", all=TRUE), ctrl_dfs)
merged_ctrl_genes <- merged_ctrl[!grepl("^__", merged_ctrl$gene), ]
final_ctrl <- data.frame(
  gene = merged_ctrl_genes$gene,
  avg_ctrl = rowMeans(merged_ctrl_genes[, grep("^ctrl_", names(merged_ctrl_genes))])
)

# 2. Import GTF and parse attributes
gtf <- read.delim(gtf_file, header=FALSE, sep="\t", comment.char="#", stringsAsFactors=FALSE,
                  col.names=c("seqname","source","feature","start","end","score","strand","frame","attr"))

# Extract GENES
genes <- subset(gtf, feature == "gene")

genes$gene_id <- ifelse(
  grepl("gene_id[[:space:]]*[^;]+;", genes$attr),
  sub('.*gene_id[[:space:]]*([^;]+);.*', '\\1', genes$attr),
  NA
)
genes$gene_name <- ifelse(
  grepl("gene_name[[:space:]]*[^;]+;", genes$attr),
  sub('.*gene_name[[:space:]]*([^;]+);.*', '\\1', genes$attr),
  NA
)

genes$gene_id <- trimws(genes$gene_id)

gene_bounds <- genes[, c("gene_id", "gene_name", "start", "end")]

# Extract EXONS
exons <- subset(gtf, feature=="exon")
exons$gene_id <- sub('.*gene_id[[:space:]]*([^;]+);.*', '\\1', exons$attr)
exons$gene_id <- trimws(exons$gene_id)
exons$exon_number <- as.integer(sub('.*exon_number[[:space:]]*([0-9]+).*', '\\1', exons$attr))
exons$transcript_id <- sub(".*transcript_id ([^;]+);.*", "\\1", exons$attr)

library(dplyr)

set.seed(42)
transcript_per_gene <- exons %>%
  distinct(gene_id, transcript_id) %>%
  group_by(gene_id) %>%
  slice_sample(n = 1) %>%
  ungroup()

exons_one_transcript <- exons %>%
  inner_join(transcript_per_gene, by = c("gene_id", "transcript_id"))

gene_bounds <- genes[, c("gene_id", "gene_name", "start", "end")]

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
)

final_table <- final_table[, c("gene_id", "start.x", "end.x", "start.y", "end.y", "exon_number", "gene_name", "avg_ctrl")]

colnames(final_table)[2:3] <- c("exon_start", "exon_end")
colnames(final_table)[4:5] <- c("gene_start", "gene_end")

chr_info <- genes[, c("gene_id", "seqname")]

final_table <- merge(final_table, chr_info, by = "gene_id", all.x = TRUE)

colnames(final_table)[which(names(final_table) == "seqname")] <- "chromosome"

library(writexl)
output_path <- "C:/Users/fraga/OneDrive/Desktop/Advanced Bioinformatics/Code/Advanced_Bioinformatics/final_table.xlsx"
write_xlsx(final_table, output_path)
cat("File saved to: ", output_path)
