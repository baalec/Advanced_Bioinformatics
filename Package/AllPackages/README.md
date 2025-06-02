# AllPackages

**AllPackages** is an R toolkit that has the following functions:

🧬 One_hot_encode – Encodes a sequence into 1's and 0's (one-hot format).

🔗 ConnectRNAseqandGenome – Summarizes three RNA-seq .gz files and joins them with the correct genes annotated from the human reference genome.

🧠 sgRNAExonLocation – Aligns the last 10 bp of sgRNA sequences to the human reference genome to identify which exon each sgRNA specifically targets.

🧾 TranslatesgRNAGeneNames – Takes an sgRNA .xlsx file and translates sgRNA IDs into sequences using two .csv translation files.

🧪 FindOverLapUsage – Takes a random short RNA sequence and aligns it to a random chromosome in the human reference genome using the FindOverlap() function.

## Installation

1. Install the following packages manually: dplyr, writexl, Biostrings, IRanges, GenomicRanges, readxl

2. Run remote install command: remotes::install_local("Advanced_Bioinformatics/AllPackages_0.0.0.9000.tar.gz")

