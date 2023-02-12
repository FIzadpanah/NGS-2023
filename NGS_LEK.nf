// mafft [arguments] input > output
// trimal -in example1 -out output8 -htmlout output8.html -automated1

nextflow.enable.dsl = 2
params.out = "${launchDir}/output" 
params.storedir = "${baseDir}/cache"

//1-Download the refernce fastafiles from NCBI:
process downloadReferencefasta{
publishDir params.out, mode: "copy" , overwrite : true
storeDir params.storedir  

output:
    path "AX741154.fasta"  
// SRA toll could be used to download the accesion
script:
"""
esearch -db nucleotide -query "AX741154" | efetch -format fasta > AX741154.fasta
"""
}
//2-Download the all fastafiles:
process downloadfastafiles{
publishDir params.out, mode: "copy", overwrite : true
storeDir params.storedir  

output:
    path "fastafile.fasta"

script:
"""
wget "https://gitlab.com/dabrowskiw/cq-examples/-/tree/master/data/hepatitis" -O fastafile.fasta
"""
}
//3- combining all the files:
process combinefiles{
publishDir params.out, mode: "copy" , overwrite : true
    
input:
    path  "AX741154.fasta"
    path "fastafile.fasta"

output:
    path "complete.fasta"  
script:
"""
cat  AX741154.fasta  fastafile.fasta  > complete.fasta
"""
} 

//4- Mafft the file:
process mafftedFile {
publishDir params.out, mode: "copy"
container "https://depot.galaxyproject.org/singularity/mafft%3A7.221--0"

input:
    path "complete.fatsa"

output:
    path "mafftResult.fasta"

"""
mafft complete.fatsa > mafftResult.fasta
"""
}

//5- cleaning through Trimal:
process trimmedFile{
publishDir params.out, mode: "copy"
container "https://depot.galaxyproject.org/singularity/trimal%3A1.4.1--h9f5acd7_6"

input:
    path "mafftResult.fasta"

output:
    path "trimmResult.fasta", emit: cleanedile
    path "trimmedreport.html", emit: finalreport

"""
trimal -in mafftResult.fasta -out trimmResult.fasta -automated1 -htmlout trimmedreport.html 
"""
}


workflow{
    referencefasta_channel = downloadReferencefasta()
    fastafile_channel = downloadfastafiles().collect()
    combinefiles_channel = combinefiles(referencefasta_channel,fastafile_channel) 
    mafft_channel = mafftedFile(combinefiles_channel)
    trimmedFile(mafft_channel)
}

// we cold use these parameters:
//params.inpath = null
//params.accession = null
// then we should implimented the processes and then workflow:
// reffiledownlod:
//input:
  //path inpath
//output:
  //  path "AX741154.fasta"  
    //val accession
  //fastafiles download:  
    //input:
  //  path inpath
    //workflow:
/*
//referencefasta_channel = downloadReferencefasta(Channel.from(params.accession)) 
     if(params.inpath == null) {
        print "ERROR: Please provide an input with fasta files to start analysis(e.g. --inpath path)"
        System.exit(1)
        }/*/
    //fastafile_channel = Channel.fromPath("${params.inpath}/fastafile.fasta").collect()