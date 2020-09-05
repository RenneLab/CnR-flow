
Workflow
===============

| The CUT&RUN-Flow (CnR-flow) workflow is designed to be simple to install and execute 
  without sacrificing analysis capabilities. Nextflow_ [Nextflow_Citation]_ provides several
  features that facilitate this design, included automatic download of 
  dependencies and i/o handling between workflow components.

Full Workflow:
    .. image:: ../../build_info/dotgraph_parsed.png
        :alt: CUT&RUN-Flow Pipe Flowchart

Download and Installation
--------------------------

    (If necessary, begin by installing Nextflow_ and Conda_ as 
    described in :ref:`Quickstart`)

    | Nextflow allows the pipeline to be downloaded simply by using the 
      "nextflow run" command, and providing the user/repository path to
      the relevant github repository. CnR-flow has a one-step installation 
      mode that can be performed simultaneously ( :cl_param:`--mode initiate` ).
    | Together, this gives the command:

    .. code-block:: bash
  
        $ nextflow run RenneLab/CnR-flow --mode initiate

    | This should download the pipeline, install the few required local 
      files and dependencies, and prepare the pipeline for execution.

    .. note:: | After the initial download, the pipeline can then be referred
                to by name, as with: 
              | "nextflow run CnR-flow ..."

Dependency Setup and Validation
-------------------------------

    | cnr-flow comes preconfigured to utilize the conda environment management
      together with bioconda packages to handle dependency utilization.
    | for more details, or for an alternative configuration, see 
      :ref:`dependency config`

    | either using the default dependency configuration, or with a user's
      custom configuration, the dependency setup can then be tested using the 
      :cl_param:`--mode validate` or :cl_param:`--mode validate_all` parameters.

    .. code-block:: bash
       :name: mode_validate_all

        # validate all workflow dependencies (recommended)
        $ nextflow run CnR-flow --mode validate_all

    .. code-block:: bash
       :name: mode_validate

        # validate only steps enabled in nextflow.config
        $ nextflow run CnR-flow --mode validate

