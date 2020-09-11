
Task Setup
================

Task Setup Overview
-------------------

    | After running using :cl_param:`mode initiate`, *CUT&RUN-Flow*
      will copy the task configuration template into your current 
      working directory. For a full example of this file, see 
      :ref:`Task nextflow.config`.

    .. code-block:: bash

        # Configure:
        $ <vim/nano...> ./my_task/nextflow.config   # Task Input, Steps, etc. Configuration
    
    | Task-level inputs such as input files and reference fasta files
      must be configured here (see :ref:`Input File Setup`).
      Additional task-specific settings are also configured here, such as 
      output read naming rules and output file locations 
      (see :ref:`Output Setup`).

    .. note:: These settings are provided for user customizability, but in 
       the majority of cases the default settings should work fine.
    
    | Many pipeline settings can justifiably be configured either
      on a task-specifc
      basis (in :ref:`Task nextflow.config`) or as defaults for the pipeline 
      (in :ref:`Pipe nextflow.config` ). These include nextflow "executor" 
      settings for use of SLURM_ and 
      `Environment Modules`_
      and associated settings such as memory and cpu usage. 
      These settings are described here, in :ref:`Executor Setup`, but can
      also be set in the :ref:`Pipe nextflow.config`.
    |
    | Likewise, settings for individual pipeline components such as
      Trimmomatic_ tag trimming paramaters, or the ``qval`` used for 
      MACS2_ peak calling can be provided in either config file,
      or both (for a description of 
      these parameters, see :ref:`Workflow`).

    .. note:: If any settings are provided in both the 
       above :ref:`Task nextflow.config` file and the 
       :ref:`Pipe nextflow.config` file located in the pipe directory, 
       the task-directory settings will take precedence. For more
       information on Nextflow configuration precedence, see
       :manpage:`config`.

Reference Files Setup
---------------------
    
    CUT&RUN-Flow handles reference database preparation with a series
    of steps utilizing :cl_param:`mode prep_fasta`. The location of the
    fasta used for preparation is provided to the :param:`ref_fasta`
    paramater as either a file path or URL.

    Reference preparation is then performed using::

        $ nextflow CnR-flow --mode prep_fasta

    This will place the prepared reference files in the directory 
    specified by :param:`refs_dir` (see :ref:`Output Setup`). Once 
    prepared, the this parameter can be dynamically used 
    during pipeline execution to detect
    the reference name and location, depending on the value of the
    :param:`ref_mode` parameter.

    Ref Modes:   
        * ``'fasta'`` : Get reference name from :param:`ref_fasta`
          (which must then be set)
        * ``'name'`` : Get reference name from :param:`ref_name` 
          (which must then be set)
        * ``'manual'`` : Set required paramaters manually:
          
        Ref Required Manual Paramaters:
          * :param:`ref_name` : Reference Name
          * :param:`ref_bt2db_path` : Reference Bowtie2 
            Alignment Reference Path
          * :param:`ref_chrom_sizes_path` : Path to 
            <reference>.chrom_sizes file
          * :param:`ref_eff_genome_size` : Effective genome size
            for reference.

    The :param:`ref_mode` parameter also applies to the preparation
    and location of the fasta used for the normalization reference 
    if :flag_param:`do_norm`. These paramaters are named in parallel
    using a ``norm_[ref...]`` prefix and are autodetected from the value
    of :param:`norm_ref_fasta` or :param:`norm_ref_name` depending on 
    the value of :param:`ref_mode`. For details on normalization steps,
    see :ref:`Normalization Steps`.

