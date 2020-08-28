
CnR-flow
==================================
.. image:: https://img.shields.io/badge/nextflow-%3E%3D20.07.01-brightgreen
   :target: https://www.nextflow.io/
   :alt: Nextflow Version Required >= 20.07.01
.. COMMENT
   image:: https://img.shields.io/github/v/release/RenneLab/hybkit?include_prereleases
   :target: https://github.com/RenneLab/hybkit/releases
   :alt: GitHub release (latest by date including pre-releases)
.. image:: https://travis-ci.com/dstrib/CnR-flow.svg?branch=master
   :target: https://travis-ci.com/dstrib/CnR-flow
   :alt: Travis-CI Build Status
.. image:: https://readthedocs.org/projects/CnR-flow/badge/?version=latest
   :target: https://CnR-flow.readthedocs.io/en/latest/?badge=latest
   :alt: ReadTheDocs Documentation Status
.. image:: https://img.shields.io/badge/License-GPLv3+-blue
   :target: https://www.gnu.org/licenses/gpl-3.0.en.html
   :alt: GNU GPLv3+ License

| Welcome to CUT&RUN-Flow (CnR-flow), a Nextflow pipeline for QC, tag 
  trimming, normalization, and peak calling for paired-end sequencing 
  data from CUT&RUN experiments.
| This software is available via GitHub, at 
  http://www.github.com/dstrib/cnr-flow .
| Full project documentation is available at
  `CUT&RUN-Flow's ReadTheDocs Documentation <https://cnr-flow.readthedocs.io/>`_.

| CUT&RUN-Flow is built using `Nextflow <www.nextflow.io>`, a powerful 
  domain-specific workflow language built to creat flexible and 
  efficient bioinformatics pipelines. 
  Nextflow provides extensive flexibility in utilizing cluster 
  computing environments such as `PBS <https://www.openpbs.org/>` 
  and `SLURM <https://slurm.schedmd.com/>`, 
  and in automated and compartmentalized handling of dependencies using 
  `Conda <https://docs.conda.io/en/latest/>` 
  and `Environment Modules <http://modules.sourceforge.net/>`.

| CUT&RUN-Flow utilizes `Trimmomatic <http://www.usadellab.org/cms/?page=trimmomatic>`
  and `CUT&RUN-Tools:kseq_test <https://bitbucket.org/qzhudfci/cutruntools/src>` 
  for tag trimming,
  `Bowtie2 <http://bowtie-bio.sourceforge.net/bowtie2/index.shtml>`
  for tag alignment
  `Samtools <http://www.htslib.org/>`, 
  `Picard <https://broadinstitute.github.io/picard/>`,
  and `CUT&RUN-Tools <https://bitbucket.org/qzhudfci/cutruntools/src>`
  for alignment manipulation, and 
  `MACS2 <https://github.com/macs3-project/MACS>` 
  and/or `SEACR <https://github.com/FredHutch/SEACR>`
  for peak calling, as well as their associated language subdependencies of
  Java, Python2/3, R, and C++.
| In addition to standard local configurations, Nextflow allows handling of 
  dependencies in separated working environments within the same pipeline 
  using `Conda <https://docs.conda.io/en/latest/>`
  or `Environment Modules <http://modules.sourceforge.net/>`. 
| CnR-Flow is pre-configured to acquire and utilize dependencies
  using conda environments with no required dependency setup.
| For a full list of required dependencies and tested versions, see 
  the |Dependencies| section of |docs_link|_, and for dependency 
  configuration options see the |Dependency Config| section.

Quickstart
==========

Here is a brief introduction on how to install and get started using the pipeline. 
For full details visit  `CUT&RUN-Flow's ReadTheDocs Documentation <https://cnr-flow.readthedocs.io/>`_.

Install nextflow (if necessary):
.. code-block:: bash

    curl -s https://get.nextflow.io | bash

If using Nextflow's builtin Conda dependency handling (recommended),
install miniconda (if necessary):

    Installation instructions at: https://docs.conda.io/en/latest/miniconda.html

Create a task directory, and navigate to it.

.. code-block:: bash

    mkdir /path/to/my_task
    cd    /path/to/my_task

| Download and Install CnR-Flow:
| (Nextflow will download and store the pipeline in the 
  user's nextflow information directory, default: "~/.nextflow/" )

.. code-block:: bash

    #If nextflow in task directory:
    ./nextflow run dstrib/CnR-flow --mode initiate    

    #If nextflow on path:
    nextflow run dstrib/CnR-flow --mode initiate

If using an alternative configuration to conda, see the |Dependency Config|
section of |docs_link|_ for dependency configuration options.

Validate setup of dependencies using the command:

.. code-block:: bash

    nextflow run CnR-flow --mode validate_all

| Fill the required task paramater variables in .../my_task/nextflow.config
| For detailed setup instructions, see the  |Task Setup| 
  section of |docs_link|_  ::

    //REQUIRED values to enter (all others *should* work as default):
    // ref_fasta               (or some other ref-mode/location)
    // treat_fastqs            (input paired-end fastq[.gz] file paths)
    // [OR fastq_groups]       (mutli-group input paired-end .fastq[.gz] file paths)

| Configure your system executor, time, and memory settings in either the 
  .../CnR-Flow/nextflow.config or .../my_task/nextflow.config 
  to use cluster-based job submssion like SLURM, PBS, etc. (if applicable).

| Prepare your reference databse (and normalization reference) from .fasta[.gz]
  file(s): 

.. code-block:: bash

    nextflow run CnR-flow --mode prep_fasta

Perform a test run to check inputs, paramater setup, and process execution:

.. code-block:: bash

    nextflow run CnR-flow --mode dry_run

If satisifed with the pipeline setup, execute the pipeline.

.. code-block:: bash

    nextflow run CnR-flow --mode run

| Further documentation on CUT&RUN-Flow components, setup, and usage can
  be found in |docs_link|_.

.. |Dependency Config| replace:: *Dependency Configuration*
.. |Dependencies| replace:: *Dependencies*
.. |Task Setup| replace:: *Task Setup*
.. |docs_link| replace:: CUT&RUN-Flow's ReadTheDocs
.. _docs_link: https://cnr-flow.readthedocs.io#

.. include:: docs_readme_format.rst
