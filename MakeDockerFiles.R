#Read the list of packages
used_pkgs <- readLines("used_packages.txt")

#Get all installed packages
ip <- installed.packages()[, c("Package","Version"), drop = FALSE]

#Subset to only those you actually use
pkgs_to_pin <- setdiff(used_pkgs, "methods")
req_df <- ip[rownames(ip) %in% pkgs_to_pin, , drop = FALSE]

#Check for any package in used_packages.txt that is not yet installed
missing <- setdiff(pkgs_to_pin, rownames(req_df))
if (length(missing)) {
  stop("These packages are listed in used_packages.txt but not installed:\n",
       paste(missing, collapse = ", "))
}

#Create lines of the form "Package==Version"
req_lines <- paste(req_df[, "Package"], req_df[, "Version"], sep = "==")

#Write out to r_requirements.txt
writeLines(req_lines, con = "r_requirements.txt")

#Record Rversion
writeLines(R.version.string, con = "r_version.txt")

