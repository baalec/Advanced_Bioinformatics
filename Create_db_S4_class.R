library("methods")
library("DBI")
library("RSQLite")
library("readxl")

#S4 class defined with slots for the database path and connection
setClass(
  "DBManager",
  slots = list(
    db_path = "character",
    conn    = "DBIConnection" #Slot where we hold connection object
  )
)

#Open a connection when a new DBManager is created
setMethod(
  "initialize", "DBManager",
  function(.Object, db_path) {
    .Object@db_path <- db_path
    .Object@conn    <- dbConnect(SQLite(), dbname = db_path)
    .Object
  }
)

#Method to write an Excel file into a table in the database
setGeneric("write_excel_to_db", function(object, table_name, file_path) {
  standardGeneric("write_excel_to_db")
})
setMethod(
  "write_excel_to_db", "DBManager",
  function(object, table_name, file_path) {
    df <- read_excel(file_path)
    dbWriteTable(object@conn, table_name, df, overwrite = TRUE)
    message("Table '", table_name, "' has been created/overwritten.")
  }
)

#Method to list all tables in the database
setGeneric("list_tables", function(object) {
  standardGeneric("list_tables")
})
setMethod(
  "list_tables", "DBManager",
  function(object) {
    dbListTables(object@conn)
  }
)


# my-db <- new("DBManager", db_path = "my-db.sqlite")
# write_excel_to_db(my-db, "sgRNA_MaGeCK_data", "Data/sgrna_with_exons.xlsx")
# list_tables(my-db)
#Disconnect manually:
# dbDisconnect(my-db@conn)
