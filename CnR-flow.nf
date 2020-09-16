#!/usr/bin/env nextflow
//Daniel Stribling
//Renne Lab, University of Florida
//
//This file is part of CnR-flow.
//CnR-flow is free software: you can redistribute it and/or modify
//it under the terms of the GNU General Public License as published by
//the Free Software Foundation, either version 3 of the License, or
//(at your option) any later version.
//CnR-flow is distributed in the hope that it will be useful,
//but WITHOUT ANY WARRANTY; without even the implied warranty of
//MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//GNU General Public License for more details.
//You should have received a copy of the GNU General Public License
//along with CnR-flow.  If not, see <https://www.gnu.org/licenses/>.

// To prevent duplication, all required parameters are listed in the bundled files:
//   /CnR-flow/nextflow.config
//   /CnR-flow/templates/nextflow.config.backup

// --------------- Setup Default Pipe Variables: ---------------
params.verbose = false
params.help = false
params.h = false
params.version = false
params.v = false
params.out_front_pad = 4
params.out_prop_pad = 17

// --------------- Check (and Describe) "--mode" param: ---------------
    modes = ['initiate', 'validate', 'validate_all', 'prep_fasta',
             'list_refs', 'dry_run', 'run', 'help', 'version']
    usage = """\
    USAGE:
        nextflow [NF_OPTIONS] run CnR-flow --mode <run-mode> [PIPE_OPTIONS]

    Run Modes:
        initiate     : Copy configuration templates to current directory
        validate     : Validate current dependency configuration
        validate_all : Validate all dependencies
        prep_fasta   : Prepare alignment reference(s) from <genome>.fa[sta]
        list_refs    : List prepared alignment references
        dry_run      : Check configruation and all inputs, but don't run pipeline
        run          : Run pipeline
        help         : Print help and usage information for pipeline
        version      : Print pipeline version
    """

    help_description = """\
    ${workflow.manifest.name} Nextflow Pipeline, Version: ${workflow.manifest.version}
    This nextflow pipeline analyzes paired-end data in .fastq[.gz] format 
    created from CUT&RUN Experiments.

    """.stripIndent()
    full_help = "\n" + help_description + usage    
    full_version = " -- ${workflow.manifest.name} : ${workflow.manifest.mainScript} "
    full_version += ": ${workflow.manifest.version}"  

if( params.containsKey('mode') && params.mode == 'prep_all' ) { params.mode = 'prep' }

if( params.help || params.h ) {
    println full_help
    exit 0
} else if( params.version || params.v ) {
    println full_version
    exit 0
} else if( !params.containsKey('mode') ) {
    println ""
    log.warn "--mode Keyword ('params.mode) not provided." 
    log.warn "Use --h, --help, --mode=help, or --mode help  for more information."
    log.warn "Defaulting to --mode='dry_run'"
    log.warn ""
    params.mode = 'dry_run'
} else if( !modes.any{it == params.mode} ) {
    println ""
    log.error "Unrecognized --mode Keyword ('params.mode):"
    log.error "    '${params.mode}'"
    log.error ""
    println usage
    exit 1
} else if( params.mode == 'help' ) {
    println full_help
    exit 0
} else if( params.mode == 'version' ) {
    println full_version
    exit 0
} else {
    log.info ""
    log.info "Utilizing Run Mode: ${params.mode}"
}

print_in_files = []

// If mode is 'prep_fasta', ensure "ref_fasta" has been provided.
if( ['prep_fasta'].contains(params.mode) ) {
    test_params_key(params, 'ref_fasta', 'nonblank')
    if( !file("${params.ref_fasta}", checkIfExists: false).exists() ) {
        message = "File for reference preparation does not exist:\n"
        message += "    genome_sequence: ${params['ref_fasta']}\n"
        message += check_full_file_path(params['ref_fasta'])
        log.error message
        exit 1
    }
// If 'list_refs' mode, ensure refs dir is defined.
} else if(['list_refs'].contains(params.mode)) {
    test_params_key(params, 'refs_dir')
     
// If a run or validate mode, ensure all required keys have been provided correctly.
} else if(['run', 'dry_run', 'validate', 'validate_all'].contains(params.mode) ) {
    // Check to ensure required keys have been provided correctly.
    first_test_keys = [
        'do_merge_lanes', 'do_fastqc', 'do_trim', 'do_retrim', 'do_norm_spike', 
        'do_make_bigwig',
        'peak_callers', 'java_call', 'bowtie2_build_call', 'samtools_call',
        'facount_call', 'bedgraphtobigwig_call',
        'fastqc_call', 'trimmomatic_call', 'kseqtest_call', 'bowtie2_call', 
        'bedtools_call', 'macs2_call', 
        'seacr_call', 'out_dir', 'refs_dir', 'log_dir', 'prep_bt2db_suf',
        'merge_fastqs_dir', 'fastqc_pre_dir', 'trim_dir', 'retrim_dir',
        'fastqc_post_dir', 'aln_dir_ref', 'aln_dir_spike', 'aln_dir_mod',
        'aln_dir_norm', 'aln_bigwig_dir', 'peaks_dir_macs', 'peaks_dir_seacr',
        'verbose', 'help', 'h', 'version', 'v', 'out_front_pad', 'out_prop_pad', 
        'trim_name_prefix', 'trim_name_suffix'
    ]
    first_test_keys.each { test_params_key(params, it) } 
    use_tests = []
    req_keys  = []
    req_files = []
    
    // If Run mode, automatically set reference keys based on reference mode.
    if (['run', 'dry_run'].contains(params.mode) ) {
        if( !params.containsKey('ref_mode') ) {
            log.warn "No --ref_mode (params.ref_mode) parameter provided."
            log.warn "Defaulting to 'fasta'"
            log.warn ""
            params.ref_mode = 'fasta'
        }
        test_params_key(params, 'ref_mode', ['manual', 'name', 'fasta'])
        ref_key = ''
        norm_ref_key = ''
        // If an automatic mode is enabled, get details.
        if( ['name', 'fasta'].contains(params.ref_mode) ) {
            if( params.verbose ) {
                log.info ""
                log.info "Using Automatic Reference Location Mode: ${params.ref_mode}"
                log.info ""
            }
            ref_info = get_ref_details(params, 'ref')
            if( params.verbose ) { 
                log.info "Identified Reference Database Details:"
                ref_info.each {detail ->
                    log.info "- ref_${detail.key}".padRight(21) + " : ${detail.value}"
                }
            }
            // Set database details.
            ref_info.each {detail -> 
                if( !params.containsKey(detail.key) ) {
                    params["ref_${detail.key}".toString()] = detail.value
                } else if( !(['name', 'fasta'].contains(detail_key) ) ) {
                    log.warn "Key: ref_${detail.key} already exists in params."
                    log.warn "-   Skipping auto-setting of this params value."
                    println ""
                }
            }
            params.ref_eff_genome_size = file(params.ref_eff_genome_path).text.trim()
            if( params.verbose ) {
                log.info 'Setting --ref_eff_genome_size (params.ref_eff_genome_size)'
                log.info "-  to identified value: ${params.ref_eff_genome_size}"
            }
            if( params.do_norm_spike ) {
                ref_info = get_ref_details(params, 'norm_ref')
                if( params.verbose ) { 
                    log.info ""
                    log.info "Identified Normalization Reference Database Details:"
                    ref_info.each {detail ->
                        log.info "- norm_ref_${detail.key}".padRight(21) + " : ${detail.value}"
                    }
                }
                // Set database details.
                ref_info.each {detail -> 
                    if( !params.containsKey("norm_ref_${detail.key}".toString()) ) {
                        params["norm_ref_${detail.key}".toString()] = detail.value
                    } else if (!(['name', 'fasta'].contains(detail.key) ) ) {
                        log.warn "Key: norm_ref_${detail.key} already exists in params."
                        log.warn "-   Skipping auto-setting of this params value."
                        println ""
                    }
                }
            }
        } else {
            if( params.verbose ) {
                log.info "Using Manual Reference File Location Paramaters."
                log.info ""
            }
        }
    }

    test_commands = [
        "Java": ["${params.java_call} -version", 0, *get_resources(params, 'java')],
        "bowtie2-build": ["${params.bowtie2_build_call} --version", 0, 
            *get_resources(params, 'bowtie2')],
        "faCount": ["${params.facount_call}", 255, *get_resources(params, 'facount')],
        "Samtools": ["${params.samtools_call} help", 0, *get_resources(params, 'samtools')],
        "FastQC": ["${params.fastqc_call} -v", 0, *get_resources(params, 'fastqc')], 
        "Trimmomatic": ["${params.trimmomatic_call} -version", 0, *get_resources(params, 'trimmomatic')],
        "kseqtest": ["${params.kseqtest_call}", 1, *get_resources(params, 'kseqtest') ],
        "bowtie2": ["${params.bowtie2_call} --version", 0, *get_resources(params, 'bowtie2')],
        "bedtools": ["${params.bedtools_call} --version", 0, *get_resources(params, 'bedtools')],
        "MACS2": ["${params.macs2_call} --version", 0, *get_resources(params, 'macs2')],
        "SEACR": ["${params.seacr_call}", 1, *get_resources(params, 'seacr')],
        "bedGraphToBigWig": ["${params.bedgraphtobigwig_call}", 255, 
            *get_resources(params, 'bedgraphtobigwig')],
    ] 

    // General Keys and Params:
    req_keys.add(['publish_files', ['minimal', 'default', 'all']])
    req_keys.add(['publish_mode', ['symlink', 'copy']])

    // Keys and Params for merging langes
    if( params.do_merge_lanes ) {
        null // No custom settings
    }
    // Keys and Params for FastQC
    if( params.do_fastqc ) {
        use_tests.add(["FastQC", *test_commands["FastQC"]])
        req_keys.add(['fastqc_flags'])
    }
    // Keys and Params for Trimmomatic trimming
    if( params.do_trim ) {
        use_tests.add(["Trimmomatic", *test_commands["Trimmomatic"]])
        req_files.add(['trimmomatic_adapterpath'])
        req_keys.add(['trimmomatic_settings'])
        req_keys.add(['trimmomatic_flags'])
    }
    // Keys and Params for Trimmomatic trimming
    if( params.do_retrim ) {
        use_tests.add(["kseqtest", *test_commands["kseqtest"]])
        req_keys.add(['input_seq_len'])
    }
    // keys and params for alignment steps
    if( true ) {
        use_tests.add(["bowtie2", *test_commands["bowtie2"]])
        use_tests.add(["Samtools", *test_commands["Samtools"]])
        use_tests.add(["bedtools", *test_commands["bedtools"]])
        req_keys.add(['ref_bt2db_path'])
        req_keys.add(['ref_name'])
        req_keys.add(['aln_ref_flags'])
        req_keys.add(['use_aln_modes',
            ['all', 'all_dedup', 'less_120', 'less_120_dedup']])
        req_files.add(['ref_chrom_sizes_path'])
    }
    // keys and params for normalization
    if( params.do_norm_spike ) {
        req_keys.add(['norm_scale'])
        req_keys.add(['aln_norm_flags'])
        req_keys.add(['norm_ref_bt2db_path'])
        req_keys.add(['norm_ref_name'])
        req_keys.add(['norm_mode', ['adj', 'all']])
    }
    // keys and params for bigWig creation
    if( params.do_make_bigwig ) {
        req_keys.add(['norm_mode', ['adj', 'all']])
        use_tests.add(["bedGraphToBigWig", *test_commands["bedGraphToBigWig"]])
    }
    // keys and params for peak calling
    req_keys.add(['peak_callers', ['macs', 'seacr']])
    if( params.peak_callers.contains('macs') ) {
        use_tests.add(["MACS2", *test_commands["MACS2"]])
        req_keys.add(['macs_qval'])
        req_keys.add(['macs_flags'])
        req_keys.add(['ref_eff_genome_size'])
    }
    if( params.peak_callers.contains('seacr') ) {
        use_tests.add(["SEACR", *test_commands["SEACR"]])
        req_keys.add(['seacr_fdr_threshhold'])
        req_keys.add(['seacr_norm_mode', ['auto', 'norm', 'non']])
        req_keys.add(['seacr_call_stringent', [true, false]])
        req_keys.add(['seacr_call_relaxed', [true, false]])
    }

    // If validate_all, ignore prepared tests and test all dependencies.
    if( params.mode == 'validate_all' ) {
        use_tests = []
        test_commands.each{test -> use_tests.add([test.key, *test.value]) }
    }

    // If a Run Mode, Test Step-Specific Keys and Required Files:
    if( ['run', 'dry_run'].contains(params.mode) ) {
        test_params_keys(params, req_keys)
        test_params_files(params, req_files) 
    }
}

