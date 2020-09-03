
CUT&RUN-Flow (CnR-flow)
==================================
.. image:: https://img.shields.io/github/v/release/rennelab/cnr-flow?include_prereleases
   :target: https://github.com/rennelab/cnr-flow/releases
   :alt: GitHub release (latest by date including pre-releases)
.. image:: https://travis-ci.com/rennelab/CnR-flow.svg?branch=master
   :target: https://travis-ci.com/rennelab/CnR-flow
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
  http://www.github.com/rennelab/CnR-flow .
| Full project documentation is available at |docs_link|_.

Pipeline Design:
    | CUT&RUN-Flow is built using `Nextflow`_, a powerful 
      domain-specific workflow language built to create flexible and 
      efficient bioinformatics pipelines. 
      Nextflow provides extensive flexibility in utilizing cluster 
      computing environments such as `PBS`_ and `SLURM`_, 
      and in automated and compartmentalized handling of dependencies using 
      `Conda`_ / `Bioconda`_ and `Environment Modules <Environment_Modules>`_.
    
Dependencies:
    | In addition to standard local configurations, Nextflow allows handling of 
      dependencies in separated working environments within the same pipeline 
      using `Conda`_ or `Environment Modules <Environment_Modules>`_. 
      **CnR-Flow is pre-configured to acquire and utilize dependencies
      using conda environments with no additional required setup.**
    | CUT&RUN-Flow utilizes 
      `UCSC Genome Browser Tools <faCount>`_ and  `Samtools`_
      for reference library preparation,
      `FastQC`_ for tag quality control,
      `Trimmomatic`_ and `CUT&RUN-Tools:kseq_test <CUTRUNTools>`_ 
      for tag trimming, `Bowtie2`_ for tag alignment,
      `Samtools`_, `bedtools`_ and `UCSC Genome Browser Tools <faCount>`_
      for alignment manipulation, and `MACS2`_ and/or `SEACR`_
      for peak calling, as well as their associated language subdependencies of
      Java, Python2/3, R, and C++.

Pipeline Features:
    * One-step reference database prepration using a path (or URL)
      to a FASTA file.
    * Ability to specify groups
      of samples containing both treatment and control (Ex: IgG) antibody
      groups, with automated association of each control sample with the 
      respective treatment samples during the peak calling step
    * (Optional) Built-in normalization
      protocol to normalize to a sequence library of the user's choice
      when spike-in DNA is used in the CUT&RUN Protocol (Includes an 
      *E. coli* reference genome for utiliziation of *E. coli* 
      as a spike-in control as described by |Meers2019| 
      [see the |References| section of |docs_link|_])
    * SLURM, PBS... and many other job scheduling environments 
      enabled natively by Nextflow
    * Output of CRAM (alignment), bedgraph (genome coverage), 
      and bigWig (genome coverage) file formats

    |pipe_dotgraph|

| For a full list of required dependencies and tested versions, see 
  the |Dependencies| section of |docs_link|_, and for dependency 
  configuration options see the |Dependency Config| section.

Quickstart:
------------

Here is a brief introduction on how to install and get started using the pipeline. 
For full details, see |docs_link|_.

Prepare Task Directory:
    | Create a task directory, and navigate to it.

    .. code-block:: bash   

            $ mkdir /path/to/my_task  # (Example)
            $ cd /path/to/my_task     # (Example)

Install Nextflow (if necessary):
    | Download the nextflow executable to your current directory.
    | (You can move the nextflow executable and add to $PATH for 
      future usage)

    .. code-block:: bash

        $ curl -s https://get.nextflow.io | bash

        # For the following steps, use:
        nextflow    # If nextflow executable on $PATH (assumed)
        ./nextflow  # If running nextflow executable from local directory

Download and Install CnR-Flow:
    | Nextflow will download and store the pipeline in the 
      user's Nextflow info directory (Default: ``~/.nextflow/``)

    .. code-block:: bash

        $ nextflow run rennelab/CnR-flow --mode initiate    

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

        $ nextflow run CnR-flow --mode validate_all

    | Fill the required task input paramaters in "nextflow.config"
      For detailed setup instructions, see the  |Task Setup| 
      section of |docs_link|_
      *Additionally, for usage on a SLURM, PBS, or other cluster, 
      configure your system executor, time, and memory settings in this
      pipe configuration file.*

    .. code-block:: bash

        # Configure:
        $ <vi/nano/emacs/...> nextflow.config   # Task Input, Steps, etc. Configuration
    
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
.. |Meers2019| replace:: *Meers et. al. (eLife 2019)*
.. |Dependency Config| replace:: *Dependency Configuration*
.. |Dependencies| replace:: *Dependencies*
.. |Task Setup| replace:: *Task Setup*
.. |pipe_dotgraph| image:: build_info/current_dotgraph.png
    :alt: CUT&RUN-Flow Pipe Flowchart
.. |docs_link| replace:: CUT&RUN-Flow's ReadTheDocs
.. _docs_link: https://cnr-flow.readthedocs.io#

.. _Nextflow: http://www.nextflow.io
.. _Bioconda: https://bioconda.github.io/
.. _CUTRUNTools: https://bitbucket.org/qzhudfci/cutruntools/src
.. _SEACR: https://github.com/FredHutch/SEACR
.. _R: https://www.r-project.org/
.. _Bowtie2: http://bowtie-bio.sourceforge.net/bowtie2/index.shtml
.. _faCount: https://hgdownload.cse.ucsc.edu/admin/exe/
.. _Samtools: http://www.htslib.org/
.. _FastQC: https://www.bioinformatics.babraham.ac.uk/projects/fastqc/
.. _Trimmomatic: http://www.usadellab.org/cms/?page=trimmomatic
.. _bedtools: https://bedtools.readthedocs.io/en/latest/
.. _bedGraphToBigWig: https://hgdownload.cse.ucsc.edu/admin/exe/
.. _MACS2: https://github.com/macs3-project/MACS
.. _PBS: https://www.openpbs.org/
.. _SLURM: https://slurm.schedmd.com/
.. _CONDA: https://slurm.schedmd.com/
.. _Environment_Modules: http://modules.sourceforge.net/

.. include:: docs_readme_format.rst
