# ─────────────────────────────────────────────────────────────
# 1. Base image: use the rocker image matching your R version
#    (replace “4.2.2” if r_version.txt says something else)
FROM rocker/r-ver:4.2.2

# ─────────────────────────────────────────────────────────────
# 2. Install system libraries required by your R packages
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libz-dev \
    libzip-dev \
    libxt-dev \
    libpng-dev \
    libcairo2-dev \
    libsqlite3-dev \
  && rm -rf /var/lib/apt/lists/*

# ─────────────────────────────────────────────────────────────
# 3. Copy in the pinned‐versions file
COPY r_requirements.txt /tmp/r_requirements.txt

# ─────────────────────────────────────────────────────────────
# 4. Install 'remotes' so we can install specific versions
RUN Rscript -e "install.packages('remotes', repos='https://cloud.r-project.org')"

# ─────────────────────────────────────────────────────────────
# 5. Loop through r_requirements.txt and install each package version
RUN Rscript -e " \
    reqs <- read.table('/tmp/r_requirements.txt', sep='==', stringsAsFactors=FALSE, col.names=c('Package','Version')); \
    for (i in seq_len(nrow(reqs))) { \
      pkg <- reqs$Package[i]; \
      ver <- reqs$Version[i]; \
      remotes::install_version(pkg, version=ver, repos='https://cloud.r-project.org', upgrade='never'); \
    } \
  "

# ─────────────────────────────────────────────────────────────
# 6. Copy your own package source (tarball) into the image
#    Assume you have built AllPackages_0.0.0.9000.tar.gz in the project root
COPY AllPackages_0.0.0.9000.tar.gz /tmp/

# 7. Install your custom package; its DESCRIPTION will pull in any Imports
RUN Rscript -e "remotes::install_local('/tmp/AllPackages_0.0.0.9000.tar.gz')"

# ─────────────────────────────────────────────────────────────
# 8. Copy the rest of your project files (e.g., R scripts, Shiny app) into the image
COPY . /usr/local/src
WORKDIR /usr/local/src

# ─────────────────────────────────────────────────────────────
# 9. Default command: start R (you can override to run a script or Shiny app)
CMD ["R"]
