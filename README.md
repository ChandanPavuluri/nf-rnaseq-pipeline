# nf-rnaseq-pipeline
# Chandan Pavuluri
Workflow Description

This RNA-seq preprocessing pipeline is implemented in Nextflow DSL2, enabling scalable, reproducible execution across local machines, HPC schedulers, and cloud environments. The workflow processes raw paired-end FASTQ files through quality trimming, alignment, quantification, and gene-level summarization.

`nextflow run main.nf -c nextflow.config -with-conda -with-dag dag.pdf -with-report rnaseq_report.html`

![DAG](https://github.com/ChandanPavuluri/nf-rnaseq-pipeline/blob/f670d940fec10d99d14555f2b7254402fb9b96ed/dag.png)
