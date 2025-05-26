#' Translate xlsx file with sgRNA_id. Using csv translation files
#'
#' @param orig_path Path to original DATA file with sgRNA_id
#' @param libA_path Path to your Translation file for libA
#' @param libB_path Path to your Translation file for libB
#' @param out_path Path to where the Translated file should be saved
#'
#' @returns A Translated xlsx file.
#' @export
#'
#' @examples translate_sgrna(orig_path, libA_path, libB_path, out_path)
#' @examples translate_sgrna(orig_path = "C:/Users/File_Location", libA_path"C:/Users/File_Location", libB_path"C:/Users/File_Location", out_path"C:/Users/File_Location"

translate_sgrna <- function(orig_path, libA_path, libB_path, out_path) {
  library(readxl)  
  library(dplyr)    
  library(writexl)  

  #Read data
  orig_df <- read_excel(orig_path)
  head(orig_df)

  #Read translation tables
  HGLibA <- read.csv(libA_path, stringsAsFactors = FALSE)
  HGLibB <- read.csv(libB_path, stringsAsFactors = FALSE)

  #Build new vector with trasnlation: UID -> seq
  seq_map <- c(HGLibA$seq, HGLibB$seq)
  names(seq_map) <- c(HGLibA$UID,  HGLibB$UID)

  #Translate the sgrna column via 'vectorized lookup'
  #HERE IS THE ID CONVERSION BEING MADE THAT IS FASTER THAN MERGE/LOOP
  orig_df <- orig_df %>%
    mutate(sgrna = seq_map[as.character(sgrna)])

  #Write result to Excel file
  write_xlsx(orig_df, out_path)

  invisible(TRUE)
}

translate_sgrna(
  orig_path = "C:/Users/fraga/OneDrive/Desktop/Advanced Bioinformatics/Data/Big_data.xlsx",
  libA_path = "C:/Users/fraga/OneDrive/Desktop/Advanced Bioinformatics/Data/HGLibA.csv",
  libB_path = "C:/Users/fraga/OneDrive/Desktop/Advanced Bioinformatics/Data/HGLibB.csv",
  out_path  = "C:/Users/fraga/OneDrive/Desktop/Advanced Bioinformatics/Data/Translated_Big_data.xlsx"
)

