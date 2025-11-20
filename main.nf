nextflow.enable.dsl=2

workflow.onComplete {
  println "\nPipeline finished. Outputs in: ${params.outdir}\n"
}

// Input channel for paired reads
READS_CH = Channel.fromFilePairs(params.reads, flat:true)


// TRIMMOMATIC PROCESS

process TRIMMOMATIC {
    tag { sample_id }
    publishDir "${params.outdir}/trimmed", mode: 'copy'

    conda "/Users/chandankrishnapavuluri/opt/anaconda3/envs/RNAseq"

    input:
    tuple val(sample_id), path(r1), path(r2)

    output:
    tuple val(sample_id), \
          path("${sample_id}_R1.paired.fastq.gz"), \
          path("${sample_id}_R2.paired.fastq.gz")

    script:
    """
    mkdir -p ${params.basedir}/logs/
    trimmomatic PE -threads ${task.cpus} \
        ${r1} \
        ${r2} \
        ${sample_id}_R1.paired.fastq.gz \
        ${sample_id}_R1.unpaired.fastq.gz \
        ${sample_id}_R2.paired.fastq.gz \
        ${sample_id}_R2.unpaired.fastq.gz \
        ILLUMINACLIP:${params.adapters}:2:30:10 \
        LEADING:3 \
        TRAILING:3 \
        SLIDINGWINDOW:4:20 \
        MINLEN:36 \
        2> ${params.basedir}/logs/${sample_id}.trimmomatic.log
    """
}

process HISAT2_ALIGN {
    tag { sample_id }
    publishDir "${params.outdir}/aligned", mode: 'copy'

    conda "/Users/chandankrishnapavuluri/opt/anaconda3/envs/RNAseq"

    input:
    tuple val(sample_id), path(r1_paired), path(r2_paired)

    output:
    tuple val(sample_id), 
          path("${sample_id}.bam"),
          path("${sample_id}.bam.bai")

    script:
    """
    hisat2 -p ${task.cpus} \
        -x ${params.hisat2_index} \
        -1 ${r1_paired} \
        -2 ${r2_paired} \
        2> ${params.basedir}/logs/${sample_id}.hisat2.log \
      | samtools sort -@ 4 -o ${sample_id}.bam

    samtools index ${sample_id}.bam
    """
}

process SALMON_QUANT {
    tag { sample_id }
    publishDir "${params.outdir}/salmon", mode: 'copy'

    conda "/Users/chandankrishnapavuluri/opt/anaconda3/envs/RNAseq"

    input:
    tuple val(sample_id), path(r1_paired), path(r2_paired)

    output:
    path "${sample_id}_salmon"

    script:
    """
    salmon quant -i ${params.salmon_index} \
        -l A \
        -1 ${r1_paired} \
        -2 ${r2_paired} \
        -p ${task.cpus} \
        -o ${sample_id}_salmon
    """
}

process FEATURECOUNTS {
    tag { sample_id }
    publishDir "${params.outdir}/counts", mode: 'copy'

    conda "/Users/chandankrishnapavuluri/opt/anaconda3/envs/RNAseq"

    input:
    tuple val(sample_id), path(bam), path(bai)

    output:
    path "${sample_id}_counts.txt"

    script:
    """
    featureCounts -T ${task.cpus} \
        -t exon \
        -g gene_id \
        -a ${params.gtf} \
        -o ${sample_id}_counts.txt \
        ${bam} \
        2> ${params.basedir}/logs/${sample_id}.featurecounts.log
    """
}


process MERGE_FEATURECOUNTS {
    publishDir "${params.outdir}/counts", mode: 'copy'
    conda "/Users/chandankrishnapavuluri/opt/anaconda3"

    input:
        path count_files


    script:
    """
    python3 ${params.basedir}/scripts/merge_featurecounts.py ${params.basedir}
    """
}


process MERGE_SALMON {
    publishDir "${params.outdir}/salmon", mode: 'copy'
    conda "/Users/chandankrishnapavuluri/opt/anaconda3"

    input:
        path salmon_dirs


    script:
    """
    python3 ${params.basedir}/scripts/merge_salmon.py ${params.basedir}
    """
}




// WORKFLOW
workflow {
    trimmed = TRIMMOMATIC(READS_CH)
    aligned = HISAT2_ALIGN(trimmed)
    fc = FEATURECOUNTS(aligned)
    salmon = SALMON_QUANT(trimmed)
    MERGE_FEATURECOUNTS(fc.collect())
    MERGE_SALMON(salmon.collect())
}


