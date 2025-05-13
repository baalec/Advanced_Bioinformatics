#############################################################################
# 1) Define the S4 class with the exact slots you need
#############################################################################
setClass("FilteredData",
         slots = list(
           sgrna          = "character",
           Dropout_count  = "numeric",
           LFC            = "numeric",
           adj_var        = "numeric",
           score          = "numeric"
         )
)

#############################################################################
# 2) Declare generics for I/O + filters
#############################################################################
setGeneric("importDb",  function(object, db_path, table_name)    standardGeneric("importDb"))
setGeneric("filter1",   function(object, ...)                   standardGeneric("filter1"))
setGeneric("filter2",   function(object, ...)                   standardGeneric("filter2"))
setGeneric("filter3",   function(object, ...)                   standardGeneric("filter3"))
setGeneric("exportDb",  function(object, db_path, table_name)    standardGeneric("exportDb"))

#############################################################################
# 3) Implement methods
#############################################################################

## 3a) importDb: only pull the five columns you listed
setMethod("importDb", "FilteredData",
          function(object, db_path, table_name) {
            library("DBI")
            library("RSQLite")
            library("readxl")
            con <- dbConnect(RSQLite::SQLite(), "my-db.sqlite")
            df  <- DBI::dbGetQuery(
              con,
              sprintf(
                "SELECT sgrna, Dropout_count, LFC, adj_var, score
         FROM %s;",
                table_name
              )
            )
            DBI::dbDisconnect(con)
            
            object@sgrna         <- df$sgrna
            object@Dropout_count <- df$Dropout_count
            object@LFC           <- df$LFC
            object@adj_var       <- df$adj_var
            object@score         <- df$score
            
            object
          }
)

## 3b) filter1: e.g. drop low‐count guides
setMethod("filter1", "FilteredData",
          function(object, min_dropout = 10) {
            keep <- object@Dropout_count >= min_dropout
            object@sgrna         <- object@sgrna[keep]
            object@Dropout_count <- object@Dropout_count[keep]
            object@LFC           <- object@LFC[keep]
            object@adj_var       <- object@adj_var[keep]
            object@score         <- object@score[keep]
            object
          }
)

## 3c) filter2: e.g. require LFC above threshold
setMethod("filter2", "FilteredData",
          function(object, min_lfc = -2) {
            keep <- object@LFC >= min_lfc
            object@sgrna         <- object@sgrna[keep]
            object@Dropout_count <- object@Dropout_count[keep]
            object@LFC           <- object@LFC[keep]
            object@adj_var       <- object@adj_var[keep]
            object@score         <- object@score[keep]
            object
          }
)

## 3d) filter3: e.g. drop extreme variance weights
setMethod("filter3", "FilteredData",
          function(object, max_var = 1e6) {
            keep <- object@adj_var <= max_var
            object@sgrna         <- object@sgrna[keep]
            object@Dropout_count <- object@Dropout_count[keep]
            object@LFC           <- object@LFC[keep]
            object@adj_var       <- object@adj_var[keep]
            object@score         <- object@score[keep]
            object
          }
)

## 3e) exportDb: write those five columns back out
setMethod("exportDb", "FilteredData",
          function(object, db_path, table_name) {
            df <- data.frame(
              sgrna         = object@sgrna,
              Dropout_count = object@Dropout_count,
              LFC           = object@LFC,
              adj_var       = object@adj_var,
              score         = object@score,
              stringsAsFactors = FALSE
            )
            con <- DBI::dbConnect(RSQLite::SQLite(), dbname = db_path)
            DBI::dbWriteTable(con, table_name, df, overwrite = TRUE, row.names = FALSE)
            DBI::dbDisconnect(con)
            invisible(TRUE)
          }
)
