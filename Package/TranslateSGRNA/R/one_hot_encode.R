
# Function to One hot encode a sequence
#' One Hot Encode for DNA
#'
#' @param sequence 
#'
#' @returns One Hot Encoded Matrix with position as columns and base as rows
#' @export
#'
#' @examples function("ACGT")
one_hot_encode <- function(sequence) {
  # Splits a sequence into individual bases and saves in bases_in_sequence
  bases_in_sequence <- unlist(strsplit(sequence, ""))
  bases <- c("A","C","G","T")
  # Creates a one_hot_matrix using a discrete function that converts bases
  # in the sequence as a list with integers, e.g. A = [1 0 0 0 ]
  one_hot_matrix <- sapply(bases, function(base) as.integer(bases_in_sequence == base))
  # Transform the matrix to make sure rows become bases and row becomes position
  return(t(one_hot_matrix))
}
