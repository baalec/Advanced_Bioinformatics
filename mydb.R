library("DBI")
library("RSQLite")

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
