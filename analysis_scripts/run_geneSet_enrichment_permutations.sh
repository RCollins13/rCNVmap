#!/usr/bin/env bash

##############################
#    Rare CNV Map Project    #
##############################

# Copyright (c) 2017 Ryan L. Collins
# Distributed under terms of the MIT License (see LICENSE)
# Contact: Ryan L. Collins <rlcollins@g.harvard.edu>
# Code development credits availble on GitHub

#Code to run benchmarking permutation tests for gene set enrichments
#See set_enrichment_benchmarking.sh for description

#####Set parameters
export WRKDIR=/data/talkowski/Samples/rCNVmap
source ${WRKDIR}/bin/rCNVmap/misc/rCNV_code_parameters.sh

#####Read arguments
VF=$1
CNV=$2
pheno=$3
n=$4
W=$5

#####run
for i in $( seq -w 0001 1000 ); do
	echo -e "STARTING TEST ${i}"
  if [ ${W} -eq 0 ]; then
    ${WRKDIR}/bin/rCNVmap/bin/geneSet_permutation_test.sh -N 1000 \
    -H ${WRKDIR}/data/misc/exons_boundaries_dictionary/ \
    -U ${WRKDIR}/data/master_annotations/genelists/Gencode_v19_protein_coding.genes.list \
    -o ${WRKDIR}/analysis/benchmarking/geneSet_enrichments/permutation_testing_${VF}/${CNV}/${pheno}/results_exons_n${n}_i${i}.txt \
    ${WRKDIR}/data/CNV/CNV_MASTER/CTRL/CTRL.${CNV}.${VF}.GRCh37.all.bed.gz \
    ${WRKDIR}/data/CNV/CNV_MASTER/${pheno}/${pheno}.${CNV}.${VF}.GRCh37.all.bed.gz \
    ${WRKDIR}/analysis/benchmarking/geneSet_enrichments/simulated_sets/genes_n${n}/geneSet_n${n}_${i}.list \
    ${WRKDIR}/data/master_annotations/gencode/gencode.v19.annotation.gtf
  else
    ${WRKDIR}/bin/rCNVmap/bin/geneSet_permutation_test.sh -N 1000 -W \
    -H ${WRKDIR}/data/misc/exons_boundaries_dictionary/ \
    -U ${WRKDIR}/data/master_annotations/genelists/Gencode_v19_protein_coding.genes.list \
    -o ${WRKDIR}/analysis/benchmarking/geneSet_enrichments/permutation_testing_${VF}/${CNV}/${pheno}/results_wholegenes_n${n}_i${i}.txt \
    ${WRKDIR}/data/CNV/CNV_MASTER/CTRL/CTRL.${CNV}.${VF}.GRCh37.all.bed.gz \
    ${WRKDIR}/data/CNV/CNV_MASTER/${pheno}/${pheno}.${CNV}.${VF}.GRCh37.all.bed.gz \
    ${WRKDIR}/analysis/benchmarking/geneSet_enrichments/simulated_sets/genes_n${n}/geneSet_n${n}_${i}.list \
    ${WRKDIR}/data/master_annotations/gencode/gencode.v19.annotation.gtf
  fi
done