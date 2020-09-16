#!/usr/bin/env bash
#Daniel Stribling
#Renne Lab, University of Florida
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

# Source: http://hgdownload.soe.ucsc.edu/goldenPath/hg38/bigZips/latest/hg38.chromFa.tar.gz
if [ $(ls test_reference/hg38_chr22.fa 2>/dev/null | wc -l) -ge 1 ] ; then
  echo "Reference Data Exists."
  exit 0
fi
mkdir -p test_reference
cd test_reference

wget -c --progress=dot:mega --waitretry=60 --retry-connrefused http://hgdownload.soe.ucsc.edu/goldenPath/hg38/bigZips/latest/hg38.chromFa.tar.gz
tar -xvf hg38.chromFa.tar.gz ./chroms/chr22.fa
rm  hg38.chromFa.tar.gz
mv chroms/chr22.fa ./hg38_chr22.fa
rmdir chroms
echo "Done with reference downloads."
cd ../../



