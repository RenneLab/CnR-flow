#!/usr/bin/env python3

import os
import sys
import glob

main_cite_path = os.path.join('..', 'Citations.txt')
main_bib_path = main_cite_path.replace('.txt', '.bib')  
rst_cite_path = os.path.join('..', 'docs', 'source', 'citations.rst')

all_citations = []
rst_indent = 4

for cite in sorted(glob.glob('*cite*cite*txt')):
    all_citations.append(cite.strip().replace(".txt", ""))

used_citations = {}
with open(main_cite_path, 'w') as main_cite, \
     open(main_bib_path, 'w') as main_bib, \
     open(rst_cite_path, 'w') as rst_cite:
    for citation in all_citations:
        citation_name = citation.split('_')[-1]
        if citation_name in used_citations:
            continue
        else:
            used_citations[citation_name] = True
        with open(citation + '.txt', 'r') as cite_txt, \
             open(citation + '.bib', 'r') as cite_bib:

            # Copy BibTex without modification
            main_bib.writelines(cite_bib.readlines() + ['\n'])

            # Write title for main file.
            main_cite.write(citation_name + '\n')

            # Iterate through normal citation lines:
            first_line = next(cite_txt)
            main_cite.write(first_line)
            rst_cite.write((' '*rst_indent) + '#. ' + first_line)

            for line in cite_txt:
                main_cite.write(line)
                rst_cite.write((' '*(rst_indent + 3)) + line)
            
            main_cite.write('\n')
            rst_cite.write('\n')    

