#!/usr/bin/env bash
#Daniel Stribling
#Renne Lab, University of Florida
#Changelog:
#   2020-08-28, Initial (Beta) Version
#
#This file is part of CnR-Flow.
#CnR-Flow is free software: you can redistribute it and/or modify
#it under the terms of the GNU General Public License as published by
#the Free Software Foundation, either version 3 of the License, or
#(at your option) any later version.
#CnR-Flow is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.
#You should have received a copy of the GNU General Public License
#along with CnR-Flow.  If not, see <https://www.gnu.org/licenses/>.


../flow_code/ensure_commented.py config_3A_params_task_inputs.txt config_5B_suffix_pipe_inputs_auto.txt "//" "    " 

PIPE_FILES=$(find *shared* *pipe* | sort)
TASK_FILES=$(find *shared* *task* | sort)

cat ${PIPE_FILES} > ../nextflow.config
cat ${TASK_FILES} > ../nextflow.config.task_default

cp -v ../nextflow.config              ../templates/nextflow.config.backup
cp -v ../nextflow.config.task_default ../templates/nextflow.config.task_default.backup
