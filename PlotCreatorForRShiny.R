
#Below is code to make the plots for the RShiny interface
library(ggplot2)

www_path <- "www/"

# LFC histogram
p_lfc_hist <- ggplot(model_data, aes(x = LFC)) +
  geom_histogram(binwidth = 0.5, fill = "steelblue", color = "black") +
  labs(title = "Histogram av LFC", x = "LFC", y = "Frekvens") +
  theme_minimal()

saveRDS(p_lfc_hist, file = paste0(www_path, "lfc_histogram"))

# gc_content histogram
p_gc_hist <- ggplot(model_data, aes(x = gc_content)) +
  geom_histogram(binwidth = 0.05, fill = "purple", color = "black") +
  labs(title = "Histogram av GC Content", x = "GC Content (%)", y = "Frekvens") +
  theme_minimal()

saveRDS(p_gc_hist, file = paste0(www_path, "gc_content_histogram"))

# RNAseq_expression histogram
p_rna_hist <- ggplot(model_data, aes(x = RNAseq_expression)) +
  geom_histogram(binwidth = 1, fill = "forestgreen", color = "black") +
  labs(title = "Histogram av RNAseq Expression", x = "RNAseq Expression (logdfold2)", y = "Frekvens") +
  theme_minimal()

saveRDS(p_rna_hist, file = paste0(www_path, "rna_expression_histogram"))
