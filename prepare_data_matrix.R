# Script for creating and training XGBoost model
# Training is done on One Hot encoded sequence data

library("DBI")
library("xgboost")

# Connect and select sgRNA sequence and LFC score from dataset, save in df
mydb <- dbConnect(RSQLite::SQLite(), "my-db.sqlite")
df <- dbGetQuery(mydb, "Select sgrna, LFC FROM sgRNA_MaGeCK_data")
dbDisconnect(mydb)

# One hot encode sequences using one_hot_encode function and flatten the matrix
# to use as predictor for XGBoost model
source("Package/TranslateSGRNA/R/one_hot_encode.R")
# NEW IDEA
#' Create empty dataframe
#' Create a for loop that each round connects to the database
#' gets one sequence and one hot encodes it
#' Transforms it into a vector and saves it to a new table along with the LFC
#' for that sequence.
#' This should result in the matrix needed for our model
#' 

# Create new table in database containing position and score
positions <- 20
bases <- c("A","C","G","T")
column_names <- as.vector(sapply(1:positions, function(i) paste0(bases, i)))
column_names <- c("Index", column_names, "gc_content", "LFC")
model_df <- data.frame(matrix(ncol = length(column_names),
                              nrow = 0))
colnames(model_df) <- column_names
dbWriteTable(mydb,"model_data", model_df)

# Create empty dataframe
df <- data.frame()
number_of_seq <- unlist(dbGetQuery(mydb, "SELECT COUNT(*) AS nr_seq
                                   FROM sgRNA_MaGeCK_data"))
for (i in 0:number_of_seq) {
  query <- sprintf("SELECT sgrna, LFC 
                         FROM sgRNA_MaGeCK_data 
                         WHERE \"index\" = %d", i)
  sequence <- dbGetQuery(mydb, query)
  if (nrow(sequence) > 0) {
    gc <- sum(table(strsplit(sequence$sgrna, ""))[c("C","G")])
    gc_content <- gc/positions
    encoded <- t(as.vector(one_hot_encode(sequence$sgrna)))
    df <- as.data.frame(cbind(index = i, encoded,
                              gc_content = gc_content,
                              LFC = sequence$LFC))
    colnames(df) <- column_names
    dbWriteTable(mydb, "model_data", df, append = TRUE, row.names = FALSE)
  }
}
