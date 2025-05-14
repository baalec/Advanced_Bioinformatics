library("DBI")
library("RSQLite")
library("readxl")

# Create and Connect Database using RSQLite and DBI
#mydb <- dbConnect(RSQLite::SQLite(), "my-db.sqlite")
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
sgRNA_MaGeCK_df <- read_excel("Data/Translated_Big_data.xlsx")
sgRNA_MaGeCK_df$index <- 1:nrow(sgRNA_MaGeCK_df) # Add Index rows

# Create table containing 
dbWriteTable(mydb, "sgRNA_MaGeCK_data", sgRNA_MaGeCK_df)

