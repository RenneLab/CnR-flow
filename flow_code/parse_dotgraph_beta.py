#!/usr/bin/env python3
#Daniel Stribling
#Renne Lab, University of Florida
#Changelog:
#   2020-08-15, Initial (Beta) Version
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

#Usage: parse_dotgraph_beta.py in_graph.dot nextflow.config custom.dot

"""
This script manipulates a ".dot" file produced by the CnR-flow pipeline.
This entails trimming non-informative connection steps from the graph,
and pruning of unusued channel outputs.

Note: This code is in *BETA*, use/read at "your own risk". :)
"""

import sys
import os
import subprocess
from natsort import natsorted

out_dot_name = 'parsed_dotgraph.dot'

remove_node_labels = ['map', 'groupTuple', 'unique', 'branch', 'cross', 'mix',
                      'concat', 'first', 'Channel.fromList',
                       'Channel.empty', 'Channel.fromFilePairs', ]
remove_graph_labels = []
remove_graph_target_labels = ['_log_outs', '_all_outs', 'aln_spike_csv_outs']

change_label_shapes = {
    'CnR_S2_A_Aln_Ref': 'box',
    'CnR_S2_B_Modify_Aln': 'box',
    'CnR_S2_C_Make_Bdg': 'box',
}

aln_mode_channels = {'all': 'sort_aln_outs_all',
                     'all_dedup': 'sort_aln_outs_all_dedup',
                     'less_120': 'sort_aln_outs_120',
                     'less_120_dedup': 'sort_aln_outs_120_dedup',
                    }

origin_shape = 'invtriangle'
terminus_shape = 'octagon'
terminus_label = 'output'

custom_nodes = {}
graph_groups = []

def read_nextflow_config(config_path):
    with open(config_path, 'r') as nextflow_config:
        add_remove_node_labels = []
        add_remove_graph_labels = []
        add_remove_graph_target_labels = []
        add_change_label_shapes = {}

        for line in nextflow_config:
            if line.strip().startswith('//'):
                continue
            elif 'use_aln_modes' in line and '=' in line:
                val_str = line.split('=')[1].strip()
                val_str = val_str.split('//')[0]
                raw_vals = val_str.strip('[ ]').split(',')
                aln_modes = [val.strip().strip('"').strip("'") for val in raw_vals]
                remove_modes = [v for k,v in aln_mode_channels.items()
                                if k not in aln_modes]
                add_remove_graph_target_labels += remove_modes

    ret_tuple = (add_remove_node_labels, add_remove_graph_labels, 
                 add_remove_graph_target_labels, add_change_label_shapes)
    return ret_tuple

def add_replace_tag(line, tag, value):
    tag_str = tag + '='
    new_tag_str = tag_str + value
    if tag in line:
        old_shape = line.split('shape=')[1].split(',')[0].rstrip().rstrip(';]')
        ret_line = line.replace('shape=' + old_shape, new_tag_str)
    elif '[' in line:
        ret_line = line.replace('[', '[%s,'% new_tag_str)
    else:
        ret_line = line.replace(';', '[%s];'% new_tag_str)
    return ret_line

if len(sys.argv) > 2 and os.path.exists(sys.argv[2]):
    ret_vals = read_nextflow_config(sys.argv[2]) 
    remove_node_labels += ret_vals[0]
    remove_graph_labels += ret_vals[1]
    remove_graph_target_labels += ret_vals[2]
    change_label_shapes.update(ret_vals[3])

add_lines = [
    'p01a [label="treat_fastqs"];\n',
    'p01b [label="ctrl_fastqs"];\n',
    'p01a -> p01c\n',
    'p01b -> p01c\n',
    'p01c [shape=circle,label="",fixedsize=true,width=0.1,xlabel="concat"];\n',
    'p01c -> p2\n' 
]
if len(sys.argv) > 3 and os.path.exists(sys.argv[3]):
    with open(sys.argv[3], 'r') as add_dot:
        add_lines += add_dot.readlines()    

with open(sys.argv[1], 'r') as dot_file:
    header = next(dot_file)
    group_lines = []
    for line in dot_file:
        if line.strip() == '}':
            footer = line
            break
        if line.strip():
            group_lines.append(line)
        else:
            graph_groups.append(group_lines)
            group_lines = []
    
out_base = 'test_out_dot'
out_dot = out_base + '.dot'

origins = set()
termini = set()
conn_forward = {}
conn_backward = {}
remove_nodes = set()
remove_graphs = set()
bridges = []
bridge_tuples = set()

# Detect all nodes and graphs to be removed
for group in graph_groups:
    for group_line in group:
        line_split = group_line.split()
        source = line_split[0].strip()
        if '->' in group_line:
            target = line_split[2].rstrip().rstrip('; ')
            # If source node has not been previously identified as a source
            if source not in conn_forward:
                conn_forward[source] = []
            # If target not previously identified as a target
            if target not in conn_backward:
                conn_backward[target] = []
            conn_forward[source].append(target)
            conn_backward[target].append(source)
        
            if any((label in group_line for label in remove_graph_labels)):
                remove_graphs.add((source, target))
            if any((label in group_line for label in remove_graph_target_labels)):
                remove_graphs.add((source, target))
                remove_nodes.add(target)
        else:
            if any((label in group_line for label in remove_node_labels)):
                remove_nodes.add(source)

for line in add_lines:
    line_split = line.split()
    if '->' in line:
        source, target = line_split[0], line_split[2].rstrip().rstrip('; ')
        # If source node has not been previously identified as a source
        if source not in conn_forward:
            conn_forward[source] = []
        # If target not previously identified as a target
        if target not in conn_backward:
            conn_backward[target] = []
        conn_forward[source].append(target)
        conn_backward[target].append(source)

# Create bridges, where applicable, for any nodes to be removed
for node in natsorted(remove_nodes):
    if node in conn_backward:
        all_sources = conn_backward[node][:]
    else:
        all_sources = []
    if node in conn_forward:
        all_targets = conn_forward[node][:] 
    else:
        all_targets = []

    found_bridge = False
    new_bridges = []
    for bridge in bridges:
        if bridge[1] != node:
            new_bridges.append(bridge)
        else:
            found_bridge = True
            for target in all_targets:
                new_bridges.append([bridge[0], target])

    if not found_bridge:
        for source in all_sources:
            if source in remove_nodes:
                continue
            for target in all_targets:
                new_bridges.append([source, target])

    bridges = new_bridges

for bridge in bridges:
    bridge_tuples.add((bridge[0], bridge[1]))

# Cull original dotgraph to only nodes and graphs to be retained.


use_lines = []
final_sources = set()
final_targets = set()
for line in add_lines:
    line_split = line.split() 
    if '->' in line:
        source, target = line_split[0], line_split[2].rstrip().rstrip('; ')
        if target in remove_nodes:
            continue
        final_sources.add(source)
        final_targets.add(target)
    use_lines.append(line)

for graph_group in graph_groups:
    source_node = graph_group[0].split()[0]
    target_node = graph_group[1].split()[0]
    graph = (graph_group[2].split()[0], graph_group[2].split()[2])
    use_graph_group = graph_group[:]
    add_target = True
    #Process final source
    if source_node in remove_nodes:
        use_graph_group[0] = ''
        use_graph_group[2] = ''
        add_target = False
    #If source is not the target of anything, it is a final origin.
    else:
        final_sources.add(source_node)
    #Process final target
    if target_node in remove_nodes:
        use_graph_group[1] = ''
        use_graph_group[2] = ''
    elif add_target:
        final_targets.add(target_node)
        
    if graph in remove_graphs:
        use_graph_group[2] = ''
    
    add_lines = [l for l in use_graph_group if (l.strip())]
    if add_lines:
        add_lines += ['\n']
    use_lines += add_lines

for bridge in bridge_tuples:
    source, target = bridge
    use_lines.append("%s -> %s;\n" % (source, target))
    final_sources.add(source)
    final_targets.add(target)

final_origins = final_sources - final_targets
final_termini = final_targets - final_sources

new_use_lines = []
final_nodes = set()
for line in natsorted(use_lines):
    use_line = line
    if not line.strip():
        continue
    elif '->' in line:
        pass
    else:
        node = line.split()[0]
        if node in final_nodes:
            continue
        final_nodes.add(node)
        if node in final_termini:
            if terminus_shape:
                use_line = add_replace_tag(use_line, 'shape', terminus_shape)
            if terminus_label:
                use_line = add_replace_tag(use_line, 'label', terminus_label)
        if node in final_origins and origin_shape:
            use_line = add_replace_tag(use_line, 'shape', origin_shape)

        #Check for custom shape labels:
        for label in change_label_shapes.keys():
            if label in use_line:
                new_shape = change_label_shapes[label]
                use_line = add_replace_tag(use_line, 'shape', new_shape)
                break

    new_use_lines.append(use_line)
use_lines = new_use_lines
       
# Modify dotgraph, add bridges, and write output.
with open(out_dot_name, 'w') as out_dot_file:
    out_dot_file.write(header)
    out_dot_file.writelines(use_lines)
    out_dot_file.write(footer + '\n')

command = ['dot', '-Tpng', '-O', out_dot_name]
subprocess.call(command)

#for bridge_tuple in bridge_tuples:
#    print(' ', bridge_tuple)
#print(final_origins)
#print(final_termini)

print('Done.\n')

