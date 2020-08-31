#!/usr/bin/env python3
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

"""
This script reads a file and ensures that every non-blank line begins 
with a specified string after a specified indent.
"""

import sys
import os

def ensure_commented(in_file_path, out_file_path, comment_str, indent_str):
    with open(in_file_path, 'r') as in_file, \
         open(out_file_path, 'w') as out_file:
        for line in in_file:
            use_line = line
            if use_line.strip() and not use_line.lstrip().startswith(comment_str):
                use_line = indent_str + comment_str + line.lstrip()
            out_file.write(use_line)

if not len(sys.argv) == 5:
    print('\nUsage:')
    print('ensure_commented.py <in_file> <out_file> <comment_str> <indent_str>\n')
    sys.exit(1)

ensure_commented(*sys.argv[1:])





