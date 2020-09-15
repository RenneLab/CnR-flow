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

if [ -d subsampled_data ] ; then
  echo "Input Data Exists."
  exit 0
fi

mkdir raw_data
cd raw_data

echo "Downloading SRR6128981"
#curl -# --retry-max-time 150 --retry 15 -o SRR6128981_1.fastq.gz ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR612/001/SRR6128981/SRR6128981_1.fastq.gz
wget --progress=dot:mega --waitretry=30 --retry-connrefused ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR612/001/SRR6128981/SRR6128981_1.fastq.gz

#curl -# --retry-max-time 150 --retry 15 -o SRR6128981_2.fastq.gz ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR612/001/SRR6128981/SRR6128981_2.fastq.gz
wget --progress=dot:mega --waitretry=30 --retry-connrefused ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR612/001/SRR6128981/SRR6128981_2.fastq.gz

echo "Downloading SRR6128978"
#curl -# --retry-max-time 150 --retry 15 -o SRR6128978_1.fastq.gz ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR612/008/SRR6128978/SRR6128978_1.fastq.gz
wget --progress=dot:mega --waitretry=30 --retry-connrefused ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR612/008/SRR6128978/SRR6128978_1.fastq.gz

#curl -# --retry-max-time 150 --retry 15 -o SRR6128978_2.fastq.gz ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR612/008/SRR6128978/SRR6128978_2.fastq.gz
wget --progress=dot:mega --waitretry=30 --retry-connrefused ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR612/008/SRR6128978/SRR6128978_2.fastq.gz

echo "Done Donwnloading SRA Data."
cd ..

echo "Subsampling Data"

./subsample_data.nf

echo "Done Subsampling Data"