// If run mode, ensure input files have been provided and test existence.
if( ['run', 'dry_run'].contains(params.mode) ) {
    if( params.containsKey('treat_fastqs') && params.containsKey('fastq_groups') ) {
        message =  "Please provide input fastq file data to either of \n"
        message += "    --treat_fastqs  (params.treat_fastqs)\n"
        message += " or --fastq_groups  (params.fastq_groups)\n"
        message += "    (not both)\n"
        log.error message
        exit 1
    // If Input files are via params.treat_fastqs
    } else if( params.containsKey('treat_fastqs') ) { 
        if( !params.treat_fastqs ) {
            err_message = "params.treat_fastqs cannot be empty if provided."
            log.error err_message
            exit 1
        }
        // Check Existence of treat and control fastqs if provided.
        if( params.treat_fastqs instanceof List ) {
            params.treat_fastqs.each{it -> print_in_files.addAll(file(it, checkIfExists: true)) }
        } else {
            print_in_files.addAll(file(params.treat_fastqs, checkIfExists: true))
        }
        if( params.containsKey('ctrl_fastqs') ) {
            if( params.ctrl_fastqs instanceof List ) {
                params.ctrl_fastqs.each{it -> print_in_files.addAll(file(it, checkIfExists: true)) }
            } else {
                print_in_files.addAll(file(params.ctrl_fastqs, checkIfExists: true))
            }
        }
    
    // If Input files are via params.fastq_groups
    } else if( params.containsKey('fastq_groups') ) {
        if( !params.fastq_groups ) {
            err_message = "params.fastq_groups cannot be empty if provided."
            log.error err_message
            exit 1
        }
        params.fastq_groups.each {group_name, group_details ->
            if( !group_details.containsKey('treat') || !group_details.treat ) {
                err_message =  "params.fastq_groups - Group: '${group_name}\n"
                err_message += "    Does not contain required key 'treat' or variable is empty."
                log.error err_message
                exit 1
            }
            if( !group_details.containsKey('ctrl') || !group_details.ctrl ) {
                warn_message =  "params.fastq_groups - Group: '${group_name}\n"
                warn_message += "    Does not contain key 'ctrl' or variable is empty.\n\n"
                warn_message += "(If this is intentional, please consider using '--treat_fastqs\n'"
                warn_message += "    parameter instead for file input as this may produce \n"
                warn_message += "    unexpected output)"
                log.warn warn_message
            }
            if( group_details.treat instanceof List ) {
                group_details.treat.each{it -> print_in_files.addAll(file(it, checkIfExists: true)) }
            } else {
                print_in_files.addAll(file(group_details.treat, checkIfExists: true)) 
            }
            if( group_details.containsKey('ctrl') ) {
                if( group_details.ctrl instanceof List ) {
                    group_details.ctrl.each{it -> 
                        print_in_files.addAll(file(it, checkIfExists: true))
                    }
                } else {
                    print_in_files.addAll(file(group_details.ctrl, checkIfExists: true)) 
                }
            }
        }
    }
}

use_aln_modes = return_as_list(params['use_aln_modes'])
peak_callers  = return_as_list(params['peak_callers'])

// --------------- If Verbose, Print Nextflow Command: ---------------
if( params.verbose ) { print_command(workflow.commandLine) }

// --------------- Parameter Setup ---------------
log.info ''
log.info ' -- Preparing Workflow Environment -- '
log.info ''

// --------------- Print Workflow Details ---------------

// If Verbose, Print Workflow Details:
if( params.verbose ) {
    print_workflow_details(workflow, params, params.out_front_pad, params.out_prop_pad)
}

// -- If a Run Mode, Check-for and Print Input Files
if( ['run', 'dry_run'].contains( params.mode) ) {
    if( print_in_files.size() < 2 ) {
        message =  "No Input Files Provided.\n"
        message += "Please provide valid --treat_fastqs (params.treat_fastqs) option.\n"
        message += "   Exiting"
        log.error message
        exit 1

    } else if( params.verbose ) {
        message = (
                   "-".multiply(params.out_front_pad)
                   + "Input Files:".padRight(params.out_prop_pad)
                   + print_in_files[0] 
                  )
        log.info message
        print_in_files.subList(1, print_in_files.size()).each {
    
            log.info "-".multiply(params.out_front_pad) + ' '.multiply(params.out_prop_pad) + it
        }
    } else {
        log.info "${print_in_files.size()} Input Files Detected. "
    }
}    

// --------------- Execute Workflow ---------------

log.info ''
log.info ' -- Executing Workflow -- '
log.info ''
System.out.flush(); System.err.flush()

// -- Run Mode: validate
if( ['initiate'].contains( params.mode ) ) { 
    //kseq_test_exe = file("${projectDir}/CUTRUNTools/kseq_test")
    //if( !(kseq_test_exe.exists()) ) {
    //    log.info "Downloading and Compiling Utilized CUTRUNTools Utilities"
    //    ret_text = "${projectDir}/CUTRUNTools/install_cutruntools.sh".execute().text
    //    println ret_text
    //    if (ret_text.contains("kseq_test Installation Failure.") 
    //        || !(kseq_test_exe.exists())) {
    //        println "kseq_test Installation Failure Detected."
    //        println "Please report issue to project developers."
    //        exit 1
    //    }
    //}
    trimmomatic_dir = file("${projectDir}/ref_dbs/trimmomatic_adapters")
    if( !(trimmomatic_dir.exists()) ) {
        log.info "Downloading Trimmomatic Sequence Adapter Files"
        println "${projectDir}/ref_dbs/get_trimmomatic_adapters.sh".execute().text
    }
    log.info "Copying CnR-flow nextflow task configuration into launch directory"
    task_config = file("${projectDir}/nextflow.config.task")
    task_config_target = file("${launchDir}/nextflow.config")
    task_config_nodoc = file("${projectDir}/nextflow.config.task.nodoc")
    task_config_nodoc_target = file("${launchDir}/nextflow.config.nodoc")
    task_config_minimal = file("${projectDir}/nextflow.config.task.nodoc.minimal")
    task_config_minimal_target = file("${launchDir}/nextflow.config.minimal")
    if( task_config_target.exists() ) {
        message =  "Cannot overwrite existing task config file:\n"
        message += "    ${task_config_target}\n"
        message += "Please remove and retry.\n"
        log.error message
        exit 1
    }
    task_config.copyTo("${task_config_target}")
    task_config_nodoc.copyTo("${task_config_nodoc_target}")
    task_config_minimal.copyTo("${task_config_minimal_target}")
    log.info ""
    log.info "Initialization Complete."
    log.info "Please configure pipeline cluster / dependency settings (if necessary) at:"
    log.info "-   ${projectDir}/nextflow.config"
    log.info ""
    log.info "Please modify task configuration file:"
    log.info "-   ${task_config_target}"
    log.info "Then check using 'validate' or 'dry_run' modes to test setup."
    println ""
}

// -- Run Mode: validate
if( ['validate', 'validate_all'].contains( params.mode ) ) { 
    process CnR_Validate {
        tag             { title }
        // Previous step ensures only one or another (non-null) resource is provided:
        module          { "${test_module}" }
        conda           { "${test_conda}" }
        label           'small_mem'   
        maxForks        1
        errorStrategy   'terminate'
        cpus            1
        echo            true

        input:
        tuple val(title), val(test_call), val(exp_code), val(test_module), val(test_conda) from Channel.fromList(use_tests)
        
        output:
        val('success') into validate_outs

        script:
        resource_string = ''
        if( task.module) { 
            resource_string = "echo -e '  -  Module(s): ${task.module.join(':')}'"
        } else if( task.conda) {
            resource_string = "echo -e '  -  Conda-env: \"${task.conda.toString()}\"'"
        }
        
        shell:
        '''
        echo -e "\\n!{task.tag}"
        !{resource_string}
        echo -e "\\nTesting System Call for dependency: !{title}"
        echo -e "Using Command:"
        echo -e "    !{test_call}\\n"

        set +e
        !{test_call}
        TEST_EXIT_CODE=$?
        set -e

        if [ "${TEST_EXIT_CODE}" == "!{exp_code}" ]; then
            echo "!{title} Test Success."
            PROCESS_EXIT_CODE=0
        else
            echo "!{title} Test Failure."
            echo "Exit Code: ${TEST_EXIT_CODE}"
            PROCESS_EXIT_CODE=${TEST_EXIT_CODE}
        fi
        exit ${PROCESS_EXIT_CODE} 
        '''
    }
    validate_outs
                .collect()
                .view { it -> "\nDependencies Have been Validated, Results:\n    $it\n" } 
}

def get_refs_locations(params) {
    refs_locations = [
        'refs_dir': params.refs_dir,
        'pipe_refs_dir': "${projectDir}/ref_dbs"
    ]
    if( params.containsKey('shared_refs_dir') ) {
        refs_locations['shared_refs_dir'] = params.shared_refs_dir
    }
    refs_locations
}

def search_refs (params, only_ref_name=null) {
    refs = [:]
    refs_locations = get_refs_locations(params)
    refs_locations.each {ref ->
        loc_name = ref.key
        loc_path = ref.value
        ref_dir = file(loc_path)
        //if( !ref_dir.exists() || !ref_dir.isDirectory() ) {
        //    log.error "Provided References Directory: '${loc_name}'"
        //    log.error "Cannot be found at location:"
        //    log.error "    ${loc_path}"
        //    log.error ""
        //    exit 1
        //}
        if( ref_dir.exists() && ref_dir.isDirectory() ) {
            ref_dir.eachFileMatch(~/.*\.refinfo\.txt$/) {ref_info_path ->
                ref_info_name = ref_info_path.getName()
                ref_name = ref_info_name - ~/\.refinfo\.txt$/
                refs[ref_name] = ref_info_path
            }
        }
    }
    if( only_ref_name ) {
        if( refs.containsKey(only_ref_name) ) {
            refs = [(only_ref_name): refs[only_ref_name]]
        } else {
            log.error "Reference: '${only_ref_name}' Cannot be located."
            println ''
            exit 1
        }
    }
    refs
}

// -- Run Mode: list_refs
if( params.mode == 'list_refs' ) { 
    ref_locations = get_refs_locations(params)
    refs = search_refs(params)
    if( refs.size() < 1 ) {
        log.info 'No Prepared References Found at Locations:'
        ref_locations.each{loc ->
            use_name = loc.value - ~/\.refinfo\.txt$/
            log.info '-' + "${loc.key}".padRight(15) + " : ${use_name}"
        }
        println ''
    } else {
        println ''
        log.info 'Prepared References: (name : location)'
        
        max_name_len = 0
        refs.each {ref -> 
            max_name_len = (ref.key.size() > max_name_len) ? ref.key.size() : max_name_len
        }
        refs.each {ref ->
            log.info "-- " + ref.key.padRight(max_name_len ) + " : ${ref.value}"
        }
        println ''
    }
}

// -- Run Mode: prep_fasta
if( params.mode == 'prep_fasta' ) { 
    if( !file("${params.refs_dir}").exists() ) {
        log.info "Creating Prep Directory: ${params.refs_dir}"
        println ""
        file("${params.refs_dir}").mkdir()
    }
    use_prep_sources = []
    prep_sources = [params.ref_fasta]
    if( params.containsKey('norm_ref_fasta') ) {
        prep_sources.add(params.norm_ref_fasta)
    }
    prep_sources.each {source_fasta ->
        if( "${source_fasta}".endsWith('.gz') ) {
            temp_name = file("${source_fasta}").getBaseName()
            db_name = file("${temp_name}").getBaseName()
        } else {
            db_name = file("${source_fasta}").getBaseName()
        }
        use_prep_sources.add([db_name, "${source_fasta}"])
    }
    Channel.fromList(use_prep_sources)
          .map {db_name, full_fn -> 
              use_full_fn = full_fn
              if( !("${full_fn}".contains('://')) 
                    && !("${full_fn}".startsWith('/') ) ) {
                  use_full_fn = "${launchDir}/${full_fn}"
              }
              [db_name, full_fn, file(full_fn)] 
          }
          .set {source_fasta}

    process CnR_Prep_GetFasta {
        tag          { name }
        label        'big_mem'
        beforeScript { task_details(task) }
        stageInMode  'copy'    
        echo         true

        input:
        tuple val(name), val(fasta_source), path(fasta) from source_fasta
    
        output:
        tuple val(name), path(use_fasta) into get_fasta_outs
        tuple val(name), val(get_fasta_details) into get_fasta_detail_outs
        path '.command.log' into get_fasta_log_outs
    
        publishDir "${params.refs_dir}/logs", mode: params.publish_mode, 
                   pattern: ".command.log", saveAs: { out_log_name }
        publishDir "${params.refs_dir}", mode: params.publish_mode, 
                   overwrite: false, pattern: "${use_fasta}*"
    
        script:
        run_id         = "${task.tag}.${task.process}"
        out_log_name   = "${run_id}.nf.log.txt"
        full_refs_dir  = "${params.refs_dir}"
        acq_datetime   = new Date().format("yyyy-MM-dd_HH:mm:ss")
        if( !(full_refs_dir.startsWith("/")) ) {
            full_refs_dir = "${workflow.launchDir}/${params.refs_dir}"
        }
        if( "${fasta}".endsWith('.gz') ) {
            use_fasta = fasta.getBaseName()  
            gunzip_command = "gunzip -c ${fasta} > ${use_fasta}"
        } else {
            use_fasta = fasta
            gunzip_command = "echo 'File is not gzipped.'"
        }
        get_fasta_details  = "name,${name}\n"
        get_fasta_details += "title,${name}\n"
        get_fasta_details += "fasta_source,${fasta_source}\n"
        get_fasta_details += "fastq_acq,${acq_datetime}\n"
        get_fasta_details += "fasta_path,./${use_fasta}"

        shell:
        '''
        echo "Acquiring Fasta from Source:"
        echo "    !{fasta}"
        echo ""
        !{gunzip_command}

        echo "Publishing Fasta to References Directory:"
        echo "   !{full_refs_dir}"    
    
        '''
    }

    get_fasta_outs.into{prep_bt2db_inputs; prep_sizes_inputs}

    process CnR_Prep_Bt2db {
        if( has_module(params, 'bowtie2') ) {
            module get_module(params, 'bowtie2')
        } else if( has_conda(params, 'bowtie2') ) {
            conda get_conda(params, 'bowtie2')
        }
        tag          { name }
        label        'big_mem'
        beforeScript { task_details(task) }
        echo         true
    
        input:
        tuple val(name), path(fasta) from prep_bt2db_inputs
    
        output:
        path "${bt2db_dir_name}/*" into prep_bt2db_outs
        tuple val(name), val(bt2db_details) into prep_bt2db_detail_outs
        path '.command.log' into prep_bt2db_log_outs
    
        publishDir "${params.refs_dir}/logs", mode: params.publish_mode, 
                   pattern: ".command.log", saveAs: { out_log_name }
        publishDir "${params.refs_dir}", mode: params.publish_mode, 
                   pattern: "${bt2db_dir_name}/*"
    
        script:
        run_id         = "${task.tag}.${task.process}"
        out_log_name   = "${run_id}.nf.log.txt"
        bt2db_dir_name = "${name}_${params.prep_bt2db_suf}"
        refs_dir       = "${params.refs_dir}"
        full_out_base  = "${bt2db_dir_name}/${name}"
        bt2db_details  = "bt2db_path,./${full_out_base}"
        shell:
        '''
    
        echo "Preparing Bowtie2 Database for fasta file:"
        echo "    !{fasta}"
        echo ""
        echo "Out DB Dir: !{bt2db_dir_name}"
        echo "Out DB:     !{full_out_base}"

        mkdir -v !{bt2db_dir_name}
        set -v -H -o history
        !{params.bowtie2_build_call} --quiet --threads !{task.cpus} !{fasta} !{full_out_base}
        set +v +H +o history

        echo "Publishing Bowtie2 Database to References Directory:"
        echo "   !{params.refs_dir}"    
    
        '''
    }
    
    process CnR_Prep_Sizes {
        if( has_module(params, ['samtools', 'facount']) ) {
            module get_module(params, ['samtools', 'facount'])
        } else if( has_conda(params, ['samtools', 'facount']) ) {
            conda get_conda(params, ['samtools', 'facount'])
        }
        tag          { name }
        beforeScript { task_details(task) }
        label        'norm_mem'
        cpus         1
        echo         true
    
        input:
        tuple val(name), path(fasta) from prep_sizes_inputs
    
        output:
        tuple path(faidx_name), path(chrom_sizes_name), path(fa_count_name),
              path(eff_size_name) into prep_sizes_outs
        tuple val(name), val(prep_sizes_details) into prep_sizes_detail_outs
        path '.command.log' into prep_sizes_log_outs
    
        publishDir "${params.refs_dir}/logs", mode: params.publish_mode, 
                   pattern: ".command.log", saveAs: { out_log_name } 
        publishDir "${params.refs_dir}", mode: params.publish_mode, 
                   pattern: "${name}*" 
    
        script:
        run_id = "${task.tag}.${task.process}"
        out_log_name = "${run_id}.nf.log.txt"
        faidx_name = "${fasta}.fai"
        chrom_sizes_name = "${name}.chrom.sizes"
        fa_count_name = "${name}.faCount"
        eff_size_name = "${name}.effGenome"
        prep_sizes_details  = "faidx_path,./${faidx_name}\n"
        prep_sizes_details += "chrom_sizes_path,./${chrom_sizes_name}\n"
        prep_sizes_details += "fa_count_path,./${fa_count_name}\n"
        prep_sizes_details += "eff_genome_path,./${eff_size_name}"
        shell:
        '''
        echo -e "\\nPreparing genome size information for Input Fasta: !{fasta}"
        echo -e "Indexing Fasta..."
        !{params.samtools_call} faidx !{fasta}
        echo -e "Preparing chrom.sizes File..."
        cut -f1,2 !{faidx_name} > !{chrom_sizes_name}
        echo -e "Counting Reference Nucleotides..."
        !{params.facount_call} !{fasta} > !{fa_count_name}
        echo -e "Calculating Reference Effective Genome Size (Total - N's method )..."
        TOTAL=$(tail -n 1 !{fa_count_name} | cut -f2) 
        NS=$(tail -n 1 !{fa_count_name} | cut -f7)
        EFFECTIVE=$( bc <<< "${TOTAL} - ${NS}")
        echo "${EFFECTIVE}" > !{eff_size_name}
        echo "Effective Genome Size: ${TOTAL} - ${NS} = ${EFFECTIVE}"
        echo "Done."
        '''
    }

    get_fasta_detail_outs
                        .concat(prep_sizes_detail_outs)
                        .concat(prep_bt2db_detail_outs)
                        .collectFile(
                            sort: false, newLine: true, 
                            storeDir: "${params.refs_dir}"
                        ) {name, details -> 
                            ["${name}.refinfo.txt", details]
                        }
                        .view { "Database Prepared and published in:\n    ${params.refs_dir}/${it}\nDetails:\n${it.text}" }
}

// -- Run Mode: 'dry_run'
if( params.mode == 'dry_run' ) {
    process CnR_DryRun {
        tag          { "my_input" }
        label        'norm_mem'
        beforeScript { task_details(task) }
        echo         true
    
        output:
        path "${test_out_file_name}" into dryRun_outs
        path '.command.log' into dryRun_log_outs
    
        publishDir "${params.out_dir}/${params.log_dir}", mode: params.publish_mode, 
                   pattern: ".command.log", saveAs: { out_log_name } 
        publishDir "${params.out_dir}", mode: params.publish_mode, 
                   pattern: "${test_out_file_name}"
    
        script:
        run_id = "${task.tag}.${task.process}"
        out_log_name = "${run_id}.nf.log.txt"
        test_out_file_name = "test_out_file.txt"
        shell:
        '''
        echo "Performing 'Dry Run' Test:"
    
        echo "Would Execute Pipeline now."
    
        echo "Creating Test Out File: !{test_out_file_name}"
        echo "Dry Run Test Output File Created on: $(date)" > !{test_out_file_name}
    
        echo -e '\\n"Dry Run" test complete.\\n'
        '''
    }
}

// -- Run Mode: 'run'
if( params.mode == 'run' ) { 
    use_ctrl_samples = false
    // If Input files are via params.treat_fastqs
    if( params.containsKey('treat_fastqs') ) { 
        Channel.fromFilePairs(params.treat_fastqs)
              .map {name, fastqs -> [name, 'treat', 'main', fastqs] }
              .set { treat_fastqs }
        //Create Channel of Control Fastas, if existing.
        if( params.containsKey('ctrl_fastqs') && params.ctrl_fastqs ) { 
            Channel.fromFilePairs(params.ctrl_fastqs)
                  .map {name, fastqs -> [name, 'ctrl', 'main', fastqs] }
                  .set { ctrl_fastqs } 
            use_ctrl_samples = true
            if( params.verbose ) {
                log.info "Control Samples Detected. Enabling Treatment/Control Peak-Calling Mode."
                log.info ""
            }
        } else {
            Channel.empty()
                  .set { ctrl_fastqs }
            use_ctrl_samples = false
            if( params.verbose ) {
                log.info "No Control Samples Detected."
                log.info ""
            }
            
        }
    // If Input files are via params.fastq_groups
    } else if( params.containsKey('fastq_groups') ) {
        treat_channels = []
        ctrl_channels = []
        params.fastq_groups.each {group_name, group_details ->
            treat_channels.add(
                Channel
                      .fromFilePairs(group_details.treat, checkIfExists: true)
                      .map {name, fastqs -> [name, 'treat', group_name, fastqs] }
                )

            if( group_details.containsKey('ctrl') ) {
                if( !use_ctrl_samples ) {
                    use_ctrl_samples = true
                    if( params.verbose ) {
                        log.info "Control Samples Detected. Enabling Treatment/Control Peak-Calling Mode."
                        log.info ""
                }
            }

                ctrl_channels.add(
                    Channel
                          .fromFilePairs(group_details.ctrl, checkIfExists: true)
                          .map {name, fastqs -> [name, 'ctrl', group_name, fastqs] }
                )
            }
        }
        Channel.empty()
              .mix(*treat_channels)
              .set { treat_fastqs }
        Channel.empty()
              .mix(*ctrl_channels)
              .set { ctrl_fastqs }
    }

    // Mix (Labeled) Treatment and Control Fastqs
    ctrl_fastqs
          .concat( treat_fastqs )
          // Remove duplicate ctrl also matched as treat:
          .unique { name, cond, group, fastqs -> name }
          .map { name, cond, group, fastqs ->
                 // Remove "_R" name suffix
                 name = name - ~/_R$/
                 [name, cond, group, fastqs]
               }
          .into { prep_fastqs; seq_len_fastqs }

    //If utilizing retrimming, autodetect or confirm tag size:
    if( params.do_retrim ) {
        if( params.input_seq_len == "auto" ) {
            process CnR_S0_A_GetSeqLen {
                label       'small_mem'
                executor    'local'
                cpus        1
                time        '1h'
                echo        params.verbose
                stageInMode 'copy'
        
                input:
                tuple val(name), val(cond), val(group), path(fastq) from seq_len_fastqs.first()
                
                output:
                env SIZE into input_seq_len
        
                script:
                test_fastq = fastq[0]
                if( "${test_fastq}".endsWith('.gz') ) {
                    first_command = "head -c 10000 ${test_fastq} | zcat 2>/dev/null"
                } else {
                    first_command = "cat ${test_fastq}"
                }
                shell:
                '''
                echo -e "Auto-detecting Tag Sequence Length:"
                echo -e "Using first provided file:"
                echo -e "    !{test_fastq}"

                !{first_command} | head -n 2 | tail -n 1 > seq.txt
                SIZE=$(cat seq.txt | head -c -1 | wc -c )
        
                echo "Read Size: ${SIZE}"
                '''
            }
        } else if( params.input_seq_len ) {
            Channel
                  .value(params.input_seq_len)
                  .set { input_seq_len }
        } else {
            log.error "Invalid Value for Paramater 'input_seq_len' provided:"
            log.error "-   '${input_seq_len}'"
            log.error ""
            exit 1
        }   
    }

    // If Merge, combine sample prefix-duplicates and catenate files.
    if( params.do_merge_lanes ) {
        prep_fastqs
                  // Remove "_L00?" name suffix
                  .map { name, cond, group, fastqs ->
                         name = name - ~/_L00\d$/ 
                         name = name - params.trim_name_prefix
                         name = name - params.trim_name_suffix
                         [name, cond, group, fastqs]
                       }
                  // Group files by common name
                  .groupTuple()
                  // Reformat grouped files so that fastqs are in lists of pairs.
                  .map {name, conds, groups, fastq_pairs ->
                        [name, conds[0], groups[0], fastq_pairs.flatten()]
                       }
                  .set { merge_fastqs } 
        
        // Step 0, Part A, Merge Lanes (If Enabled)
        process CnR_S0_B_MergeFastqs {
            tag          { name }
            label        'norm_mem'
            beforeScript { task_details(task) }
            cpus         1
           
            input:
            tuple val(name), val(cond), val(group), path(fastq) from merge_fastqs
        
            output:
            tuple val(name), val(cond), val(group), path("${merge_fastqs_dir}/${name}_R{1,2}_001.fastq.gz") into use_fastqs
            path '.command.log' into mergeFastqs_log_outs
        
            publishDir "${params.out_dir}/${params.log_dir}", mode: params.publish_mode, 
                       pattern: '.command.log', saveAs: { out_log_name } 
            // Publish merged fastq files only when publish_files == all
            publishDir "${params.out_dir}", mode: params.publish_mode,
                       pattern: "${merge_fastqs_dir}/*", 
                       enabled: (params.publish_files == "all") 
        
            script:
            run_id = "${task.tag}.${task.process}"
            out_log_name = "${run_id}.nf.log.txt"
            merge_fastqs_dir = "${params.merge_fastqs_dir}"
            R1_files = fastq.findAll {fn ->
                "${fn}".contains("_R1_") || "${fn}".contains("_1.f") || "${fn}".contains("_1_")
            }
            R2_files = fastq.findAll {fn -> 
                "${fn}".contains("_R2_") || "${fn}".contains("_2.f") || "${fn}".contains("_2_")
            }
            R1_out_file = "${params.merge_fastqs_dir}/${name}_R1_001.fastq.gz"
            R2_out_file = "${params.merge_fastqs_dir}/${name}_R2_001.fastq.gz" 

            if( R1_files.size() < 1 || R2_files.size() < 1 ) {
                message = "Merge Error:\nR1 Files: ${R1_files}\nR2 Files: ${R2_Files}"
                throw new Exception(message)
            } else if( R1_files.size() == 1 && R2_files.size() == 1 ) {
                command = '''
                echo "No Merge Necessary. Renaming Files..."
                set -v -H -o history
                mkdir !{merge_fastqs_dir}
                mv -v "!{R1_files[0]}" "!{R1_out_file}"
                mv -v "!{R2_files[0]}" "!{R2_out_file}"
                set +v +H +o history
                '''
            } else {
                command = '''
                mkdir !{merge_fastqs_dir}
                echo -e "\\nCombining Files: !{R1_files.join(' ')}"
                echo "    Into: !{R1_out_file}"
                set -v -H -o history
                cat '!{R1_files.join("' '")}' > '!{R1_out_file}'
                set +v +H +o history
    
                echo -e "\\nCombining Files: !{R2_files.join(' ')}"
                echo "    Into: !{R2_out_file}"
                set -v -H -o history
                cat '!{R2_files.join("' '")}' > '!{R2_out_file}'
                set +v +H +o history
                '''
            }
            shell:
            command
        }
    // If Not Merge, Rename and Passthrough fastq files.
    } else {
        prep_fastqs
                  .map { name, cond, group, fastqs ->
                         name = name - params.trim_name_prefix
                         name = name - params.trim_name_suffix
                         [name, cond, group, fastqs]
                       }
                  .set { use_fastqs }
    }

    // Prepare Step 0/1 Input Channels
    use_fastqs.into { fastqcPre_inputs; trim_inputs } 
    
    // Step 0, Part C, FastQC Analysis (If Enabled)
    if( params.do_fastqc ) {
        process CnR_S0_C_FastQCPre {
            if( has_module(params, 'fastqc') ) {
                module get_module(params, 'fastqc')
            } else if( has_conda(params, 'fastqc') ) {
                conda get_conda(params, 'fastqc')
            }
            tag          { name }
            label        'small_mem'
            beforeScript { task_details(task) }
            cpus         1   //Multiple CPUS for FastQC are for multiple files.

            input:
            tuple val(name), val(cond), val(group), path(fastq) from fastqcPre_inputs
        
            output:
            path "${fastqc_out_dir}/*.{html,zip}" into fastqcPre_all_outs
            path '.command.log' into fastqcPre_log_outs
        
            publishDir "${params.out_dir}/${params.log_dir}", mode: params.publish_mode, 
                       pattern: '.command.log', saveAs: { out_log_name } 
            publishDir "${params.out_dir}", mode: params.publish_mode, 
                       pattern: "${fastqc_out_dir}/*"
        
            script:
            run_id         = "${task.tag}.${task.process}"
            out_log_name   = "${run_id}.nf.log.txt"
            fastqc_out_dir = params.fastqc_pre_dir
            fastqc_flags   = params.fastqc_flags
            shell:
            '''
            set -v -H -o history
            mkdir -v !{fastqc_out_dir}
            cat !{fastq} > !{name}_all.fastq.gz
            !{params.fastqc_call} !{fastqc_flags} -o !{fastqc_out_dir} !{name}_all.fastq.gz
            rm !{name}_all.fastq.gz  # Remove Intermediate
            set +v +H +o history
            '''
        }
    }

    // Step 1, Part A, Trim Reads using Trimmomatic (if_enabled)
    if( params.do_trim ) {
        process CnR_S1_A_Trim { 
            if( has_module(params, 'trimmomatic') ) {
                module get_module(params, 'trimmomatic')
            } else if( has_conda(params, 'trimmomatic') ) {
                conda get_conda(params, 'trimmomatic')
            }
            tag          { name }
            label        'small_mem'
            beforeScript { task_details(task) }
        
            input:
            tuple val(name), val(cond), val(group), path(fastq) from trim_inputs
        
            output:
            path "${params.trim_dir}/*" into trim_all_outs
            tuple val(name), val(cond), val(group), path("${params.trim_dir}/*.paired.*") into trim_outs
            path '.command.log' into trim_log_outs
        
            // Publish Log
            publishDir "${params.out_dir}/${params.log_dir}", mode: params.publish_mode, 
                       pattern: '.command.log', saveAs: { out_log_name }
            // Publish if publish_mode == 'all', or == 'default' and not last trim step.
            publishDir "${params.out_dir}", mode: params.publish_mode,
                       pattern: "${trim_dir}/*.paired.*",
                       enabled: (
                           (params.publish_files == "default" && !params.do_retrim)
                            || params.publish_files == "all"
                       )
        
            script:
            run_id               = "${task.tag}.${task.process}"
            out_log_name         = "${run_id}.nf.log.txt"
            trimmomatic_flags    = params.trimmomatic_flags 
            trimmomatic_settings = params.trimmomatic_settings
            trim_dir             = "${params.trim_dir}"       
            out_reads_1_paired   = "${trim_dir}/${name}_1.paired.fastq.gz"
            out_reads_1_unpaired = "${trim_dir}/${name}_1.unpaired.fastq.gz" 
            out_reads_2_paired   = "${trim_dir}/${name}_2.paired.fastq.gz"
            out_reads_2_unpaired = "${trim_dir}/${name}_2.unpaired.fastq.gz" 
            shell:
            '''
            mkdir !{trim_dir}
            echo "Trimming file name base: !{name} ... utilizing Trimmomatic"

            set -v -H -o history
            !{params.trimmomatic_call} PE \\
                          -threads !{task.cpus} \\
                          !{trimmomatic_flags} \\
                          !{fastq} \\
                          !{out_reads_1_paired}   \\
                          !{out_reads_1_unpaired} \\
                          !{out_reads_2_paired}   \\
                          !{out_reads_2_unpaired} \\
                          !{trimmomatic_settings}
            set +v +H +o history

            echo "Step 1, Part A, Trimmomatic Trimming, Complete."
            '''
        }
    // If not performing trimming, pass trim output to retrim channel.
    } else {
        trim_inputs.set { trim_outs } 
    }

    // Step 1, Part B, Retrim Sequences Using Cut&RunTools kseq_test (If Enabled)
    if( params.do_retrim ) {
        process CnR_S1_B_Retrim { 
            if( has_module(params, 'kseqtest') ) {
                module get_module(params, 'kseqtest')
            } else if( has_conda(params, 'kseqtest') ) {
                conda get_conda(params, 'kseqtest')
            }
            tag          { name }
            label        'small_mem'
            beforeScript { task_details(task) }
            cpus         1   
     
            input:
            tuple val(name), val(cond), val(group), path(fastq) from trim_outs
            val(seq_len) from input_seq_len        

            output:
            tuple val(name), val(cond), val(group), path("${params.retrim_dir}/*") into trim_final
            path '.command.log' into retrim_log_outs
        
            // Publish Log
            publishDir "${params.out_dir}/${params.log_dir}", mode: params.publish_mode, 
                       pattern: '.command.log', saveAs: { out_log_name }
            // Publish if publish_files == "all" or "default"
            publishDir "${params.out_dir}", mode: params.publish_mode, 
                       pattern: "${params.retrim_dir}/*",
                       enabled: (
                           params.publish_files == "all" 
                           || params.publish_files == 'default'
                       )
        
            script:
            run_id = "${task.tag}.${task.process}"
            out_log_name = "${run_id}.nf.log.txt"
        
            shell:
            '''
            mkdir !{params.retrim_dir}
            echo "Second stage (retrimming) name base: !{name} ... utilizing kseq_test ..."

            set -v -H -o history
            !{params.kseqtest_call} !{fastq[0]} !{seq_len} \\
                                    !{params.retrim_dir}/!{fastq[0]}
        
            !{params.kseqtest_call} !{fastq[1]} !{seq_len} \\
                                    !{params.retrim_dir}/!{fastq[1]}
            set +v +H +o history        

            echo "Step 1, Part B, kseq_test Trimming, Complete."
            '''
        }
    // If not performing retrimming, pass trim output onto alignments.
    } else {
        trim_outs.set { trim_final }
    }

    trim_final.into { aln_ref_inputs; aln_spike_inputs; fastqcPost_inputs }

    // Step 1, Part C, Evaluate Final Trimmed Sequences With FastQC (If Enabled)
    if( params.do_fastqc ) {
        process CnR_S1_C_FastQCPost {
            if( has_module(params, 'fastqc') ) {
                module get_module(params, 'fastqc')
            } else if( has_conda(params, 'fastqc') ) {
                conda get_conda(params, 'fastqc')
            }
            tag          { name }
            label        'small_mem'
            beforeScript { task_details(task) }
            cpus         1   //Multiple CPUS for FastQC are for multiple files.
           
            input:
            tuple val(name), val(cond), val(group), path(fastq) from fastqcPost_inputs
        
            output:
            path "${fastqc_out_dir}/*.{html,zip}" into fastqcPost_all_outs
            path '.command.log' into fastqcPost_log_outs
        
            publishDir "${params.out_dir}/${params.log_dir}", mode: params.publish_mode, 
                       pattern: '.command.log', saveAs: { out_log_name } 
            publishDir "${params.out_dir}", mode: params.publish_mode, 
                       pattern: "${fastqc_out_dir}/*"
        
            script:
            run_id         = "${task.tag}.${task.process}"
            out_log_name   = "${run_id}.nf.log.txt"
            fastqc_out_dir = params.fastqc_post_dir 
            fastqc_flags   = params.fastqc_flags
            shell:
            '''
            set -v -H -o history
            mkdir -v !{fastqc_out_dir}
            cat !{fastq} > !{name}_all.fastq.gz
            !{params.fastqc_call} !{fastqc_flags} -t !{task.cpus} -o !{fastqc_out_dir} !{name}_all.fastq.gz
            rm !{name}_all.fastq.gz  # Remove Intermediate
            set +v +H +o history
            '''
        }
    }

    // Step 2, Part A, Align Reads to Reference Genome(s)
    process CnR_S2_A_Aln_Ref {
        if( has_module(params, ['bowtie2', 'samtools']) ) {
            module get_module(params, ['bowtie2', 'samtools'])
        } else if( has_conda(params, ['bowtie2', 'samtools']) ) {
            conda get_conda(params, ['bowtie2', 'samtools'])
        }
        tag          { name }
        label        'norm_mem'
        beforeScript { task_details(task) }
    
        input:
        tuple val(name), val(cond), val(group), path(fastq) from aln_ref_inputs
    
        output:
        tuple val(name), val(cond), val(group), path("${params.aln_dir_ref}/*") into aln_outs
        path '.command.log' into aln_log_outs
    
        // Publish Log
        publishDir "${params.out_dir}/${params.log_dir}", mode: params.publish_mode, 
                   pattern: '.command.log', saveAs: { out_log_name }
        // Publish unsorted alignments only when publish_files == all
        publishDir "${params.out_dir}", mode: params.publish_mode, 
                   pattern: "${params.aln_dir_ref}/*",
                   enabled: (params.publish_files == "all")
    
        script:
        run_id         = "${task.tag}.${task.process}"
        out_log_name   = "${run_id}.nf.log.txt"
        aln_ref_flags  = params.aln_ref_flags
        ref_bt2db_path = params.ref_bt2db_path
    
        shell:
        '''
        set -o pipefail
        mkdir !{params.aln_dir_ref}
        echo "Aligning file name base: !{name} ... utilizing Bowtie2"
    
        set -v -H -o history
        !{params.bowtie2_call} -p !{task.cpus} \\
                               !{aln_ref_flags} \\
                               -x !{ref_bt2db_path} \\
                               -1 !{fastq[0]} \\
                               -2 !{fastq[1]} \\
                                 | !{params.samtools_call} view -bS - \\
                                   > !{params.aln_dir_ref}/!{name}.bam
        set +v +H +o history

        echo "Step 2, Part A, Alignment, Complete."
        '''
    }

    // Step 2, Part B, Sort and Process Alignments
    process CnR_S2_B_Modify_Aln {
        if( has_module(params, 'samtools') ) {
            module get_module(params, 'samtools')
        } else if( has_conda(params, 'samtools') ) {
            conda get_conda(params, 'samtools')
        }
        tag          { name }
        label        'big_mem'
        beforeScript { task_details(task) }
    
        input:
        tuple val(name), val(cond), val(group), path(aln) from aln_outs
    
        output:
        path "${params.aln_dir_mod}/*" into sort_aln_all_outs
        tuple val(name), val(cond), val(group), val("all"), 
              path("${params.aln_dir_mod}/${name}_sort.*") into sort_aln_outs_all
        tuple val(name), val(cond), val(group), val("all_dedup"), 
              path("${params.aln_dir_mod}/${name}_sort_dedup.*") into sort_aln_outs_all_dedup
        tuple val(name), val(cond), val(group), val("limit_120"), 
              path("${params.aln_dir_mod}/${name}_sort_120.*") into sort_aln_outs_120
        tuple val(name), val(cond), val(group), val("limit_120_dedup"), 
              path("${params.aln_dir_mod}/${name}_sort_dedup_120.*") into sort_aln_outs_120_dedup
        path '.command.log' into sort_aln_log_outs
    
        // Publish Log
        publishDir "${params.out_dir}/${params.log_dir}", mode: params.publish_mode, 
                   pattern: '.command.log', saveAs: { out_log_name }
        // If publish raw alingments only if publish_files == "all",
        publishDir "${params.out_dir}", mode: params.publish_mode, 
                   pattern: "${params.aln_dir_mod}/*",
                   enabled: (params.publish_files=="all")
    
        script:
        run_id              = "${task.tag}.${task.process}"
        out_log_name        = "${run_id}.nf.log.txt"
        aln_dir_mod         = "${params.aln_dir_mod}"
        ref_fasta           = "${params.ref_fasta_path}"
        aln_pre             = "${aln_dir_mod}/${name}_pre"
        aln_sort            = "${aln_dir_mod}/${name}_sort.cram"
        aln_sort_dedup      = "${aln_dir_mod}/${name}_sort_dedup.cram"
        aln_sort_120        = "${aln_dir_mod}/${name}_sort_120.cram"
        aln_sort_dedup_120  = "${aln_dir_mod}/${name}_sort_dedup_120.cram"
        dedup_metrics       = "${aln_dir_mod}/${name}.dedup_metrics.txt"
        add_threads         = (task.cpus ? (task.cpus - 1) : 0) 
        mem_flag            = ""
        if( "${task.memory}" != "null" ) {
            max_mem_per_cpu_fix = trim_split_task_mem(task, 9, 10, "MB", true)
            mem_flag = "-m " + max_mem_per_cpu_fix.split()[0] + "M"
        }
        shell:
        '''
        set -o pipefail
        mkdir -v !{aln_dir_mod}
        
        echo -e "\\nFiltering Unmapped Fragments for name base: !{name} ... utilizing samtools view"
        set -v -H -o history
        !{params.samtools_call} view -bh -f 3 -F 4 -F 8 \\
                                --threads !{add_threads} \\
                                -o !{aln_pre}.mapped.bam \\
                                !{aln}
        set +v +H +o history

        echo -e "\\nSorting by name in prepartion for duplicate marking for : !{name} ... utilizing samtools sort"
        set -v -H -o history
        !{params.samtools_call} sort -n \\
                                     -o !{aln_pre}.mapped.nsort.bam \\
                                     -@ !{task.cpus} \\
                                     !{mem_flag} \\
                                     !{aln_pre}.mapped.bam
        set +v +H +o history
        rm -v !{aln_pre}.mapped.bam  # Clean Intermediate File

        echo -e "\\nAdding mate information for: !{name} ... utilizing samtools fixmate"
        set -v -H -o history
        !{params.samtools_call} fixmate -m  \\
                                     --threads !{add_threads} \\
                                     !{aln_pre}.mapped.nsort.bam \\
                                     !{aln_pre}.mapped.nsort.fm.bam
        set +v +H +o history
        rm -v !{aln_pre}.mapped.nsort.bam  # Clean Intermediate File

        echo -e "\\Coordinate-sorting mate-marked BAM for name base: !{name} ... utilizing samtools sort"
        set -v -H -o history
        !{params.samtools_call} sort \\
                                -o !{aln_pre}.mapped.nsort.fm.csort.bam \\
                                !{mem_flag} \\
                                -@ !{task.cpus} \\
                                !{aln_pre}.mapped.nsort.fm.bam
        set +v +H +o history
        rm -v !{aln_pre}.mapped.nsort.fm.bam  # Clean Intermediate File

        echo "Marking duplicates for: !{name} ... utilizing samtools markdup"
        set -v -H -o history
        !{params.samtools_call} markdup \\
                       --threads !{add_threads} \\
                       !{aln_pre}.mapped.nsort.fm.csort.bam \\
                       !{aln_pre}.mapped.nsort.fm.csort.mkd.bam
        set +v +H +o history
        rm -v !{aln_pre}.mapped.nsort.fm.csort.bam  # Clean Intermediate File

        echo "Summarizing/outputting all alignments in cram (compressed) format: !{name} ... utilizing samtools view"
        set -v -H -o history
        !{params.samtools_call} view -Ch  \\
                                     -T !{ref_fasta} \\
                                     --threads !{add_threads} \\
                                     -o !{aln_sort} \\
                                     !{aln_pre}.mapped.nsort.fm.csort.mkd.bam
        set +v +H +o history
        rm -v !{aln_pre}.mapped.nsort.fm.csort.mkd.bam  # Clean Intermediate File
        
        echo "\\nRemoving Duplicates for name base: !{name} ... utilizing samtools view"
        set -v -H -o history
        !{params.samtools_call} view -Ch -F 1024  \\
                                     -T !{ref_fasta} \\
                                     --threads !{add_threads} \\
                                     -o !{aln_sort_dedup} \\
                                     !{aln_sort}
        set +v +H +o history
    
        echo -e "\\nFiltering Non-Deduplicated Alignments for name base: !{name} ... to < 120 utilizing samtools view"
        set -v -H -o history
        !{params.samtools_call} view -h \\
                                     --threads !{add_threads} \\
                                     -o !{aln_sort}.sam \\
                                     !{aln_sort}
        LC_ALL=C awk 'length($10) < 121 || $1 ~ /^@/' \\
                     !{aln_sort}.sam \\
                     > !{aln_sort}.120.sam
        !{params.samtools_call} view -Ch \\
                                     -T !{ref_fasta} \\
                                     --threads !{add_threads} \\
                                     -o !{aln_sort_120} \\
                                     !{aln_sort}.120.sam
        rm -v !{aln_sort}.sam !{aln_sort}.120.sam
        set +v +H +o history

        echo -e "\\nFiltering Deduplicated Alignments for name base: !{name} ... to < 120 utilizing samtools view"
        set -v -H -o history
        !{params.samtools_call} view -h \\
                                     --threads !{add_threads} \\
                                     -o !{aln_sort_dedup}.sam \\
                                     !{aln_sort_dedup}
        LC_ALL=C awk 'length($10) < 121 || $1 ~ /^@/' \\
                     !{aln_sort_dedup}.sam \\
                     > !{aln_sort_dedup}.120.sam
        !{params.samtools_call} view -Ch \\
                                     -T !{ref_fasta} \\
                                     --threads !{add_threads} \\
                                     -o !{aln_sort_dedup_120} \\
                                     !{aln_sort_dedup}.120.sam
        rm -v !{aln_sort_dedup}.sam !{aln_sort_dedup}.120.sam
        set +v +H +o history
        
        echo ""
        echo "Creating bam index files for name base: !{name} ... utilizing samtools index"

        set -v -H -o history
        !{params.samtools_call} index -@ !{add_threads} !{aln_sort}
        !{params.samtools_call} index -@ !{add_threads} !{aln_sort_dedup}
        !{params.samtools_call} index -@ !{add_threads} !{aln_sort_120}
        !{params.samtools_call} index -@ !{add_threads} !{aln_sort_dedup_120}
        set +v +H +o history

        echo "Step 2, Part B, (Sort -> Dedup -> Filter) Alignments, Complete."
        '''
    }
      
    use_aln_channels = []
    if( use_aln_modes.contains('all') ) {
        use_aln_channels.add(sort_aln_outs_all)
    }
    if( use_aln_modes.contains('all_dedup') ) {
        use_aln_channels.add(sort_aln_outs_all_dedup)
    }
    if( use_aln_modes.contains('less_120') ) {
        use_aln_channels.add(sort_aln_outs_120)
    }
    if( use_aln_modes.contains('less_120_dedup') ) {
        use_aln_channels.add(sort_aln_outs_120_dedup)
    }

    if( use_aln_channels.size() < 1 ) {
        log.error "No Valid Alignment Channels Enabled."
        log.error params.use_aln_channels
        exit 1
    } else if ( use_aln_channels.size() > 1 ) { 
        use_aln_channels[0]
            .mix(*(use_aln_channels.subList(1, use_aln_channels.size())))
            .set { use_mod_alns }
    } else {
        use_aln_channels[0]
            .set { use_mod_alns }
    }

    // Step 2, Part C, Create Paired-end Bedgraphs
    process CnR_S2_C_Make_Bdg {
        if( has_module(params, ['samtools', 'bedtools']) ) {
            module get_module(params, ['samtools', 'bedtools'])
        } else if( has_conda(params, ['samtools', 'bedtools']) ) {
            conda get_conda(params, ['samtools', 'bedtools'])
        }
        tag          { name }
        label        'big_mem'
        beforeScript { task_details(task) }
        cpus         1 // Effiency for multiple CPUS is too low for this task.    

        input:
        tuple val(name), val(cond), val(group), val(aln_type), path(aln) from use_mod_alns
    
        output:
        path "${aln_dir_bdg}/*" into bdg_aln_all_outs
        tuple val(name), val(cond), val(group), val(aln_type), 
              path("${aln_dir_bdg}/*.{bam,cram,bdg,frag}*", includeInputs: true ) into bdg_aln_outs

        path '.command.log' into bdg_aln_log_outs
    
        // Publish Log
        publishDir "${params.out_dir}/${params.log_dir}", mode: params.publish_mode, 
                   pattern: '.command.log', saveAs: { out_log_name }
        // Publish Bedgraph if publish_files == "default" or "minimal" and no normalization.
        publishDir "${params.out_dir}", mode: params.publish_mode, 
                   pattern: "${aln_dir_bdg}/*.bdg",
                   enabled: (
                       (params.publish_files == "minimal" && !params.do_norm_spike)
                       || (params.publish_files == "default")
                   )
        // Publish Coord-Sorted Bam Alignemnts if publish_files == "default"
        publishDir "${params.out_dir}", mode: params.publish_mode, 
                   pattern: "${aln_dir_bdg}/${aln_in}",
                   enabled: (params.publish_files=="default")
        // Publish All Outputs if publish_fiels == "all"
        publishDir "${params.out_dir}", mode: params.publish_mode, 
                   pattern: "${aln_dir_bdg}/*",
                   enabled: (params.publish_files=="all")
    
        
        script:
        run_id       = "${task.tag}.${task.process}.${aln_type}"
        out_log_name = "${run_id}.nf.log.txt"
        aln_dir_bdg  = "${params.aln_dir_bdg}.${aln_type}"
        aln_in       = "${aln[0]}"
        aln_in_base  = "${aln_in}" - ~/.cram$/ - ~/.bam$/
        aln_by_name  = "${aln_dir_bdg}/${aln_in_base}_byname.bam"
        aln_bed      = "${aln_dir_bdg}/${aln_in_base + ".bed"}"
        aln_bdg      = "${aln_dir_bdg}/${aln_in_base + ".bdg"}"
        chrom_sizes  = "${params.ref_chrom_sizes_path}"
        add_threads  = (task.cpus ? (task.cpus - 1) : 0) 
        mem_flag     = ""
        if( "${task.memory}" != "null" ) {
            max_mem_per_cpu_fix = trim_split_task_mem(task, 9, 10, "MB", true)
            mem_flag = "-m " + max_mem_per_cpu_fix.split()[0] + "M"
        }
    
        shell:
        '''
        echo ""
        mkdir -v !{aln_dir_bdg}
        cp -vPR !{aln_in} !{aln_dir_bdg}/!{aln_in}       

        echo "Sorting alignment file by name: !{aln_in} ... utilizing samtools sort"
        set -v -H -o history
        !{params.samtools_call} sort -n \\
                                     -@ !{task.cpus} \\
                                     !{mem_flag} \\
                                     -o !{aln_by_name} \\
                                     !{aln_in}
        set -v -H -o history
        echo ""
        echo "Convert BAM into Paired-end Bedgraph."
        echo "Procedure: https://github.com/FredHutch/SEACR/blob/master/README.md" 
        echo ""
        echo "Creating Bedgraph for file: !{aln_by_name} ... utilizing bamtools bamtobed"
         
        set -v -H -o history
        !{params.bedtools_call} bamtobed -bedpe -i !{aln_by_name} > !{aln_bed}
        set +v +H +o history

        echo ""
        echo "Modifying bed file file: !{aln_bed} ... utilizing awk, cut, and sort."
        set -v -H -o history
        awk '$1==$4 && $6-$2 < 1000 {print $0}' !{aln_bed} > !{aln_bed}.clean
        cut -f 1,2,6 !{aln_bed}.clean | sort -k1,1 -k2,2n -k3,3n > !{aln_bed}.clean.frag
        set +v +H +o history


        echo ""
        echo "Creating Bedgraph using bedtools genomecov."
        set -v -H -o history
        !{params.bedtools_call} genomecov -bg -i !{aln_bed}.clean.frag -g !{chrom_sizes} > !{aln_bdg}
        set +v +H +o history

        echo "Step 2, Part C, Convert (CRAM -> BAM -> BED -> BDG) Alignments, Complete."
        '''
    }
    
    if( params.do_norm_spike ) {
        use_name = params.norm_ref_name
        if( params.containsKey('norm_ref_title') ) {
            use_name = params.norm_ref_title 
        }
        spike_ref_dbs = [[use_name, params.norm_ref_bt2db_path]]

        // Step 3, Part A, Align Reads to Spike-In Genome (If Enabled)
        process CnR_S3_A_Aln_Spike {
            if( has_module(params, ['bowtie2', 'samtools']) ) {
                module get_module(params, ['bowtie2', 'samtools'])
            } else if( has_conda(params, ['bowtie2', 'samtools']) ) {
                conda get_conda(params, ['bowtie2', 'samtools'])
            }
            tag          { name }
            label        'norm_mem'
            beforeScript { task_details(task) }
        
            input:
            tuple val(name), val(cond), val(group), path(fastq) from aln_spike_inputs
            tuple val(spike_ref_name), val(spike_ref) from Channel.fromList(spike_ref_dbs).first()
        
            output:
            path "${params.aln_dir_spike}/*" into aln_spike_all_outs
            tuple val(name), path(aln_count_csv) into aln_spike_csv_outs
            tuple val(name), path(aln_spike_count) into aln_spike_outs
            path '.command.log' into aln_spike_log_outs
        
            // Publish Log
            publishDir "${params.out_dir}/${params.log_dir}", mode: params.publish_mode, 
                       pattern: '.command.log', saveAs: { out_log_name }
            // Publish count file if publish_file == "minimal" or "default"
            publishDir "${params.out_dir}", mode: params.publish_mode, 
                       pattern: "${aln_use_count}",
                       enabled:  (params.publish_files != "all") 
            // Publish report if publish_file == "default"
            publishDir "${params.out_dir}", mode: params.publish_mode, 
                       pattern: "${aln_count_report}",
                       enabled: (params.publish_files == "default")
            // Publish all files when publish_files == all
            publishDir "${params.out_dir}", mode: params.publish_mode, 
                       pattern: "${params.aln_dir_spike}/*",
                       enabled: (params.publish_files == "all")
        
            script:
            run_id           = "${task.tag}.${task.process}"
            out_log_name     = "${run_id}.nf.log.txt"
            ref_bt2db_path   = params.ref_bt2db_path
            if( params.containsKey('ref_title') ) {
                ref_name     = params.ref_title
            } else {
                ref_name     = params.ref_name
            }
            aln_norm_flags   = params.aln_norm_flags
            aln_spike_sam    = "${params.aln_dir_spike}/${name}.${spike_ref_name}.sam"
            aln_spike_fq     = "${params.aln_dir_spike}/${name}.${spike_ref_name}.fastq.gz"
            aln_spike_fq_1   = "${params.aln_dir_spike}/${name}.${spike_ref_name}.fastq.1.gz"
            aln_spike_fq_2   = "${params.aln_dir_spike}/${name}.${spike_ref_name}.fastq.2.gz"
            aln_cross_sam    = "${params.aln_dir_spike}/${name}.cross.${ref_name}.sam"
            aln_count        = "${params.aln_dir_spike}/${name}.${spike_ref_name}.count_report"
            aln_count_report = "${params.aln_dir_spike}/${name}.${spike_ref_name}.count_report.txt" 
            aln_count_csv    = "${params.aln_dir_spike}/${name}.${spike_ref_name}.count_report.csv" 
            aln_spike_count  = "${params.aln_dir_spike}/${name}.${spike_ref_name}.01.all.count.txt"
            aln_cross_count  = "${params.aln_dir_spike}/${name}.${spike_ref_name}.02.cross.count.txt"
            aln_adj_count    = "${params.aln_dir_spike}/${name}.${spike_ref_name}.03.adj.count.txt"
            if( params.norm_mode == 'adj') { 
                aln_use_count = aln_adj_count
            } else if( params.norm_mode == 'all' ) {
                aln_use_count = aln_spike_count
            }

            if( fastq[0].toString().endsWith('.gz') ) {
                count_command = 'echo "$(zcat < ' + "${fastq[0]}" + ' | wc -l)/4" | bc'
            } else {
                count_command = 'echo "$(wc -l ' + "${fastq[0]}" + ')/4" | bc'
            }
            shell:
            '''
            set -o pipefail
            mkdir !{params.aln_dir_spike}
            echo "Aligning file name base: !{name} ... utilizing Bowtie2"

            # Count Total Read Pairs
            PAIR_NUM="$(!{count_command})"
            MESSAGE="Counted ${PAIR_NUM} Fastq Read Pairs."
            echo -e "\\n${MESSAGE}\\n"
            echo    "${MESSAGE}" > !{aln_count_report}

            # Align Reads to Spike-in Genome
            set -v -H -o history
            !{params.bowtie2_call} -p !{task.cpus} \\
                                   !{aln_norm_flags} \\
                                   -x !{spike_ref} \\
                                   -1 !{fastq[0]} \\
                                   -2 !{fastq[1]} \\
                                   -S !{aln_spike_sam} \\
                                   --al-conc-gz !{aln_spike_fq}
                                          
            RAW_SPIKE_COUNT="$(!{params.samtools_call} view -Sc !{aln_spike_sam})"
            bc <<< "${RAW_SPIKE_COUNT}/2" > !{aln_spike_count}
            SPIKE_COUNT=$(cat !{aln_spike_count})
            SPIKE_PERCENT=$(bc -l <<< "scale=8; (${SPIKE_COUNT}/${PAIR_NUM})*100")
          
            set +v +H +o history

            MESSAGE="${SPIKE_COUNT} ( ${SPIKE_PERCENT}% ) Total Spike-In Read Pairs Detected"
            echo -e "\\n${MESSAGE}\\n"
            echo    "${MESSAGE}" >> !{aln_count_report}

            # Realign Spike-in Alignments to Reference Genome to Check Cross-Mapping
            set -v -H -o history
            !{params.bowtie2_call} -p !{task.cpus} \\
                                   !{aln_norm_flags} \\
                                   -x !{ref_bt2db_path} \\
                                   -1 !{aln_spike_fq_1} \\
                                   -2 !{aln_spike_fq_2} \\
                                   -S !{aln_cross_sam}

            RAW_CROSS_COUNT="$(!{params.samtools_call} view -Sc !{aln_cross_sam})"
            bc <<< "${RAW_CROSS_COUNT}/2" > !{aln_cross_count}
            CROSS_COUNT=$(cat !{aln_cross_count})
            set +v +H +o history

            MESSAGE="${CROSS_COUNT} Read Pairs Detected that Cross-Map to Reference Genome"
            echo -e "\\n${MESSAGE}\\n"
            echo    "${MESSAGE}" >> !{aln_count_report}
         
            # Get Difference Between All Spike-In and Cross-Mapped Reads
            OPERATION="${SPIKE_COUNT} - ${CROSS_COUNT}"
            bc <<< "${OPERATION}" > !{aln_adj_count}  
            ADJ_COUNT=$(cat !{aln_adj_count})
            ADJ_PERCENT=$(bc -l <<< "scale=8; (${ADJ+COUNT}/${PAIR_NUM})*100")

            MESSAGE="$(cat !{aln_adj_count}) (${OPERATION}, ${ADJ_PERCENT}) Adjusted Spike-in Reads Detected."
            echo -e "\\n${MESSAGE}\\n"
            echo    "${MESSAGE}" >> !{aln_count_report}

            MESSAGE="\\nNormalization Mode: !{params.norm_mode}\\n"
            MESSAGE+="Selecting file for use in sample normalization:\\n"
            MESSAGE+="    !{aln_use_count}"
            echo -e "\\n${MESSAGE}\\n"
            echo -e "${MESSAGE}" >> !{aln_count_report}

            echo -e "name,fq_pairs,spike_aln_pairs,spike_aln_pct,cross_aln_pairs,cross_aln_pct,adj_aln_pairs,adj_aln_pct" > !{aln_count_csv}
            echo -e "!{name},${PAIR_NUM},${SPIKE_COUNT},${SPIKE_PERCENT},${CROSS_COUNT},CROSS_PCT,${ADJ_COUNT},${ADJ_PERCENT}" >> !{aln_count_csv}

            echo "Step 3, Part A, Spike-In Alignment, Complete."
            '''
        }

        aln_spike_outs
                  .cross(bdg_aln_outs)
                  .map {norm, samp -> 
                        [samp[0], samp[1], samp[2], samp[3], samp[4], norm[1]]
                  }
                  .set { norm_bdg_input }

        // Step 3, Part B, Normalize to Spike-in (If Enabled)
        process CnR_S3_B_Norm_Bdg {
            if( has_module(params, ['bedtools', 'samtools']) ) {
                module get_module(params, ['bedtools', 'samtools'])
            } else if( has_conda(params, ['bedtools', 'samtools']) ) {
                conda get_conda(params, ['bedtools', 'samtools'])
            }
            tag          { name }
            label        'norm_mem'
            beforeScript { task_details(task) }
            cpus         1        

            input:
            tuple val(name), val(cond), val(group), val(aln_type), path(aln), path(norm) from norm_bdg_input
        
            output:
            path "${aln_dir_norm}/*" into norm_all_outs
            tuple val(name), val(cond), val(group), val(aln_type), 
                  path("${aln_dir_norm}/*.{bam,bdg}*", includeInputs: true
                  ) into final_alns
            path '.command.log' into norm_log_outs
        
            // Publish Log
            publishDir "${params.out_dir}/${params.log_dir}", mode: params.publish_mode, 
                       pattern: '.command.log', saveAs: { out_log_name }
            // Publish bedgraph if publish_files == "minimal" or "default"
            publishDir "${params.out_dir}", mode: params.publish_mode, 
                       pattern: "${aln_dir_norm}/*_norm.bdg",
                       enabled: (params.publish_files!="all")
            // Publish all outputs if publish_files == "all"
            publishDir "${params.out_dir}", mode: params.publish_mode, 
                       pattern: "${aln_dir_norm}/*",
                       enabled: (params.publish_files=="all") 
            
            script:
            run_id        = "${task.tag}.${task.process}.${aln_type}"
            out_log_name  = "${run_id}.nf.log.txt"
            chrom_sizes   = "${params.ref_chrom_sizes_path}"
            aln_dir_norm  = "${params.aln_dir_norm}.${aln_type}"
            aln_bed_frag  = ( aln.findAll{fn -> "${fn}".endsWith(".frag") } )[0]
            aln_cram      = ( aln.findAll{fn -> "${fn}".endsWith(".cram") } )[0]
            aln_bdg       = ( aln.findAll{fn -> "${fn}".endsWith(".bdg")  } )[0]
            aln_byname    = ( aln.findAll{fn -> "${fn}".endsWith(".bam")  } )[0]
            bed_frag_base = "${aln_bed_frag}" - ~/.bed.clean.frag$/
            norm_bdg      = "${aln_dir_norm}/${bed_frag_base + '_norm.bdg'}"
        
            shell:
            '''
            mkdir -v !{aln_dir_norm}
            cp -vPR !{aln_cram} !{aln_bdg} !{aln_byname} !{aln_dir_norm}           

            echo "Calculating Scaling Factor..."
            # Reference: https://github.com/Henikoff/Cut-and-Run/blob/master/spike_in_calibration.csh
            CALC="!{params.norm_scale}/$(cat !{norm})"
            SCALE=$(bc -l <<< "scale=8; $CALC")

            echo "Scaling factor caluculated: ( ${CALC} ) = ${SCALE} "

            echo ""
            echo "Creating normalized bedgraph using bedtools genomecov."
            set -v -H -o history
            !{params.bedtools_call} genomecov -bg -i !{aln_bed_frag} -g !{chrom_sizes} -scale ${SCALE} > !{norm_bdg}
            set +v +H +o history

            echo "Step 3, Part B, Create Normalized Bedgraph, Complete."
            '''
        }
    } else {
        bdg_aln_outs.set { final_alns }
    }

    // Step 4, Part A, Create bigWig tracks from final alignments (if enabled)
    if( params.do_make_bigwig ) {

        final_alns.into { peak_call_alns; make_bigwig_alns }

        process CnR_S4_A_Make_BigWig {
            if( has_module(params, 'bedgraphtobigwig') ) {
                module get_module(params, 'bedgraphtobigwig')
            } else if( has_conda(params, 'bedgraphtobigwig') ) {
                conda get_conda(params, 'bedgraphtobigwig')
            }
            tag          { name }
            label        'norm_mem'
            beforeScript { task_details(task) }
            cpus         1

            input:
            tuple val(name), val(cond), val(group), val(aln_type), path(aln) from make_bigwig_alns
        
            output:
            tuple val(name), val(group), val(aln_type), path("${bigwig_dir}/*") into bigwig_outs
            path '.command.log' into bigwig_log_outs
        
            // Publish Log
            publishDir "${params.out_dir}/${params.log_dir}", mode: params.publish_mode, 
                       pattern: '.command.log', saveAs: { out_log_name }
            // Publish All Outputs
            publishDir "${params.out_dir}", mode: params.publish_mode, 
                       pattern: "${out_bigwig}"
            
            script:
            run_id       = "${task.tag}.${task.process}.${aln_type}"
            out_log_name = "${run_id}.nf.log.txt"
            use_name     = "${name}.${aln_type}"
            bigwig_dir   = "${params.aln_bigwig_dir}.${aln_type}"
            in_bdgs      = aln.findAll {fn -> "${fn}".endsWith('.bdg') }
            in_bdg       = in_bdgs[0]
            in_bdg_sort  = "${in_bdg}.sort"
            out_bigwig   = "${bigwig_dir}/${name}.bigWig"
            chrom_sizes  = "${params.ref_chrom_sizes_path}"
        
            shell:
            '''
            mkdir -v !{bigwig_dir}

            echo -e "\\nCreating UCSC bigWig file tracks for: !{name} ... utilizing UCSC bedGraphToBigWig"
            
            set -v -H -o history
            LC_ALL=C sort -k1,1 -k2,2n -o !{in_bdg_sort} !{in_bdg}
            !{params.bedgraphtobigwig_call} !{in_bdg_sort} !{chrom_sizes} !{out_bigwig}
            set +v +H +o history
            rm -v !{in_bdg_sort}  # Remove intermediate

            echo "Step 4, Part A, bigWig Creation, Complete."
            '''
        }
    } else {
        final_alns.set { peak_call_alns }
    }
    // If Control Samples Provided, associate each per-group treat sample with
    //   its corresponding control sample.
    if( use_ctrl_samples ) {
        peak_call_alns
                 //.view()
                 .branch {name, cond, group, mode, alns -> 
                     ctrl: cond == "ctrl"
                     treat: cond == "treat"
                 }
                 .set { cmb_aln_outs }   
    
        cmb_aln_outs.ctrl
                        .cross(cmb_aln_outs.treat) {name, cond, group, aln_set, alns -> "${group}.${aln_set}" }
                        .map {ctrl_info, treat_info ->
                              treat_name = treat_info[0]
                              treat_group = treat_info[2]
                              treat_aln_set = treat_info[3]
                              treat_alns = treat_info[4]
                              ctrl_name = ctrl_info[0]
                              ctrl_alns = ctrl_info[4]
                              [treat_name, treat_group, treat_aln_set, treat_alns, ctrl_name, ctrl_alns]
                        }
                        .into { macs_alns; seacr_alns }
    // If no control samples provided, remove "condition" and add ctrl placeholder variables
    } else {
        peak_call_alns
                 .map {name, cond, group, aln_set, alns ->
                       [name, group, aln_set, alns, null, file("${projectDir}/templates/no_ctrl.txt")]
                 }
                 .into { macs_alns; seacr_alns }
    }

    // Step 5, Part A, Utilize MACS for Peak Calling
    if( peak_callers.contains("macs") ) {
        process CnR_S5_A_Peaks_MACS {
            if( has_module(params, 'macs2') ) {
                module get_module(params, 'macs2')
            } else if( has_conda(params, 'macs2') ) {
                conda get_conda(params, 'macs2')
            }
            tag          { name }
            label        'small_mem'
            beforeScript { task_details(task) }
            cpus         1     
          
            input:
            tuple val(name), val(group), val(aln_type), path(aln), val(ctrl_name), path(ctrl_aln) from macs_alns
        
            output:
            path "${peaks_dir}/*" into macs_peak_all_outs
            tuple val(name), val(group), val(aln_type), 
                  path("${peaks_dir}/*") into macs_peak_outs
            path '.command.log' into macs_peak_log_outs
        
            // Publish Log
            publishDir "${params.out_dir}/${params.log_dir}", mode: params.publish_mode, 
                       pattern: '.command.log', saveAs: { out_log_name }
            // Publish Only Minimal Outputs
            publishDir "${params.out_dir}", mode: params.publish_mode, 
                       pattern: "${peaks_dir}/*",
                       enabled: (params.publish_files!="all")
            // Publish All Outputs
            publishDir "${params.out_dir}", mode: params.publish_mode, 
                       pattern: "${peaks_dir}/*",
                       enabled: (params.publish_files=="all") 
            
            script:
            run_id        = "${task.tag}.${task.process}.${aln_type}"
            out_log_name  = "${run_id}.nf.log.txt"
            use_name      = "${name}.${aln_type}"
            peaks_dir     = "${params.peaks_dir_macs}.${aln_type}"
            treat_bams    = aln.findAll {fn -> "${fn}".endsWith('_byname.bam') }
            treat_bam     = treat_bams[0]
            if( ctrl_name ) {
                ctrl_bams = ctrl_aln.findAll {fn -> "${fn}".endsWith('_byname.bam') }
                ctrl_flag = "--control ${ctrl_bams[0]}"
            } else {
                ctrl_flag = ""
            }
            macs_qval     = "${params.macs_qval}"
            genome_size   = "${params.ref_eff_genome_size}"
            macs_flags    = "${params.macs_flags}"
            keep_dup_flag = aln_type.contains('_dedup') ? "" : "--keep-dup all " 
            //add_threads = (task.cpus ? (task.cpus - 1) : 0) 
        
            shell:
            '''
            mkdir -v !{peaks_dir}

            echo "Calling Peaks for base name: !{name} ... utilizing macs2 callpeak"
             
            set -v -H -o history
            !{params.macs2_call} callpeak \\
                -f BAMPE \\
                --treatment !{treat_bam} \\
                !{ctrl_flag} \\
                --gsize  !{genome_size} \\
                --name   !{use_name} \\
                --outdir !{peaks_dir} \\
                --qvalue !{macs_qval} \\
                !{macs_flags} \\
                !{keep_dup_flag}
            set +v +H +o history
    
            echo "Step 5, Part A, Call Peaks Using MACS, Complete."
            '''
        }
    }

    // Step 5, Part B, Utilize MACS for Peak Calling
    if( peak_callers.contains("seacr") ) {
        process CnR_S5_B_Peaks_SEACR {
            if( has_module(params, 'seacr') ) {
                module get_module(params, 'seacr')
            } else if( has_conda(params, 'seacr') ) {
                conda get_conda(params, 'seacr')
            }
            tag          { name }
            label        'small_mem'
            beforeScript { task_details(task) }
            cpus         1     
   
            input:
            tuple val(name), val(group), val(aln_type), path(aln), val(ctrl_name), path(ctrl_aln) from seacr_alns
        
            output:
            path "${peaks_dir}/*" into seacr_peak_all_outs
            tuple val(name), val(group), val(aln_type), 
                  path("${peaks_dir}/*.bed") into seacr_peak_outs
            path '.command.log' into seacr_peak_log_outs
        
            // Publish Log
            publishDir "${params.out_dir}/${params.log_dir}", mode: params.publish_mode, 
                       pattern: '.command.log', saveAs: { out_log_name }
            // Publish All Outputs
            publishDir "${params.out_dir}", mode: params.publish_mode, 
                       pattern: "${peaks_dir}/*"
                       //enabled: (params.publish_files=="all") 
        
            
            script:
            run_id        = "${task.tag}.${task.process}.${aln_type}"
            out_log_name  = "${run_id}.nf.log.txt"
            peaks_dir     = "${params.peaks_dir_seacr}.${aln_type}"
            all_treat_bdg = aln.findAll {fn -> "${fn}".endsWith(".bdg") }
            treat_bdg     = all_treat_bdg[0]
            if( ctrl_name ) {
                all_ctrl_bdg = ctrl_aln.findAll {fn -> "${fn}".endsWith(".bdg") } 
                ctrl_flag = all_ctrl_bdg[0]
            } else {
                ctrl_flag = params.seacr_fdr_threshhold 
            }
            if( params.seacr_call_stringent && params.seacr_call_relaxed ) {
                do_relaxed   = "Enabled"
                do_stringent = "Enabled"
            } else if( params.seacr_call_relaxed ) {
                do_relaxed   = "Enabled"
                do_stringent = ""
            } else if( params.seacr_call_stringent ) {
                do_relaxed   = ""
                do_stringent = "Enabled"
            } else {
                throw new Exception("Need either stringent or relaxed modes enabled.")
            }
            if( params.seacr_norm_mode == 'auto' ) { 
                norm_mode = params.do_norm_spike ? 'non' : 'norm'
            } else {
                norm_mode = "${params.seacr_norm_mode}"
            }
            shell:
            '''
            mkdir -v !{peaks_dir}
           
            echo "Calling Peaks for base name: !{name} ... utilizing SEACR"
            set -v -H -o history
            if [ -n "!{do_relaxed}" ]; then

                echo 'Calling Peaks using "relaxed" mode.'
                !{params.seacr_call} !{treat_bdg} \\
                                     !{ctrl_flag} \\
                                     !{norm_mode} \\
                                     relaxed \\
                                     !{peaks_dir}/!{name}.!{aln_type}.peaks.seacr \\
                                     !{params.seacr_R_script} 
            fi

            if [ -n "!{do_stringent}" ]; then
                echo 'Calling Peaks using "stringent" mode.'
                !{params.seacr_call} !{treat_bdg} \\
                                     !{ctrl_flag} \\
                                     !{norm_mode} \\
                                     stringent \\
                                     !{peaks_dir}/!{name}.!{aln_type}.peaks.seacr \\
                                     !{params.seacr_R_script} 

            fi
            set +v +H +o history
    
            echo "Step 5, Part B, Call Peaks Using SEACR, Complete."
            '''
        }
    }
}

// --------------- Groovy Helper Functions ---------------
def return_as_list(item) {
    if( item instanceof List ) {
        item
    } else {
        [item]
    }
}

def get_ref_details (params, ref_type ) {
    def ref_key = ""
    if( params.ref_mode == 'name' ) {
        check_type = "${ref_type}_name".toString()
        if( !params.containsKey(check_type) ) {
            log.error "Using --ref_mode=name"
            log.error "Parameter --${ref_type}_name (params.${ref_type}_name) required for this mode."
            log.error ""
            exit 1
        }
        ref_key = params["${ref_type}_name"]
    } else if( params.ref_mode == 'fasta' ) {
        check_type = "${ref_type}_fasta".toString()
        if( !params.containsKey(check_type) ) {
            log.error "Using --ref_mode=fasta"
            log.error "Parameter --${ref_type}_fasta (params.${ref_type}_fasta) required for this mode."
            log.error ""
            exit 1
        }
        use_name = file( params["${ref_type}_fasta"]).getName()
        if( use_name.endsWith('.gz') ) {
            use_name = file(use_name).getBaseName()
        }
        use_name = file(use_name).getBaseName()
        ref_key = use_name
    }
    def ref_info = [:]
    if( ref_key ) { 
        ref_info_file = search_refs(params, ref_key)[ref_key]
        ref_info_file_location = file(ref_info_file).getParent()
        file(ref_info_file).readLines().each {line ->
            split_line = line.trim().split(',')
            if( split_line.size() != 2 ) {
                log.error "Formating Error for Database Line:"
                log.error "'${line}'\n"
                exit 1
            }
            (item_key, item_val) = split_line
            use_val = item_val
            if(item_key.endsWith('path') && !(item_val.startsWith('/')) ) {
                use_val = "${ref_info_file_location}/${item_val}"
            }
            ref_info[(item_key)] = use_val
        }        
    }
    ref_info
}

def get_resource_item(params, item_name, use_suffix, join_char, def_val="") {
    def ret_val = ""
    if( item_name instanceof List 
        && item_name.every {use_item -> params.containsKey(use_item + use_suffix) } ) {
        use_items = []
        item_name.each {use_item -> use_items.add(params[use_item + use_suffix])}
        ret_val = use_items.join(join_char)
    } else if( params.containsKey(item_name.toString() + use_suffix) ) { 
        ret_val = params[item_name + use_suffix]
    } else if( params.containsKey('all' + use_suffix) ) {
        ret_val = params['all' + use_suffix]
    } else {
        ret_val = def_val
    }
    ret_val
}
def get_module(params, name, def_val="") {
    get_resource_item(params, name, '_module', ':', def_val) 
}

def get_conda(params, name, def_val="") {
    get_resource_item(params, name, '_conda',  ' ', def_val)
}

def get_resources(params, name, def_val="") {
    def use_module = get_module(params, name, def_val) 
    def use_conda  = get_conda(params, name, def_val)
    if( use_module && use_conda ) {
        message =  "Both a '[item]_module' and a '[item]_conda' resource parameter provided "
        message += "for dependency/dependencies: ${name}\n"
        message += "    Module: ${use_module}\n"
        message += "    Conda:  ${use_conda}\n"
        message += "Please provide only one of these parameters.\n"  
        log.error message
        exit 1
    }
    [use_module, use_conda]
}

