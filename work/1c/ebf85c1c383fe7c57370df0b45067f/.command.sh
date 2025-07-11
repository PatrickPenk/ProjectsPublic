#!/bin/bash -ue
mafft --auto --thread -1 "combined.fasta" > "combined_aligned.fasta"
