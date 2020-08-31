
CnR-flow
==================================
.. image:: https://img.shields.io/github/v/release/dstrib/cnr-flow?include_prereleases
   :target: https://github.com/dstrib/cnr-flow/releases
   :alt: GitHub release (latest by date including pre-releases)
.. image:: https://travis-ci.com/dstrib/CnR-flow.svg?branch=master
   :target: https://travis-ci.com/dstrib/CnR-flow
   :alt: Travis-CI Build Status
.. image:: https://readthedocs.org/projects/cnr-flow/badge/?version=latest
   :target: https://CnR-flow.readthedocs.io/en/latest/?badge=latest
   :alt: ReadTheDocs Documentation Status
.. image:: https://img.shields.io/badge/nextflow-%3E%3D20.07.01-green
   :target: https://www.nextflow.io/
   :alt: Nextflow Version Required >= 20.07.01
.. image:: https://img.shields.io/badge/License-GPLv3+-blue
   :target: https://www.gnu.org/licenses/gpl-3.0.en.html
   :alt: GNU GPLv3+ License

| Welcome to *CUT&RUN-Flow* (*CnR-flow*), a Nextflow pipeline for QC, tag 
  trimming, normalization, and peak calling for paired-end sequencing 
  data from CUT&RUN experiments.
| This software is available via GitHub, at 
  http://www.github.com/dstrib/CnR-flow .
| Full project documentation is available at
  `CUT&RUN-Flow's ReadTheDocs Documentation <https://cnr-flow.readthedocs.io/>`_.
|
| CUT&RUN-Flow is built using `Nextflow <http://www.nextflow.io>`_, a powerful 
  domain-specific workflow language built to create flexible and 
  efficient bioinformatics pipelines. 
  Nextflow provides extensive flexibility in utilizing cluster 
  computing environments such as `PBS <https://www.openpbs.org/>`_ 
  and `SLURM <https://slurm.schedmd.com/>`_, 
  and in automated and compartmentalized handling of dependencies using 
  `Conda <https://docs.conda.io/en/latest/>`_ 
  and `Environment Modules <http://modules.sourceforge.net/>`_.
|
| CUT&RUN-Flow utilizes `FastQC <https://www.bioinformatics.babraham.ac.uk/projects/fastqc/>`_
  for quality control,
  `Trimmomatic <http://www.usadellab.org/cms/?page=trimmomatic>`_
  and `CUT&RUN-Tools:kseq_test <https://bitbucket.org/qzhudfci/cutruntools/src>`_ 
  for tag trimming,
  `Bowtie2 <http://bowtie-bio.sourceforge.net/bowtie2/index.shtml>`_
  for tag alignment,
  `Samtools <http://www.htslib.org/>`_, 
  `Picard <https://broadinstitute.github.io/picard/>`_,
  and `CUT&RUN-Tools <https://bitbucket.org/qzhudfci/cutruntools/src>`_
  for alignment manipulation, and 
  `MACS2 <https://github.com/macs3-project/MACS>`_ 
  and/or `SEACR <https://github.com/FredHutch/SEACR>`_
  for peak calling, as well as their associated language subdependencies of
  Java, Python2/3, R, and C++.
| In addition to standard local configurations, Nextflow allows handling of 
  dependencies in separated working environments within the same pipeline 
  using `Conda <https://docs.conda.io/en/latest/>`_
  or `Environment Modules <http://modules.sourceforge.net/>`_. 
  **CnR-Flow is pre-configured to acquire and utilize dependencies
  using conda environments with no additional required dependency setup.**
|
| A notable feature of CnR-flow pipeline is the ability to specify groups
  of samples containing both treatment and control (Ex: IgG) antibody
  groups, with automated association of each control sample with the 
  respective treatment samples during the peak calling step.
| Additionally, this pipeline includes an (optional) built-in normalization
  protocol to normalize to a sequence library of the user's choice
  when spike-in DNA is used in the CUT&RUN Protocol. An 
  *E. coli* reference genome is also provided with the pipline 
  included for utiliziation of *E. coli* as a spike-in control 
  as recently described by Meers et. al. (eLife 2019)
  (see the |References| section of |docs_link|_).
|
| For a full list of required dependencies and tested versions, see 
  the |Dependencies| section of |docs_link|_, and for dependency 
  configuration options see the |Dependency Config| section.

Quickstart:
------------

Here is a brief introduction on how to install and get started using the pipeline. 
For full details visit  `CUT&RUN-Flow's ReadTheDocs Documentation <https://cnr-flow.readthedocs.io/>`_.

Prepare Task Directory:
    Create a task directory, and navigate to it.

    .. code-block:: bash   

            mkdir /path/to/my_task
            cd /path/to/my_task

Install Nextflow (if necessary):
    | Download the nextflow executable to your current directory.
    | (You can move the nextflow executable and add to $PATH for 
      future usage)

    .. code-block:: bash

        curl -s https://get.nextflow.io | bash

        # For the following steps, use:
        nextflow    # If nextflow executable on $PATH (assumed)
        ./nextflow  # If running nextflow executable from local directory

Download and Install CnR-Flow:
    | Nextflow will download and store the pipeline in the 
      user's Nextflow info directory (Default: "~/.nextflow/")

    .. code-block:: bash

        nextflow run dstrib/CnR-flow --mode initiate    

Configure, Validate, and Test:
    | If using Nextflow's builtin Conda dependency handling (recommended),
      install miniconda (if necessary).
      `Installation instructions <https://docs.conda.io/en/latest/miniconda.html>`_
    | The CnR-flow configuration with Conda should then work "out-of-the-box."
    |
    | If using an alternative configuration, see the |Dependency Config|
      section of |docs_link|_ for dependency configuration options.
    |
    | Once dependencies have been configured, validate all dependencies:

    .. code-block:: bash

        nextflow run CnR-flow --mode validate_all

    | Fill the required task input paramaters in ".../my_task/nextflow.config"
    | For detailed setup instructions, see the  |Task Setup| 
      section of |docs_link|_
    | *Additionally, configure your system executor, time, and memory settings in the pipe
      configuration file, if necessary*

    .. code-block:: bash

        # Configure:
        .../my_task/nextflow.config   # Task Input, Steps, etc. Configuration
    
        #REQUIRED values to enter (all others *should* work as default):
        # ref_fasta               (or some other ref-mode/location)
        # treat_fastqs            (input paired-end fastq[.gz] file paths)
        #   [OR fastq_groups]     (mutli-group input paired-end .fastq[.gz] file paths)

Prepare and Execute Pipeline:
    | Prepare your reference databse (and normalization reference) from .fasta[.gz]
      file(s): 

    .. code-block:: bash

        $ nextflow run CnR-flow --mode prep_fasta

    | Perform a test run to check inputs, paramater setup, and process execution:

    .. code-block:: bash

        $ nextflow run CnR-flow --mode dry_run

    | If satisifed with the pipeline setup, execute the pipeline:

    .. code-block:: bash

        $ nextflow run CnR-flow --mode run

    | Further documentation on CUT&RUN-Flow components, setup, and usage can
      be found in |docs_link|_.

.. |References| replace:: *References*
.. |Dependency Config| replace:: *Dependency Configuration*
.. |Dependencies| replace:: *Dependencies*
.. |Task Setup| replace:: *Task Setup*
.. |docs_link| replace:: CUT&RUN-Flow's ReadTheDocs
.. _docs_link: https://cnr-flow.readthedocs.io#

.. include:: docs_readme_format.rst
