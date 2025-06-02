tryCatch({
  if (!requireNamespace("BiocManager", quietly = TRUE)) {
    install.packages("BiocManager", repos = "https://cloud.r-project.org")
  }

  lines <- readLines('/tmp/r_requirements.txt')
  print(lines)

  split_req <- strsplit(lines, ',')
  print(split_req)

  lengths <- sapply(split_req, length)
  print(lengths)

  if (any(lengths != 2)) {
    stop('One or more lines do not split into exactly two parts.')
  }

  reqs <- do.call(rbind, split_req)
  reqs <- as.data.frame(reqs, stringsAsFactors = FALSE)
  colnames(reqs) <- c('Package', 'Version')
  print(reqs)

  bioc_pkgs <- c("Biostrings", "GenomicRanges", "IRanges")  # list all your Bioconductor pkgs here

  for (i in seq_len(nrow(reqs))) {
    pkg <- reqs$Package[i]
    ver <- reqs$Version[i]
    print(paste('Installing:', pkg, ver))

    if (pkg %in% bioc_pkgs) {
      # Install Bioconductor package with specific version
      BiocManager::install(pkg, version = "3.16", ask = FALSE, update = FALSE)
      # Note: BiocManager doesn't support exact version pinning easily
      # You can adjust 'version' arg or rely on the Bioconductor release version
    } else {
      remotes::install_version(pkg, version = ver, repos = 'https://cloud.r-project.org', upgrade = 'never')
    }
  }
}, error = function(e) {
  print(paste('ERROR:', e$message))
  quit(status = 1)
})
