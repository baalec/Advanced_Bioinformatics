library("DBI")
library("RSQLite")
library("readxl")

# Create and Connect Database using RSQLite and DBI
mydb <- dbConnect(RSQLite::SQLite(), "my-db.sqlite")
#Create table from dataframe mtcars
dbWriteTable(mydb, "mtcars", mtcars)

# List tables in mydb
dbListTables(mydb)

# Select top 5 entries in mtcars table
dbGetQuery(mydb, "Select * FROM mtcars LIMIT 5")

#Disconnect from Database
dbDisconnect(mydb)

# Drop table from Database
dbRemoveTable(mydb, "mtcars")

# Read excel file into a dataframe
sgRNA_MaGeCK_df <- read_excel("Data/Translated_Big_data.xlsx")

# Create table containing 
dbWriteTable(mydb, "sgRNA_MaGeCK_data", sgRNA_MaGeCK_df)

