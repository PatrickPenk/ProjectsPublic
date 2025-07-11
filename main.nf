#!/usr/bin/env nextflow

params.accession_id = "M21012"
params.input_dir = "hepatitis/"
params.output_combined_file = "combined.fasta"
params.mafft_output = "combined_aligned.fasta"
params.trimal_output = "combined_aligned_trimmed.fasta"
params.trimal_report_html = "trimal_report.html"
params.outdir = "results"

// ========================== FETCH DATA ======================== //
process FETCH_FASTA {
    conda 'bioconda::entrez-direct=24.0'

    input:
    val accession_id

    output:
    path "${accession_id}.fasta", emit: sequence_fasta

    script:
    """
    esearch -db nucleotide -query "${accession_id}" | efetch fasta > "${accession_id}.fasta"
    """
}


// ================== Combine files ===================== //
process COMBINE_SEQS {

    input:
    path input_files

    output:
    path "${params.output_combined_file}", emit: combined_output

    script:
    """
    cat "${input_files}"/*.fasta > "${params.output_combined_file}"
    """
}

// ================== MAFFT Alignment Process ===================== //
process ALIGN_MAFFT {
    conda 'bioconda::mafft=7.525'

    input:
    path input_fasta

    output:
    path "${params.mafft_output}", emit: aligned_fasta

    script:
    """
    mafft --auto --thread -1 "${input_fasta}" > "${params.mafft_output}"
    """
}

// ======================== TrimAl Process ===================== //
process TRIMAL_ALIGNMENT {
    conda 'bioconda::trimal=1.5.0'

    publishDir "${params.outdir}/trimal_results", mode: 'copy', pattern: '*'

    input:
    path input_aligned_fasta

    output:
    path "${params.trimal_output}", emit: trimmed_fasta
    path "${params.trimal_report_html}", emit: trimal_html_report

    script:
    """
    trimal -in "${input_aligned_fasta}" -out "${params.trimal_output}" -automated1 -htmlout "${params.trimal_report_html}"
    """
}


// ========================== Workflow ======================== //

workflow {
    FETCH_FASTA(params.accession_id)
        Channel
        .fromPath(params.input_dir, type: 'dir')
        .set { input_dir_channel }

    COMBINE_SEQS(input_dir_channel)

    ALIGN_MAFFT(COMBINE_SEQS.out.combined_output)
    ALIGN_MAFFT.out.aligned_fasta.view { "MAFFT alignment complete: $it" }

    TRIMAL_ALIGNMENT(ALIGN_MAFFT.out.aligned_fasta)
}
