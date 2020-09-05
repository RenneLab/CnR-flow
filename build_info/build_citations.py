#!/usr/bin/env python3

import os
import sys
import glob

main_cite_path = os.path.join('..', 'Citations.txt')
main_bib_path = main_cite_path.replace('.txt', '.bib')  
rst_cite_path = os.path.join('..', 'docs', 'source', 'citations.rst')
rst_vars_path = os.path.join('..', 'docs', 'proj_rst_vars.rst')
rst_vars_py_path = os.path.join('..', 'docs', 'proj_rst_vars.py')
extra_rst_path = os.path.join('extra_rst.rst')

all_citations = []
rst_indent = 0

for cite in sorted(glob.glob('*cite*cite*txt')):
    all_citations.append(cite.strip().replace(".txt", ""))

used_citations = {}
rst_epilog = ""
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
            main_cite.write(citation_name + ':\n')

            # Iterate through normal citation lines:
            first_line = next(cite_txt)
            main_cite.write(first_line)
            header_prefix = '.. [%s_Citation] ' % citation_name
            header_size = len(header_prefix)
            rst_cite.write((' '*rst_indent) + header_prefix + first_line)

            for line in cite_txt:
                main_cite.write(line)
                rst_cite.write((' '*(rst_indent + header_prefix)) + line)
            
            main_cite.write('\n')
            rst_cite.write('\n')    

        citation_url_path = citation.replace('_cite', '_url_') + '.txt'
        with open(citation_url_path, 'r') as citation_url:
            url_string = ".. _%s: " % citation_name
            url_string += citation_url.read().strip() + '\n'
            rst_epilog += url_string

with open(extra_rst_path, 'r') as extra_rst_obj:
    rst_epilog += ''.join(extra_rst_obj.readlines())

with open(rst_vars_path, 'w') as rst_vars, \
     open(rst_vars_py_path, 'w') as rst_vars_py:
    rst_vars.write(rst_epilog)
    rst_vars_py.write(
'''\
rst_epilog = """
%s
"""
''' % rst_epilog.rstrip()
    )

print('Done.\n')
