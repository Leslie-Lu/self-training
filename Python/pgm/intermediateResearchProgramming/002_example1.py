import time
import gzip

def read_fasta_sample(fp):
    name, seq= None, []
    for line in fp:
        line= line.strip()
        if line.startswith(">"):
            if name: yield (name, "".join(seq).upper())
            name, seq= line[1:], []
        else:
            seq.append(line)
    if name: yield (name, "".join(seq).upper())

def read_file(file_name):
    n_samples= 0
    with open(file_name, "rb") as test_f:
        zipped= test_f.read(2) == b"\x1f\x8b" # gzip文件前两个字节标志
    if zipped:
        fh= gzip.open(file_name, "rt")
    else:
        fh= open(file_name, "rt")
    with fh as fasta:
        seqs= list()
        names= list()
        for h, s in read_fasta_sample(fasta):
            if len(s) % 3 != 0:
                raise RuntimeError(f"Sequence {h} is not a multiple of three")
            elif len(seqs)>0 and len(s) != len(seqs[0]):
                raise RuntimeError(f"Sequence {h} is length {len(s)}, expecting {len(seqs[0])}")
            else:
                seqs.append(s)
                names.append(h)
    return seqs, names

def countCodons(seqs):
    bases= ['A', 'C', 'G', 'T']
    codons= list()
    for base1 in bases:
        for base2 in bases: 
            for base3 in bases:
                codon= "".join((base1+base2+base3))
                codons.append(codon)

    codons_len= int(len(seqs[0]) // 3)
    counts= [dict() for _ in range(codons_len)]
    for seq in seqs:
        for codon_idx in range(codons_len):
            codon= seq[codon_idx:(codon_idx+3)]
            if not "-" in codon:
                if codon in counts[codon_idx]:
                    counts[codon_idx][codon]+= 1
                else:
                    counts[codon_idx][codon]= 1
    
    count_vec= list()
    for pos in counts:
        pos_vec= list()
        for codon in codons:
                if codon in pos:
                    pos_vec.append(pos[codon])
                else:
                    pos_vec.append(0)
        count_vec.append(pos_vec)
    
    return count_vec

def main():
    start_t= time.time_ns()
    seqs, names= read_file("/share/home/lsy_luzhen/software/Git/data/self-training/Python/materials/BIGSdb_024538_1190028856_31182.dna.aln.gz")
    end_t= time.time_ns()
    time_ms= (end_t-start_t)/1000000
    print(f"time to read {len(seqs)} samples: {time_ms} ms")
    count_vec= countCodons(seqs)

if __name__== "__main__":
    main()