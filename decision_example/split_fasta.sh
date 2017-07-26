# bash script to split wgs .fasta into individual scaffolds and create a new .fasta with scaffolds from the target organism
# requires a 'whitelist' of scaffolds to keep (here, scaffolds_to_keep.txt) and a .fasta of assembled sequence (here, final.assembly.fasta)


#!/bin/bash

awk '/^>scaffold/ {OUT=substr($0,2) ".fasta"}; OUT {print >OUT}' final.assembly.fasta
cat scaffolds_to_keep.txt | while read line; do cat "scaffold_"$line".fasta" ; done > kept_scaffolds.fasta
rm "scaffold"*".fasta"


# bash line for checking consistency between the whitelist and the new scaffolds file

cat kept_scaffolds.fasta | grep '^>' | tr -d '\>scaffold\_' | sort -n | diff - scaffolds_to_keep.txt 
