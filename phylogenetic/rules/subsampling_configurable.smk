"""
This part of the workflow subsamples sequences for constructing the phylogenetic tree.

However, this configurable subsampling allows for tierred subsampling based on values placed in the config file.

REQUIRED INPUTS:

    metadata    = results/metadata.tsv
    sequences   = results/equences.fasta

OUTPUTS:

    metadata_subsampled = results/metadata_filtered.tsv
    sequences_subsampled = results/sequences_filtered.fasta

This part of the workflow usually includes one or more of the following steps:

    - augur filter

See Augur's usage docs for these commands for more details.
"""

ruleorder: extract_subsampled_sequences_and_metadata > filter_manual

rule subsample:
    input:
        metadata = config["input_metadata"],
        sequences = config["input_sequences"],
    output:
        subsampled_strains = "results/subsampled_strains_{subsample}.txt",
    params:
        filters = lambda wildcards: config.get("subsampling", {}).get(wildcards.subsample, ""),
        id_column = config["strain_id_field"],
    shell:
        """
        augur filter \
            --sequences {input.sequences} \
            --metadata {input.metadata} \
            --metadata-id-columns {params.id_column} \
            {params.filters} \
            --output-strains {output.subsampled_strains}
        """

rule extract_subsampled_sequences_and_metadata:
    input:
        sequences = config["input_sequences"],
        metadata = config["input_metadata"],
        subsampled_strains = expand("results/subsampled_strains_{subsample}.txt", subsample=list(config.get("subsampling", {}).keys()))
    output:
        sequences = "results/sequences_filtered.fasta",
        metadata = "results/metadata_filtered.tsv",
    params:
        id_column = config["strain_id_field"],
    shell:
        """
        augur filter \
            --sequences {input.sequences} \
            --metadata {input.metadata} \
            --metadata-id-columns {params.id_column} \
            --exclude-all \
            --include {input.subsampled_strains} \
            --output-sequences {output.sequences} \
            --output-metadata {output.metadata}
        """
