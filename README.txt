Here is a description of my project

#1 Using the Docker file for installation:
    1. Install docker desktop
    2. Load myimage.tar 
    3. Run the container from image via docker
    
#2 Installing only our costum made package
    1. Install the following packages manually (if not already installed): 
        dplyr
        writexl
        Biostrings
        IRanges)
        GenomicRanges
        readxl
    2. Run remote install command:
        remotes::install_local("Advanced_Bioinformatics/AllPackages_0.0.0.9000.tar.gz")
        
#3  Opening pkgdown website for package:
    1. Install package 'pkgdown' and load using library("pkgdown")
    2. When in reprository for Allpackages.Rproj, build the site using:
        pkgdown::build_site()

#4  Opening Rshiny website to see plots:
    1. Navigate to root directory and open fie "RshinyWebsite.R"
    2. Run entire code.
    3. Navigate through website.
    

