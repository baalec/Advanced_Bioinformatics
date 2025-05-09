library("DBI")
?DBI

# Create Database using RSQLite and DBI
mydb <- dbConnect(RSQLite::SQLite(), "my-db.sqlite")

dbWriteTable(mydb, "mtcars", mtcars)
dbListTables(mydb)

dbGetQuery(mydb, "Select * FROM mtcars LIMIT 5")