Reference Preparation
----------------------

    | CnR-flow provides one-step preparation of alignment reference genome(s)
      for use by the pipeline. Either the local path or URL of a fasta file are 
      provided to the :param:`ref_fasta` paramater, and the execution
      is performed with:

    .. code-block:: bash
       :name: mode_prep_fasta
  
        $ nextflow run CnR-flow --mode prep_fasta

    | This copies the reference fasta to the directory specified by 
      :param:`ref_dir`, creates a bowtie2 alignment reference, 
      creates a fasta index using Samtools, and creates a ".chrom.sizes" 
      file using `UCSC faCount <faCount>`_ [faCount_Citation]_.
      The effective genome size is also calculated
      with faCount_, using the (Total - N's) method. 
      Reference details are written to a ".refinfo.txt" in the same directory.
    
    .. note:: If normalization is enabled, the same process will be repeated 
              for the fasta file supplied to :param:`norm_ref_fasta`
              for alignments to the spike-in control genome.

    | These referenes are then detected automatically, using the same parameter
      used for preparation setup. For more details, see :ref:`Task Setup`.
      The list of all detectable prepared databases can be provided using the
      :cl_param:`mode list_refs` run mode:

    .. code-block:: bash
       :name: mode_list_refs
  
        $ nextflow run CnR-flow --mode list_refs

Experimental Condition
----------------------

    | CUT&RUN-Flow allows automated handling of treatment (Ex: H3K4me3) 
      and and control (Ex: IgG) input files, performing the analysis steps
      on each condition in parallel, and then associating the treatment with the 
      control for the final peak calling step. This can be performed either
      with a single treatment/control group, or with multiple groups in parallel.
      For more information, see :ref:`Task Setup`.

 
Preprocessing Steps
----------------------

GetSeqLen
+++++++++

    This step is enabled with paramater :flag_param:`do_retrim` 
    (default: :obj:`true`).
    This step takes one example input fastq[.gz] file and determines 
    the sequence length, for use in later steps.

MergeFastqs
+++++++++++

    This step is enabled with paramater :flag_param:`do_merge_lanes`
    (default: :obj:`true`).
    If multiple sets of paired end files are provided that differ only by
    the "_L00#_" component of the name, these sequences are concatenated for
    further analysis.

    For example, these files will be merged into the common name: 'my_sample_CTRL_R(1/2)_001.fastq.gz'::

        ./my_sample_CTRL_L001_R1_001.fastq.gz ./my_sample_CTRL_L001_R2_001.fastq.gz
        ./my_sample_CTRL_L002_R1_001.fastq.gz ./my_sample_CTRL_L002_R2_001.fastq.gz
        #... --> 
        ./my_sample_CTRL_R1_001.fastq.gz ./my_sample_CTRL_R2_001.fastq.gz

FastQCPre   
+++++++++

    This step is enabled with paramater :flag_param:`do_fastqc`
    (default: :obj:`true`).
    FastQC_ [FastQC_Citation]_ is utilized to perform quality control checks on the input
    (presumably untrimmed) fastq[.gz] files. 

Trim   
+++++++++

    | This step is enabled with paramater :flag_param:`do_trim` (default: :obj:`true`).
      Trimming of input fastq[.gz] files for read quality and adapter content
      is performed by Trimmomatic_ [Trimmomatic_Citation]_.
    | 
    | Default trimming parameters:

    .. include:: ../../build_info/config_zz_auto_trimmomatic_settings.txt
       :literal:

    | Default flags:
 
    .. include:: ../../build_info/config_zz_auto_trimmomatic_flags.txt
       :literal:

Retrim
+++++++++

    | This step is enabled with paramater :flag_param:`do_retrim` 
      (default: :obj:`true`). Trimming of input fastq[.gz] 
      files is performed by the kseq_test executable
      from the CUTRUNTools_ toolkit [CUTRUNTools_Citation]_. It is 
      designed to identify and remove very short adapter sequences 
      from tags that were potentially missed by previous trimming steps.

FastQCPost   
+++++++++++

    This step is enabled with paramater :flag_param:`do_fastqc`
    (default: :obj:`true`).
    FastQC_ [FastQC_Citation]_ is utilized to perform quality control checks on 
    sequences after any/all trimming steps are performed.

Alignment Steps
----------------------

Aln_Ref
+++++++++

    | Sequence reads are aligned to the reference genome using 
      Bowtie2_ [Bowtie2_Citation]_.
    | Default alignment parameters were selected using concepts 
      presented in work by the Henikoff Lab [Meers2019]_
      and the Yuan Lab [CUTRUNTools_Citation]_.
    |
    | Default flags:
 
    .. include:: ../../build_info/config_zz_auto_aln_ref_flags.txt
       :literal:

    .. warning:: None of the output alignments (.sam/.bam/.cram) files
       produced in this step (or indeed, anywhere else in the pipeline)
       are normalized. The only normalized outputs are are genome 
       genome coverage tracks produced if normalization is enabled.

Modify_Aln
++++++++++

    | Output alignments are then subjected to several cleaning, 
      filtering, and preprocessing steps utilizing 
      Samtools_ [Samtools_Citation]_. 
    | These are:
    
    #. Removal of unmapped reads (samtools view)
    #. Sorting by name (samtools sort [required for fixmate])
    #. Adding/correcting mate pair information (samtools fixmate -m)
    #. Sorting by genome coordinate (samtools sort)
    #. Marking duplicates (samtools mkdup)
    #. ( Optional Processing Steps [ see below ] )
    #. Alignment compression BAM -> CRAM (samtools view)
    #. Alignment indexing (samtools index)

    | Optional processing steps include:
    
    * Removal of Duplicates
    * Filtering to reads <= 120 bp in length

    | The desired category (or categories) of output are selected
      with :param:`use_aln_modes`. Multiple categores can be specifically
      selected using :config_param:`use_aln_modes` as a list, and the
      resulting selections are analyzed and output in parallel.
    | (Example: :config_param:`use_aln_modes ['all', 'less_120_dedup']`)

        +--------------------+----------------------+-------------------------+
        | **Option**         | **Deduplicated**     | **Length <= 120bp**     |
        +--------------------+----------------------+-------------------------+
        | all                | false                | false                   |
        +--------------------+----------------------+-------------------------+
        | all_dedup          | true                 | false                   |
        +--------------------+----------------------+-------------------------+
        | less_120           | false                | true                    |
        +--------------------+----------------------+-------------------------+
        | less_120_dedup     | true                 | true                    |
        +--------------------+----------------------+-------------------------+

    | Default mode:
 
    .. include:: ../../build_info/config_zz_auto_use_aln_modes.txt
       :literal:

Make_Bdg
++++++++++

    | Further cleaning steps are then performed on the outputs, to prepare
      the alignments for (optional) normalization and peak calling.
    | These modifications are performed as suggested by the Henikoff lab
      in the documentation for SEACR, 
      https://github.com/FredHutch/SEACR/blob/master/README.md
      [SEACR_Citation]_ , and are performed utilizing
      Samtools_ [Samtools_Citation]_ and bedtools_ [bedtools_Citation]_.

    | These are:
    
    #. Sorting by name and uncompress CRAM -> BAM (samtools sort)
    #. Covert BAM to bedgraph (bedtools bamtobed)
    #. Filter discordant tag pairs (awk)
    #. Change bedtools bed format to BEDPE format (cut | sort)
    #. Convert BEDPE to (non-normalized) bedgraph (bedtools genomecov)

    .. note:: Genome coverage tracks output by this step are NOT normalized.

Normalization Steps
----------------------

Aln_Spike
+++++++++

    | This step is enabled with paramater :flag_param:`do_norm_spike`
      (default: :obj:`true`).
    | This step calculates a normalization factor for scaling output
      genome coverage tracks. 

    Strategy:
        A dual-alignment strategy is used to 
        filter out any reads that cross-map to both the primary reference
        and the normalization references. Sequence pairs that align to 
        the normalization reference are then re-aligned to the primary
        reference. The number of read pairs that align to both references
        is then subtracted from the normalization factor output by this
        step, depending on the value of :param:`norm_mode` 
        (default: :obj:`true`).
    
    Details:
        | Sequence reads are first aligned to the normalization reference 
          genome using Bowtie2_ [Bowtie2_Citation]_.
          Default alignment parameters are the same as with 
          alignment to the primary reference genome.
        
        Default flags:
 
            .. include:: ../../build_info/config_zz_auto_aln_norm_flags.txt
               :literal:
   
        | All reads that aligned to the normalization reference are then again
          aligned to the primary reference using Bowtie2_ [Bowtie2_Citation]_.
        |
        | Counts are then performed of **pairs** of sequence reads that align
          (and re-align, respectively) to each reference using Samtools_ 
          [Samtools_Citation]_ (via ``samtools view``). 
          The count of aligned pairs to the spike-in genome 
          reference is then returned, with the number of cross-mapped pairs 
          subtracted depending on the value of :param:`norm_mode`.

        +---------------+----------------------------------------------+
        | norm_mode     | Normalization Factor Used                    |
        +---------------+----------------------------------------------+
        | all           | norm_ref_aligned (pairs)                     |
        +---------------+----------------------------------------------+
        | adj           | norm_ref_aligned - cross_map_aligned (pairs) |
        +---------------+----------------------------------------------+

        .. include:: ../../build_info/config_zz_auto_norm_mode.txt
           :literal:
  
Norm_Bdg
+++++++++

    | This step is enabled with paramater :flag_param:`do_norm_spike`
      (default: :obj:`true`).
    | This step uses a normalization factor to create scaled
      genome coverage tracks. The calculation as provided by the 
      Henikoff Lab: 
      https://github.com/Henikoff/Cut-and-Run/blob/master/spike_in_calibration.csh
      [Meers2019]_ is:

        :math:`count_{norm} = (count_{site} * norm\_scale) / norm\_factor`
    
    | Thus, the scaling factor used is calucated as: 

        :math:`scale\_factor = norm\_scale / norm\_factor`

    | Where ``norm_factor`` is calculated in the previous step,
      and the arbitrary ``norm_scale`` is provided by the parameter:
      :param:`norm_scale`.
    |
    | Default ``norm_scale`` value:
 
    .. include:: ../../build_info/config_zz_auto_norm_scale.txt
       :literal:

    | The normalized genome coverage track is then created by bedtools_ 
      [bedtools_Citation]_ using the ``-scale`` option.

Conversion Steps
----------------------

Make_BigWig
+++++++++++

    | This step is enabled with paramater :flag_param:`do_make_bigwig`
      (default: :obj:`true`).
    | This step converts the output genome coverage file from the
      previous steps as in the UCSC bigWig file format using 
      `UCSC bedGraphToBigWig <bedGraphToBigWig>`_, a genome coverage
      format with significantly decreased file size [bedGraphToBigWig_Citation]_.

    .. warning:: The bigWig file format is a "lossy" file format that
       cannot be reconverted to bedGraph with all information intact.

Peak Calling Steps
----------------------

| One or more peak callers can be used for peak calling. 
  The peak caller used is determined by :param:`peak_callers`.
  This can either be provided a single argument, as with:

    :param:`peak_callers seacr`

| ...or can be configured using a list:

    :config_param:`peak-callers ['macs', 'seacr']`

| Default ``peak_callers`` value:

    .. include:: ../../build_info/config_zz_auto_peak_callers.txt
       :literal:


Peaks_MACS2
+++++++++++

    | This step is enabled if ``macs`` is included in
      :config_param:`peak-callers`.
    | This step calls peaks using the **non-normalized** alignment data
      produced in previous steps, 
      using the MACS2_ peak_caller [MACS2_Citation]_

    Default MACS2 Settings:

    .. include:: ../../build_info/config_zz_auto_macs_settings.txt
       :literal:


Peaks_SEACR
+++++++++++

    | This step is enabled if ``seacr`` is included in
      :config_param:`peak_callers`.
    | This step calls peaks using the **normalized** alignment data
      produced in previous steps (if normalization is enabled,
      using the SEACR_ peak caller [SEACR_Citation]_.
    |
    | *Special thanks to the Henikoff group for their permission to 
      distribute SEACR bundled with this pipeline.*
    

    Parameters:
        :param:`seacr_norm_mode` passes either ``norm`` or ``non`` 
        to SEACR. Options:

        * ``'auto'`` :
            * if ``do_norm = true``  - Passes ``'non'`` to SEACR
            * if ``do_norm = false`` - passes ``'norm'`` to SEACR         
        * ``'norm'``
        * ``'non'``

        | :param:`seacr_fdr` is passed directly to SEACR.
      
        | :param:`seacr_call_stringent` - SEACR is called in "stringent" mode.
        | :param:`seacr_call_relaxed` - SEACR is called in "relaxed" mode.
        | (If both of these are true, both outputs will be produced)        

    Default SEACR Settings:

    .. include:: ../../build_info/config_zz_auto_seacr_settings.txt
       :literal:

