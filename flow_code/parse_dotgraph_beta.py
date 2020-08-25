#!/usr/bin/env python3
#Daniel Stribling
#Renne Lab, University of Florida
#Changelog:
#   2020-08-15, Initial (Beta) Version

"""
This script manipulates a ".dot" file produced by the CnR-flow pipeline.
This entails trimming non-informative connection steps from the graph,
and pruning of unusued channel outputs.
"""

import sys
import subprocess

remove_node_names = ['map', 'groupTuple', 'unique', 'branch', 'cross']
remove_source_phrases = ['Channel.empty']
remove_target_phrases = ['_log_outs', '_all_outs']

graph_groups = []
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

conn_forward = {}
conn_backward = {}
remove_nodes = {}
bridges = []

for group in graph_groups:
    for group_line in group:
        if '->' in group_line:
            line_split = [i.strip() for i in group_line.split('->')]
            line_split[1] = line_split[1].rstrip(';').split()[0].strip()
            source, target = line_split
            if source not in conn_forward:
                conn_forward[source] = []
            if target not in conn_backward:
                conn_backward[target] = []
            conn_forward[source].append(target)
            conn_backward[target].append(source)

        if any((rn in group_line for rn in remove_node_names)):
            remove_nodes[group_line.split()[0]] = None
            pass

#testing
#remove_nodes = {'p6':None, 'p7':None, 'p12':None}

for node in sorted(remove_nodes):
    all_sources = conn_backward[node][:]
    all_targets = conn_forward[node][:]

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
            for target in all_targets:
                new_bridges.append([source, target])

    bridges = new_bridges

bridge_tuples = {}
for bridge in bridges:
    bridge_tuples[(bridge[0], bridge[1])] = None

with open('test_out_dot.dot', 'w') as out_dot_file:
    out_dot_file.write(header)
    for graph_group in graph_groups:
        source = graph_group[0].split()[0]
        target = graph_group[1].split()[0]
        use_graph_group = graph_group[:]
        if any((phrase in graph_group[0] for phrase in remove_source_phrases)):
            continue
        elif any((phrase in graph_group[-1] for phrase in remove_target_phrases)):
            continue
        if source in remove_nodes:
            use_graph_group[0] = ''
            use_graph_group[2] = ''
        if target in remove_nodes:
            use_graph_group[1] = ''
            use_graph_group[2] = ''
        out_dot_file.writelines(use_graph_group + ['\n'])

    for bridge in bridge_tuples:
        out_dot_file.write("%s -> %s;\n" % (bridge[0], bridge[1]))
        print(bridge)

    out_dot_file.write(footer + '\n')
            
command = ['dot', '-Tpng', '-O', out_dot]
subprocess.call(command)





