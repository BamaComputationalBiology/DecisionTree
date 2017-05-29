# Blobology and kraken method notes

**Step 1: Construct a preliminary assembly**

The preliminary assembly is used for classification as the initial reads are too short to obtain any useful information. The A.vaga data was fully assembled from Illumina FASTQs, for the 534 data only the "standard" PE reads were used, not the mate pairs. Those reads were used later. 

    abyss-pe np=8 k=61 n=10 in='read_1.fastq read_2.fastq'  name=organism

**Step 2: Align reads to preliminary assembly**

This is used both to identify reads for filtering, as well as to approximate coverage for the TAGC plot used by Blobology.

    gsnap -B 5 -t 8 -A sam -N 1 -n 1 -D /path -d organism read_1.fastq read_2.fastq > organism.sam
    samtools view -bS organism.sam > organism.bam
    samtools sort organism.bam organism_sorted.bam
    samtools index organism_sorted.bam

## Blobology specific steps
**Step 3a: BLAST the preliminary assembly**

This generates a classification used to generate the TAGC plot.

    blastn \
    -task megablast \
    -query organism-scaffolds.fa \
    -db nt \
    -outfmt '6 qseqid staxids bitscore std sscinames sskingdoms stitle' \
    -culling_limit 5 \
    -num_threads 8 \
    -evalue 1e-25 \
    -out organism.blast

**Step 3b: Generate a BlobDB**

Now that the data are prepared, we can begin the actual Blobology process. The first step is to generate a BlobDB. We're using the [blobtools distribution](https://github.com/DRL/blobtools) for this paper. `nodes.db` and `names.db` are from the [NCBI Taxonomy dump.](ftp://ftp.ncbi.nlm.nih.gov/pub/taxonomy/)

    blobtools create -i organism-scaffolds.fa --nodes nodes.db --names names.db -t organsim.blast -b organism_sorted.bam

**Step 3c: Generate a TAGC plot and a view**

From the BlobDB we can generate a TAGC plot (which will be used to determine filtering characteristics) and a view (to which the characteristics will be applied to create the list of contigs to keep).

    blobtools blobplot -i blobDB.json
    blobtools view -i blobDB.json

**Step 3d: Select filtering characteristics**

Open your TAGC plot in a standard image viewer. Each circle on the plot marks a contig from the preliminary assembly. The size of the circle is determined by the contig length. The position is determined by GC content and coverage. The color is determined by the results of the BLAST search, grey for no-hits. With luck, your data will form clearly-defined "blobs". One will generally be large and belong mostly to either no-hit or to your target. Use this blob to select ranges to include or exclude from your results. 

**Step 6: Apply filtering characterisitics to contigs**

Once you've decided on filtering characteristics, you need to apply them to the actual data. We did this using AWK, a manipulation tool for delimited text and a standard part of any *nix distribution. This manipulation will be performed on the view file generated earlier. The columns of the view file are: name length  GC  N   bam0    phylum.t.6  phylum.s.7  phylum.c.8. For our purposes, the important columns are "name", "GC", and "bam0" (coverage). Select by GC and bam0 based on the blobplot, then save the name column to a separate file.

    cat view.blobDB.table.txt | awk '$3 < 0.45' | awk '$5 > 2' | awk '{print $1}' > tokeep.contigids # Example characteristics

## Kraken specific steps 

**Step 3a: Use Kraken to classify data**

[Kraken](https://ccb.jhu.edu/software/kraken/) is used directly on the preliminary assembly. The Kraken output is not human-readable, so we need to use the companion program `kraken-translate` to format it.

    kraken --db /path/to/kraken.db/ --fasta-input organism-scaffolds.fa  --output results.kraken
    kraken-translate --db /path/to/kraken.db/ results.kraken > results.kraken_translated
    
**Step 3b: Generate a list of contigs to keep**

Given the content of Kraken's database, we can assume that any contig that Kraken successfully matches with an ID is a contaminant. We can use this list and standard \*nix tools to generate a list of contigids to keep in the final assembly.

    cat results.kraken_translated | awk '{print $1}' | sort |uniq > toremove.contigids
    cat organism-scaffolds.fa | grep '>' | awk '{print $1}' | cut -c '2-' | sort | uniq > all.contigids
     comm -23 all.contigids toremove.contigids > tokeep.contigids

**Step 4: Use filtered contigs to select reads**

Using the generated list of contigids, we can select reads to use for our final assembly. The Blobtools site calles for samtools to be used for this filtering, however there were implementation issues on our end. Two scripts-`fqrebuild.py` and `mate_rebuild.py`-were written to rebuild the fastqs based on the contig lists. These scripts are located in the repository. `fqrebuild.py` is designed for standard format FASTQs, `mate_rebuild.py` was designed for the title format of the FASTQs containing mate-pair reads.

    samtools view organism_sorted.bam `cat tokeep.contigids | tr "\n" " "` | awk '{print $1}' | sort | uniq > tokeep.readids
    python mate_rebuild.py read_1.fastq tokeep.readids rebuild_1.fastq # repeat for all FASTQs
    
**Step 5: Final assembly and downstream analysis**

Send the rebuilt FASTQ files to their downstream analysis software.