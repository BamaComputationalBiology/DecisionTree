import sys

# for standard format FASTQ files
# python fqrebuild.py original.fq tokeep.readids new.fq

def main(fastq, idlist, fqout):
    ids = []
    with open(idlist) as idl:
        for line in idl:
            ids.append(line.strip())
    ids = set(ids)
    with open(fastq) as fq:
        with open(fqout, "w+") as fqo:
            line = fq.readline()
            while "@" in line:
                header = line
                line = fq.readline()
                line2 = fq.readline()
                linecount = 1
                seqbuilder = line
                qualbuilder = ""
                while not ("+" == line2[0]):
                    seqbuilder += line2
                    linecount += 1
                    line2 = fq.readline()
                else:
                    info = line2
                    for i in range(0, linecount):
                        qualbuilder += fq.readline()
                if header[1::].split()[0] in ids:
                    fqo.write(header)
                    fqo.write(seqbuilder)
                    fqo.write(info)
                    fqo.write(qualbuilder)
                line = fq.readline()
if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2], sys.argv[3])