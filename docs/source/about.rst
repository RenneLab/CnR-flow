
About
=====

Renne Lab
---------
    | Principal Investigator: Rolf Renne
    | Henry E. Innes Professor of Cancer Research
    | University of Florida
    | UF Health Cancer Center
    | UF Department of Molecular Genetics and Microbiology
    | UF Genetics Institute
    | http://www.RenneLab.com

Lead Developer
--------------
    | Dan Stribling <ds@ufl.edu>
    | https://github.com/dstrib
    | https://orcid.org/0000-0002-0649-9506
    | University of Florida, Renne Lab

Changelog
---------

    v0.11-dev - ongoing:
        * Refinements
        * Bugfixes
        * Added additional template nextflow.config files for task
        * Added macOS support for Conda machines (for all dependencies) 
        * Added input data file integrity checks to Merge process
        * Added internal output checks for early error catching
        * Updated Conda Bowtie2 Version to 2.4.4 and added component dependency 
        * Merge "validate" and "validate-all" modes into "validate" mode
        * Remove "dry-run" mode as low utility per complexity
        * Switch to nextflow-implementation of memory handling
        * Add support for task execution via Docker / Singularity containers
        * Corrected error in handling of normalized alignment files
        * Moved SEACR to external dependency config
        * Removed CUTRUNTools:kseqtest from pipeline
        * Migrate aumotated testing from TravisCI to CircleCI
        * Add Beta support for Singularity/Docker dependency configurations
        * Add CircleCI Docker dependency config testing
        * Add default Singularity and Docker support configs via profiles

    v0.10 - 2020-09-04: 
        * Refinements
        * Changed verbose task logging to implementation with "beforeScript"
        * Complete Initial Documentation
        * Moved macs2 peak-calling out of alpha testing
        * "Reordered" output step directories
        * Tuned resource usage defaults
        * Added process memory usage categories
        * Move UCSC/Kent tools to external dependency setup
        * Added bigWig track format creation step
        * Overhauled alignment modification step
        * Removed Picard dependency
        * Changed (non-track) alignment output files to CRAM (compressed BAM)

    v0.09:
        * Refinements
        * Added one-step database preparation
        * Implemented 'list_refs' mode 
        * Implemented automatic reference paramater finding  
        * Shifted paramaters to config files
        * Implemented initiate mode
        * Added minimal documentation
        * Added UCSC (faCount) automated installation
        * Added automated acquisition of Trimmomatic adapters
        * Implemented MACS2 peak calling
        * Added autodetection of tag sequence length

    v0.08:
        * Initial Github Upload