Input File Setup
-------------------

    Two (mutually-exclusive) options are provided for supplying input 
    sample fastq[.gz] files to the workflow.

    Single Sample Group:
        | A single group of samples with zero or one (post-combination) control
          sample(s) for all treatment samples.

        * :param:`treat_fastqs`
        * :param:`ctrl_fastqs`

        .. include:: ../../build_info/config_zz_auto_inputs_single.txt
           :literal:


    .. note:: Note, for convenience, if the same file is
       found both as a treatment and control, the copy passed to treatment
       will be ignored (facilitates easy pattern matching).
 
    .. warning:: Input files must be paired-end, and in fastq[.gz] format.
       Nextflow requires the use of this (strange-looking) ``R{1,2}``
       naming construct, (matches either R1 or R2)
       which ensures that files are fed into the pipeline 
       as pairs.

    Multiple Sample Group:
        | A multi-group layout, with groups of samples provided
          where each group has a control sample.
          (All groups are required to have a control sample in this mode.) 
 
      * :config_param:`fastq_groups`

        .. include:: ../../build_info/config_zz_auto_inputs_group.txt
           :literal:

    Multiple pairs of files representing the same sample/replicate that 
    were sequenced on different lanes can be automatically recognized and
    combined (default: ``true``). For more information see: 
    :ref:`MergeFastqs`. 

Executor Setup
-------------------
    
    Nextflow provides extensive options for using cluster-based job
    scheduling, such as SLURM_, PBS_, etc. These options are worth 
    reviewing in the nextflow docs: :manpage:`executor`. The 
    specific executor is selected with the configuration setting:
    ``process.executor = 'option'``. The default value of 
    ``process.executor = 'local'`` runs the execution on the local
    filesystem. 

    Specific settings of note:
        +----------------------------+-----------------+
        | **Option**                 | **Example**     |
        +----------------------------+-----------------+
        | ``process.executor``       | ``'slurm'``     |
        +----------------------------+-----------------+
        | ``process.memory``         | ``'4 GB'``      |
        +----------------------------+-----------------+
        | ``process.cpus``           | ``4``           |
        +----------------------------+-----------------+
        | ``process.time``           | ``'1h'``        |
        +----------------------------+-----------------+
        | ``process.clusterOptions`` | ``'--qos=low'`` |
        +----------------------------+-----------------+
    
    | To facilitate process efficiency (and for adequate capacity)
      for different parts of the process, memory-related process
      labels have been applied to the processes:
      ``'small_mem'``, ``'norm_mem'``, and ``'big_mem'``. 
      These are specified using ``process.withLabel: my_label { key = value }``
      Example: ``process.withLabel: big_mem { memory = '16 GB' }``. 
    | A ``1n/2n/4n`` or ``1n/2n/8n`` strategy is recommended for the respective 
      ``small_mem/norm_mem/big_mem`` options.
      (for details on nextflow process labels, see
      `process <https://www.nextflow.io/docs/latest/process.html#label>`_).  
      Additionally, mutliple cpu usage is disabled for processes
      that do not support (or aren't significanlly more effective) with 
      multiple processes, and so the ``process.cpus`` setting only applies
      to processes within the pipeline with multiple CPUS enabled.

    .. include:: ../../build_info/config_2A_process_shared.txt
       :literal:

Output Setup
-------------------

    Output options can control the quantity, naming, and location of 
    output files from the pipeline.

    publish_files:
        Three modes are available for selecting the number of output files
        from the pipeline:

        * ``minimal`` : Only the final alignments are output. 
          (Trimmed Fastqs are Excluded)
        * ``default`` : Multiple types of alignments are output. 
          (Trimmed Fastqs are included)
        * ``all`` : All files produced by the pipline
          (excluding deleted intermediates) are output.
      
        This option is selected with :param:`publish_files`.

    publish_mode:
        This mode selects the value for the Nextflow 
        ``process.publishDir`` mode
        used to output files (for details, see: 
        `publishDir <https://www.nextflow.io/docs/latest/process.html#publishdir>`_).
        Available options are: 

        * ``'copy'`` : Copy output files (from the nextflow working directory)
          to the output folder.
        * ``'symlink'`` : Link to the output files located in the 
          nextflow working directory.

    trim_name_prefix & trim_name_suffix:
        | :config_param:`trim_name_prefix` & :config_param:`trim_name_suffix`
        | These options allow trimming of a prefix or suffix from sample
          names (after any merging steps).
  
    out_dir:
        :param:`out_dir` : Location for output of the files.

    refs_dir:
        :param:`refs_dir` : Location for placing and searching 
        for reference directories.

    .. include:: ../../build_info/config_zz_auto_naming.txt
       :literal:

