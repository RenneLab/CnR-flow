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

// https://www.ncbi.nlm.nih.gov/Traces/study/?acc=GSE104550&o=acc_s%3Aa

nextflow.enable.dsl=2
sras      = ['SRX3241465', 'SRX3241462']
file_glob = "raw_data/*_{1,2}.fastq.gz"


workflow {
    //Channel.fromSRA(sras)
    //      .view()
    //      .set { in_fastqs }
    Channel.fromFilePairs(file_glob)
          .view()
          .set { in_fastqs }
    Subsample_Fastq(in_fastqs)
}

process Subsample_Fastq {
    conda         'bioconda::seqkit=0.13.2'
    tag           { sra }
    cache         false
    echo          true
    errorStrategy { sleep(Math.pow(2, task.attempt) * 200 as long); return 'retry' }
    maxRetries    10

    input:
    tuple val(sra), path(fastqs)

    output:
    path("${out_dir}/*.fastq*")
    path('.command.log')

    publishDir "${out_dir}", mode: 'copy',
               pattern: ".command.log", saveAs: { out_log }
    publishDir ".", mode: 'move', pattern: "${out_dir}/*"
    script:
    out_log  = "${task.tag}.${task.process}.nflog.txt"
    out_dir  = 'subsampled_data'
    prop     = 0.10
    prop_str = "${prop}" - ~/\./
    fq_names = ""
    fastqs.each{name -> 
        fq_names += ("${name}" - ~/.fastq.gz/ ) + " "
    }
    shell:
    '''
    echo "Subsampling Sequence name(s): !{fq_names}"
    USE_RAND="$RANDOM"
    echo "Random Seed: ${USE_RAND}"
    mkdir -v !{out_dir}

    for IN_NAME in !{fq_names}; do
        set -v -H -o history
        seqkit sample --proportion !{prop} \\
                      --rand-seed ${USE_RAND} \\
                      --threads !{task.cpus} \\
                      --two-pass \\
                      ${IN_NAME}.fastq.gz \\
                      --out-file !{out_dir}/${IN_NAME}_prop!{prop_str}.fastq.gz
        #COMMAND="$(echo !!)"
        set +v +H +o history
    done
    echo "Done."

    '''
}

sleep(3000)
