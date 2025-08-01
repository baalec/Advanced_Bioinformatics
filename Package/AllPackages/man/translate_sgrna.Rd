% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/TranslatesgRNAGeneNames.R
\name{translate_sgrna}
\alias{translate_sgrna}
\title{Translate xlsx file with sgRNA_id. Using csv translation files}
\usage{
translate_sgrna(orig_path, libA_path, libB_path, out_path)
}
\arguments{
\item{orig_path}{Path to original DATA file with sgRNA_id}

\item{libA_path}{Path to your Translation file for libA}

\item{libB_path}{Path to your Translation file for libB}

\item{out_path}{Path to where the Translated file should be saved}
}
\value{
A Translated xlsx file.
}
\description{
Translate xlsx file with sgRNA_id. Using csv translation files
}
\examples{
translate_sgrna(
  orig_path = "path/to/original_sgrna_data.xlsx",
  libA_path = "path/to/translation_library_A.csv",
  libB_path = "path/to/translation_library_B.csv",
  out_path = "path/to/output_translated_file.xlsx"
)
}