def has_module(params, name, def_val="") {
    def use_module = get_resource_item(params, name, '_module', ':', def_val) 
    use_module != def_val
}

def has_conda(params, name, def_val="") {
    def use_conda = get_resource_item(params, name, '_conda',  ' ', def_val)
    use_conda != def_val
}

// Return Boolean true if resources exist for name(s).
def has_resources(params, name) {
    def resources = get_resources(params, name, def_val="")
    ( resources[0].toBoolean() || resources[1].toBoolean() )
}   

def test_params_key(params, key, allowed_opts=null) {
    if( !params.containsKey(key) ) {
        log.error "Required parameter key not provided:"
        log.error "    ${key}"
        log.error ""
        exit 1
    }
    if( allowed_opts == "nonblank" ) { 
        if( params[(key)] == null || params[(key)] == "" ) {
            log.error "Value of key cannot be blank:"
            log.error "    ${key}"
            log.error ""
            exit 1
        }
    } else if( allowed_opts ) { 
        def value = params[key]
        def value_list = []
        if( value instanceof List) {
            value_list = value
        } else {
            value_list = [value]
        }
        value_list.each {
            if( !(allowed_opts.contains(it)) ) {
                log.error "Parameter: '${key}' does not contain an allowed option:"
                log.error "  Provided: ${it}"
                log.error "  Allowed:  ${allowed_opts}"
                log.error ""
                exit 1
            }
        }
    }
}             

