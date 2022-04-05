#!/usr/bin/env bash
#Daniel Stribling
#Renne Lab, University of Florida
#Changelog:
#   2020-08-28, Initial (Beta) Version
#
#This file is part of CnR-flow.
#CnR-flow is free software: you can redistribute it and/or modify
#it under the terms of the GNU General Public License as published by
#the Free Software Foundation, either version 3 of the License, or
#(at your option) any later version.
#CnR-flow is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.
#You should have received a copy of the GNU General Public License
#along with CnR-flow.  If not, see <https://www.gnu.org/licenses/>.


../flow_code/ensure_commented.py config_3A_params_task_inputs.txt config_5B_suffix_pipe_inputs_auto.txt "//" "    " 

PIPE_FILES=$(find *shared* *pipe* | sort)
TASK_FILES=$(find *shared* *task* | sort)

cat ${PIPE_FILES} > ../nextflow.config
cat ${TASK_FILES} > ../nextflow.config.task
grep -vh "^\s*//\s" config_2A_process_shared.txt config_3A_params_task_inputs.txt \
    config_3B_params_shared_stepsettings.txt config_3Z_params_shared_close.txt \
    | grep -v "^\s*$" > ../nextflow.config.task.nodoc
grep -vh "^\s*//\s" config_2A_process_shared.txt config_3A_params_task_inputs.txt \
    config_3Z_params_shared_close.txt \
    | grep -v "^\s*$" > ../nextflow.config.task.nodoc.minimal

cp -v ../nextflow.config      ../templates/nextflow.config.backup
cp -v ../nextflow.config.task ../templates/nextflow.config.task.backup
cp -v ../nextflow.config.task.nodoc \
    ../templates/nextflow.config.task.nodoc.backup
cp -v ../nextflow.config.task.nodoc.minimal \
    ../templates/nextflow.config.task.nodoc.minimal.backup


# Create File Snippets
rm -v config_zz_auto*
egrep -A 2 "trimmomatic_adapter_mode" config_3B_params_shared_stepsettings.txt \
     | sed 's/^[[:space:]]*//' \
     | sed 's/trimmomatic_settings[[:space:]]*=/trimmomatic_settings =/' \
     | sed 's/=[[:space:]]*"/= "/' > config_zz_auto_trimmomatic_settings.txt 

egrep "trimmomatic_flags.*=" config_3B_params_shared_stepsettings.txt \
     | sed 's/^[[:space:]]*//' \
     | sed 's/trimmomatic_flags[[:space:]]*=/trimmomatic_flags =/' \
     | sed 's/=[[:space:]]*"/= "/' > config_zz_auto_trimmomatic_flags.txt 

egrep "aln_ref_flags.*=" config_3B_params_shared_stepsettings.txt \
     | sed 's/^[[:space:]]*//' \
     | sed 's/aln_ref_flags[[:space:]]*=/aln_ref_flags =/' \
     | sed 's/=[[:space:]]*"/= "/' > config_zz_auto_aln_ref_flags.txt 
egrep "use_aln_modes.*=" config_3B_params_shared_stepsettings.txt \
     | sed 's/^[[:space:]]*//' \
     | sed 's/use_aln_modes[[:space:]]*=/use_aln_modes =/' \
     | sed 's/=[[:space:]]*"/= "/' > config_zz_auto_use_aln_modes.txt 
egrep "aln_norm_flags.*=" config_3B_params_shared_stepsettings.txt \
     | sed 's/^[[:space:]]*//' \
     | sed 's/aln_norm_flags[[:space:]]*=/aln_norm_flags =/' \
     | sed 's/=[[:space:]]*"/= "/' > config_zz_auto_aln_norm_flags.txt 
egrep "norm_mode.*=" config_3B_params_shared_stepsettings.txt \
     | sed 's/^[[:space:]]*//' \
     | sed 's/norm_mode[[:space:]]*=/norm_mode =/' \
     | sed 's/=[[:space:]]*"/= "/' > config_zz_auto_norm_mode.txt 
egrep "norm_mode.*=" config_3B_params_shared_stepsettings.txt \
     | sed 's/^[[:space:]]*//' \
     | sed 's/norm_mode[[:space:]]*=/norm_mode =/' \
     | sed 's/=[[:space:]]*"/= "/' > config_zz_auto_norm_mode.txt 
egrep "norm_scale.*=" config_3B_params_shared_stepsettings.txt \
     | sed 's/^[[:space:]]*//' \
     | sed 's/norm_scale[[:space:]]*=/norm_scale =/' \
     | sed 's/=[[:space:]]*"/= "/' > config_zz_auto_norm_scale.txt 
egrep "norm_cpm_scale.*=" config_3B_params_shared_stepsettings.txt \
     | sed 's/^[[:space:]]*//' \
     | sed 's/norm_scale[[:space:]]*=/norm_cpm_scale =/' \
     | sed 's/=[[:space:]]*"/= "/' > config_zz_auto_norm_cpm_scale.txt 
egrep "peak_callers.*=" config_3B_params_shared_stepsettings.txt \
     | sed 's/^[[:space:]]*//' \
     | sed 's/peak_callers[[:space:]]*=/peak_callers =/' \
     | sed 's/=[[:space:]]*"/= "/' > config_zz_auto_peak_callers.txt 
egrep -A 2 "// Macs2 Settings" config_3B_params_shared_stepsettings.txt \
     | sed 's/^[[:space:]]*//' \
     | sed 's/[[:space:]]*=/=/' \
     | sed 's/=[[:space:]]*/=/' \
     | sed 's/=/ = /' > config_zz_auto_macs_settings.txt 
egrep -A 4 "// SEACR Settings" config_3B_params_shared_stepsettings.txt \
     | sed 's/^[[:space:]]*//' \
     | sed 's/[[:space:]]*=/=/' \
     | sed 's/=[[:space:]]*/=/' \
     | sed 's/=/ = /' > config_zz_auto_seacr_settings.txt 
egrep -A 11 "Using Anaconda" config_3A_params_pipe_dependencies.txt \
     | sed 's/^[[:space:]]*//' > config_zz_auto_conda_config.txt
egrep -A 11 "// Dependency Configuration Using Environment Modules" config_3A_params_pipe_dependencies.txt \
     | sed 's/^[[:space:]]*//' > config_zz_auto_module_config.txt
egrep -A 17 "with Singularity" config_3A_params_pipe_dependencies.txt \
     | sed 's/^[[:space:]]*//' > config_zz_auto_singularity_config.txt
egrep -A 20 "with Docker" config_3A_params_pipe_dependencies.txt \
     | sed 's/^[[:space:]]*//' > config_zz_auto_docker_config.txt
egrep -A 20 "// System Call Settings" config_3A_params_pipe_dependencies.txt \
     | sed 's/^[[:space:]]*//' > config_zz_auto_call_config.txt
echo "params {" > config_zz_auto_params_header.txt
echo "}" > config_zz_auto_params_footer.txt
egrep -A 7 "// CnR-flow Input Files:" config_3A_params_task_inputs.txt \
     | sed 's/^[[:space:]]*//' > config_zz_auto_inputs_single_prep.txt
egrep -A 16 "// Can specify multiple treat/control" config_3A_params_task_inputs.txt \
     | sed 's/^[[:space:]]*//' > config_zz_auto_inputs_group_prep.txt
egrep -A 13 "// ------- General Pipeline" config_3B_params_shared_stepsettings.txt \
    > config_zz_auto_naming_prep.txt
cat config_zz_auto_params_header.txt config_zz_auto_inputs_single_prep.txt config_zz_auto_params_footer.txt \
    > config_zz_auto_inputs_single.txt
cat config_zz_auto_params_header.txt config_zz_auto_inputs_group_prep.txt config_zz_auto_params_footer.txt \
    > config_zz_auto_inputs_group.txt
cat config_zz_auto_params_header.txt config_zz_auto_naming_prep.txt config_zz_auto_params_footer.txt \
    > config_zz_auto_naming.txt

rm config_zz_auto_inputs_group_prep.txt config_zz_auto_inputs_single_prep.txt \
   config_zz_auto_naming_prep.txt

