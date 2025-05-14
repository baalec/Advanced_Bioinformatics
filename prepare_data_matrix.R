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
# Create empty dataframe
df2 <- data.frame()
for (sequence in df$sgrna) {
  df2 <- rbind(df2, t(as.vector(one_hot_encode(sequence))))
}

df2 <- rbind(df2, t(as.vector(one_hot_encode(df$sgrna[1]))))
df2 <- cbind(df2, df$LFC[1])
df2 <-rbind(df2, t(as.vector(one_hot_encode(df$sgrna[2]))))