def test_params_keys(params, test_keys) {
    test_keys.each{keyopts -> test_params_key(params, *keyopts) }
}

def test_params_file(params, in_test_file) {
    def test_file = in_test_file[0]
    if( !params.containsKey(test_file) ) {
        log.error "Required file parameter key not provided:"
        log.error "    ${test_file}"
        log.error ""
        exit 1
    }
    def this_file = file(params[test_file], checkIfExists: false)
    if( this_file instanceof List ) { this_file = this_file[0] }
    if( !this_file.exists() ) {
        log.error "Required file parameter '${test_file}' does not exist:"
        log.error check_full_file_path("${this_file}")
        exit 1
    }
} 

def test_params_files(params, test_files) {
    test_files.each{file_key -> test_params_file(params, file_key) }
}

def check_full_file_path(file_name) {
    out_message = "    ${file_name}\n"
    build_subpath = ""
    use_string = file_name - ~/^\// - ~/\/$/
    use_string.split('/').each { seg ->
        build_subpath += "/" + seg
        if( file(build_subpath, checkIfExists: false).exists() ) {
            out_message += "    Exists:         " + build_subpath + "\n"
        } else {
            out_message += "    Does not Exist: " + build_subpath + "\n"
        }
    }
    return out_message
}

def print_command ( command ) {
    log.info ""
    log.info "Nextflow Command:"
    log.info "    ${command}"    

    // If command is extensive, print individual parameter details..
    command_list = "${command}".split()
    if( command_list.size() > 5 ) {
        log.info ""
        log.info "Nextflow Command Details:"
        message = "    " + command_list[0]
        last_command = null
        [command_list].flatten().subList(1, command_list.size()).each {
            if( it == "run" ) {
                if( last_command != "--mode" ) { log.info message ; message = "   "}
                message += " run"
            } else if( it.startsWith('-') || it.startsWith('--') ) {
                log.info message
                message = "    $it"
            } else {
                message += " $it"
            }
            last_command = it 
        }
        log.info message
    }
}

def print_workflow_details(
        workflow = workflow,
        params = params, 
        front_pad = 4, 
        prop_pad = 17
    ) {

    if( params.verbose ) {
        log.info "-- Project Description:"
        log.info "${workflow.manifest.name} : ${workflow.manifest.version}"
        log.info "${workflow.manifest.description}"
    }

    print_config_files = "${workflow.configFiles[0]}"
    workflow.configFiles.subList(1, workflow.configFiles.size()).each {
      print_config_files = print_config_files.concat("\n".padRight(prop_pad) + it)
    }

    print_properties = [
        'NF Config Prof.': workflow.profile,
        'NF Script': workflow.scriptFile,
        'NF Launch Dir': workflow.launchDir,
        'NF Work Dir': workflow.workDir,
        'User': workflow.userName,
        'User Home Dir': workflow.homeDir,
        'Out Dir': params.out_dir,
        'Publish Files': params.publish_files,
        'Publish Mode': params.publish_mode,
        'Start Time': workflow.start,
    ]
    first_config = '-'.multiply(front_pad) 
    first_config += 'NF Config Files'.padRight(prop_pad) 
    first_config += "${workflow.configFiles[0]}"
    log.info first_config
    workflow.configFiles.subList(1, workflow.configFiles.size()).each {
      log.info '-'.multiply(front_pad) + ' '.multiply(prop_pad) + it
    }

    print_properties.each{key, value -> 
        log.info '-'.multiply(front_pad) + key.padRight(prop_pad) + value
    }
} 

def task_details(task, run_id='') {
    def resource_string = ""
    if( task.module ) { 
        resource_string = "Module(s): '${task.module.join(':')}'"
    } else if( task.conda ) {
        resource_string = "Conda-env: '${task.conda.toString()}'"
    } else {
        resource_string = 'Resources: None'
    }
    def time_str  = ( "${task.time}" == "null" ? "" : "${task.time}" )
    def mem_str   = ( "${task.memory}" == "null" ? "" : "${task.memory}" )
    def queue_str = ( "${task.queue}" == "null" ? "" : "${task.queue}" )
    def ret_string = """
    echo    "  ${task.name}.${task.tag}"
    echo    "  -  Executor:  ${task.executor}"
    echo    "  -  CPUs:      ${task.cpus}"
    echo    "  -  Time:      ${time_str}"
    echo    "  -  Mem:       ${mem_str}"
    echo    "  -  Queue:     ${queue_str}"
    echo -e "  -  ${resource_string}\\n"
    """.stripIndent()
    ret_string
}

def sanitize_mem(mem_num, mem_size, return_as='MB', as_string=false) {
    factors = [
        'B' : (long) 1,             // B  Bytes
        'KB': (long) 1000,          // KB Kilobytes
        'MB': (long) 1000000,       // MB Megabytes
        'GB': (long) 1000000000,    // GB Gigabytes
        'TB': (long) 1000000000000, // TB Terabytes
    ]
    def mem_bytes       = (long) 0
    if( mem_num.isFloat() ) {
        def mem_bytes_float = Float.valueOf(mem_num) * factors[mem_size]
        mem_bytes = mem_bytes_float.toLong()
    } else {
        mem_bytes = Long.valueOf(mem_num) * ( factors[mem_size] )
    }
    if( !return_as ) { return_as = mem_size }
    if( factors[return_as] > mem_bytes ) {
        message =  "Value: ${mem_bytes} cannot be int-divided "
        message += "by factor: ${factors[return_as]}"
        throw new Exception(message)
    }
    def mem_num_return = mem_bytes.intdiv(factors[return_as])
    if( as_string ) { 
        return ["${mem_num_return}", return_as]
    }
    [mem_num_return, return_as]
}

def sanitize_mem_str(mem, return_as='MB', as_string=false) {
    // Assumes memory has already been processed by "memory:" directive
    def mem_split = mem.split()
    def ret_pair  = sanitize_mem(mem_split[0], mem_split[1], return_as, as_string)
    if(as_string) {
        return "${ret_pair[0]} ${ret_pair[1]}"
    }
    ret_pair
}

def trim_task_mem(task, trim_num=9, trim_div=10, return_as="MB", as_string=false) {
    def mem_num  = (long) 0
    def mem_type = ""
    (mem_num, mem_type) = sanitize_mem_str("${task.memory}", 'B')
    def adj_bytes = (mem_num * trim_num).intdiv(trim_div)
    def ret_pair = sanitize_mem("${adj_bytes}", 'B', return_as, as_string)
    if( as_string ) {
        return "${ret_pair[0]} ${ret_pair[1]}"
    }
    ret_pair
}

def split_task_mem(task, return_as="MB", as_string=false) {
    def mem_num  = (long) 0
    def mem_type = ""
    (mem_num, mem_type) = sanitize_mem_str("${task.memory}", 'B')
    def adj_bytes = mem_num.intdiv(Long.valueOf("${task.cpus}"))
    def ret_pair = sanitize_mem("${adj_bytes}", 'B', return_as, as_string)
    if( as_string ) {
        return "${ret_pair[0]} ${ret_pair[1]}"
    }
    ret_pair
}

def trim_split_task_mem(task, trim_num=9, trim_div=10, return_as="MB", as_string=false) {
    def mem_num  = (long) 0
    def mem_type = ""
    (mem_num, mem_type) = sanitize_mem_str("${task.memory}", 'B')
    def divisor = (Long.valueOf("${task.cpus}") * trim_div)
    def adj_bytes = (mem_num * trim_num).intdiv(divisor)
    def ret_pair = sanitize_mem("${adj_bytes}", 'B', return_as, as_string)
    if( as_string ) {
        return "${ret_pair[0]} ${ret_pair[1]}"
    }
    ret_pair
}

sleep(1500)
