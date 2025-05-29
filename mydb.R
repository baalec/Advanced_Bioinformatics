library("DBI")
library("RSQLite")
library("readxl")
library(dbplyr)
#devtools::install("./Package/AllPackages")
library(AllPackages)

# Create and Connect Database using RSQLite and DBI
mydb <- dbConnect(RSQLite::SQLite(), "my-db.sqlite")
#Create table from DataFrame
#dbWriteTable(mydb, "tableName", DataFrame)

# List tables in mydb
#dbListTables(mydb)

# Select top 5 entries in tableName
#dbGetQuery(mydb, "Select * FROM tableName LIMIT 5")

#Disconnect from Database
#dbDisconnect(mydb)

# Drop table from Database
#dbRemoveTable(mydb, "tableName")

# Read excel file into a dataframe
sgRNA_MaGeCK_df <- read_excel("Data/sgrna_with_exons.xlsx")
sgRNA_MaGeCK_df$index <- 1:nrow(sgRNA_MaGeCK_df) # Add Index rows

# Create table containing 
dbWriteTable(mydb, "raw_data", sgRNA_MaGeCK_df, overwrite = TRUE)

#Example query
#dbGetQuery(mydb, "SELECT * from sgRNA_MaGeCK_data WHERE gene = 'TPX2'")
# Connect and select sgRNA sequence, index, exon_position
# and LFC score from dataset, save in df
df <- dbGetQuery(mydb, "Select \"index\", sgrna, matched_exons AS Exon_position,
                 avg_ctrl AS RNAseq_expression, LFC FROM raw_data")
df <- na.omit(df)

# Create model_df for storing relevant data
positions <- 20
bases <- c("A","C","G","T")
column_names <- as.vector(sapply(1:positions, function(i) paste0(bases, i)))
column_names <- c("index", column_names, "gc_content","Exon_position", "RNAseq_expression", "absLFC")
model_df <- data.frame(matrix(ncol = length(column_names),
                              nrow = 0))
colnames(model_df) <- column_names

number_seq <- nrow(df)

# Calculating gc content and one hot encoding sequences, taking the abs of LFC
for (i in 1:number_seq) {
  sequence <- df[i, , drop = FALSE]
  if (nrow(sequence) > 0) {
    sgrna_seq <- sequence$sgrna
    encoded <- one_hot_encode(sgrna_seq)
    encoded <- as.vector(t(encoded))
    
    chars <- unlist(strsplit(sgrna_seq, ""))
    base_counts <- table(factor(chars, levels = bases))
    gc <- sum(base_counts[c("G","C")], na.rm = TRUE)
    gc_content <- gc/positions
    
    row_df <- as.data.frame(t(c(i, encoded, gc_content, sequence$Exon_position,
                                sequence$RNAseq_expression,abs(sequence$LFC))),
                                stringsAsFactors = FALSE)
    colnames(row_df) <- column_names
    row_df <- as.data.frame(lapply(row_df, as.numeric))
    model_df <- rbind(model_df, row_df)
  }              
}             

# Write model_data into database
dbWriteTable(mydb, "model_data", model_df, overwrite = TRUE)
