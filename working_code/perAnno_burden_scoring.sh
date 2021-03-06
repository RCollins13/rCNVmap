#!/usr/bin/env bash

##############################
#    Rare CNV Map Project    #
##############################

# Copyright (c) 2017 Ryan L. Collins
# Distributed under terms of the MIT License (see LICENSE)
# Contact: Ryan L. Collins <rlcollins@g.harvard.edu>
# Code development credits availble on GitHub

#Code to run all rCNV burden scoring per annotation

#####Set parameters
export WRKDIR=/data/talkowski/Samples/rCNVmap
source ${WRKDIR}/bin/rCNVmap/misc/rCNV_code_parameters.sh

#####Reinitialize directories if exists
if [ -e ${WRKDIR}/data/perAnno_burden ]; then
  rm -rf ${WRKDIR}/data/perAnno_burden
fi
mkdir ${WRKDIR}/data/perAnno_burden
if [ -e ${WRKDIR}/analysis/perAnno_burden ]; then
  rm -rf ${WRKDIR}/analysis/perAnno_burden
fi
mkdir ${WRKDIR}/analysis/perAnno_burden

#####Create subdirectories
while read pheno; do
  if [ -e ${WRKDIR}/data/perAnno_burden/${pheno} ]; then
    rm -rf ${WRKDIR}/data/perAnno_burden/${pheno}
  fi
  mkdir ${WRKDIR}/data/perAnno_burden/${pheno}
  if [ -e ${WRKDIR}/analysis/perAnno_burden/${pheno} ]; then
    rm -rf ${WRKDIR}/analysis/perAnno_burden/${pheno}
  fi
  mkdir ${WRKDIR}/analysis/perAnno_burden/${pheno}
done < <( fgrep -v "#" ${WRKDIR}/bin/rCNVmap/misc/analysis_group_HPO_mappings.list | \
          cut -f1 | fgrep -v CTRL )

#####Reorder noncoding annotations based on number of elements in group
while read class path; do
  nElements=$( cat ${path} | wc -l )
  echo -e "${class}\t${path}\t${nElements}"
done < ${WRKDIR}/bin/rCNVmap/misc/master_noncoding_annotations.list | \
sort -nk3,3 | cut -f1-2 > \
${WRKDIR}/bin/rCNVmap/misc/master_noncoding_annotations.prioritized_for_annoScore_modeling.list

#Final analysis: subset of all combinations, but exclude CNVs with >200kb overlap with any large segment
# or any exonic overlap with a known dominant disease gene
#Prep file of dominant disease genes
cat ${WRKDIR}/data/master_annotations/genelists/*dominant* \
    ${WRKDIR}/data/master_annotations/genelists/*Dominant* | sort | uniq | \
sed 's/\-/_/g' > ${TMPDIR}/dominant_disease_genes.list
#Prep CNVs:
for pheno in CTRL GERM NEURO NDD PSYCH SOMA; do
  echo ${pheno}
  for VF in E4; do
    for CNV in DEL; do
      zcat ${WRKDIR}/data/CNV/CNV_MASTER/${pheno}/${pheno}.${CNV}.${VF}.GRCh37.haplosufficient.bed.gz | head -n1 > \
      ${WRKDIR}/data/CNV/CNV_MASTER/${pheno}/${pheno}.${CNV}.${VF}.GRCh37.haplosufficient_largeSegmentExcluded_sigGeneExcluded.bed
      bedtools coverage \
      -a ${WRKDIR}/analysis/large_CNV_segments/master_lists/${CNV}_E2_all.signif.bed \
      -b ${WRKDIR}/data/CNV/CNV_MASTER/${pheno}/${pheno}.${CNV}.${VF}.GRCh37.haplosufficient.bed.gz | \
      awk -v OFS="\t" '{ if ($(NF-2)<200000) print $1, $2, $3, $4, $5, $6, $7 }' | \
      bedtools intersect -v -wa -a - \
                         -b <( fgrep -wf ${TMPDIR}/dominant_disease_genes.list \
                                         <( sed 's/\-/_/g' ${WRKDIR}/data/master_annotations/gencode/gencode.v19.exons.protein_coding.bed ) ) | \
      sort -Vk1,1 -k2,2n -k3,3n >> \
      ${WRKDIR}/data/CNV/CNV_MASTER/${pheno}/${pheno}.${CNV}.${VF}.GRCh37.haplosufficient_largeSegmentExcluded_sigGeneExcluded.bed
      gzip -f ${WRKDIR}/data/CNV/CNV_MASTER/${pheno}/${pheno}.${CNV}.${VF}.GRCh37.haplosufficient_largeSegmentExcluded_sigGeneExcluded.bed
    done
    for CNV in DUP; do
      zcat ${WRKDIR}/data/CNV/CNV_MASTER/${pheno}/${pheno}.${CNV}.${VF}.GRCh37.noncoding.bed.gz | head -n1 > \
      ${WRKDIR}/data/CNV/CNV_MASTER/${pheno}/${pheno}.${CNV}.${VF}.GRCh37.noncoding_largeSegmentExcluded.bed
      bedtools coverage \
      -a ${WRKDIR}/analysis/large_CNV_segments/master_lists/${CNV}_E2_all.signif.bed \
      -b ${WRKDIR}/data/CNV/CNV_MASTER/${pheno}/${pheno}.${CNV}.${VF}.GRCh37.noncoding.bed.gz | \
      awk -v OFS="\t" '{ if ($(NF-2)<200000) print $1, $2, $3, $4, $5, $6, $7 }' | \
      sort -Vk1,1 -k2,2n -k3,3n >> \
      ${WRKDIR}/data/CNV/CNV_MASTER/${pheno}/${pheno}.${CNV}.${VF}.GRCh37.noncoding_largeSegmentExcluded.bed
      gzip -f ${WRKDIR}/data/CNV/CNV_MASTER/${pheno}/${pheno}.${CNV}.${VF}.GRCh37.noncoding_largeSegmentExcluded.bed
    done
  done
done

#####Submit burden data collection for all phenotypes
while read pheno; do
  for CNV in CNV DEL DUP; do
    # if [ -e ${WRKDIR}/data/perAnno_burden/${pheno}/${CNV} ]; then
    #   rm -rf ${WRKDIR}/data/perAnno_burden/${pheno}/${CNV}
    # fi
    # mkdir ${WRKDIR}/data/perAnno_burden/${pheno}/${CNV}
    for VF in E4; do
      # if [ -e ${WRKDIR}/data/perAnno_burden/${pheno}/${CNV}/${VF} ]; then
      #   rm -rf ${WRKDIR}/data/perAnno_burden/${pheno}/${CNV}/${VF}
      # fi
      # mkdir ${WRKDIR}/data/perAnno_burden/${pheno}/${CNV}/${VF}
      for filt in haplosufficient noncoding; do
        # if [ -e ${WRKDIR}/data/perAnno_burden/${pheno}/${CNV}/${VF}/${filt} ]; then
        #   rm -rf ${WRKDIR}/data/perAnno_burden/${pheno}/${CNV}/${VF}/${filt}
        # fi
        # mkdir ${WRKDIR}/data/perAnno_burden/${pheno}/${CNV}/${VF}/${filt}
        bsub -q normal -sla miket_sc -u nobody -J ${pheno}_${CNV}_${VF}_perAnno_burden_dataCollection_${filt} \
        "${WRKDIR}/bin/rCNVmap/analysis_scripts/gather_annoScore_data_batchMode.sh -F \
        ${pheno} ${CNV} ${VF} ${filt} \
        ${WRKDIR}/bin/rCNVmap/misc/master_noncoding_annotations.prioritized_for_annoScore_modeling.list"
      done
    done
  done
done < <( fgrep -v "#" ${WRKDIR}/bin/rCNVmap/misc/analysis_group_HPO_mappings.list | \
          cut -f1 | fgrep -v CTRL )
#Final analysis: subset of all possible combinations
for pheno in GERM NEURO NDD PSYCH SOMA; do 
  for VF in E4; do 
    for CNV in DEL; do
      for filt in haplosufficient; do
        while read class path; do
          bsub -q normal -sla miket_sc -u nobody -J ${pheno}_${CNV}_haplosuff_${class} \
          "${WRKDIR}/bin/rCNVmap/bin/gather_annoScore_data.sh -z \
          -p ${class} \
          -o ${WRKDIR}/data/perAnno_burden/${pheno}/${CNV}/${VF}/${filt}/${pheno}.${CNV}.${VF}.haplosufficient.${class}.annoScoreData.bed \
          ${WRKDIR}/data/CNV/CNV_MASTER/CTRL/CTRL.${CNV}.${VF}.GRCh37.haplosufficient_largeSegmentExcluded_sigGeneExcluded.bed.gz \
          ${WRKDIR}/data/CNV/CNV_MASTER/${pheno}/${pheno}.${CNV}.${VF}.GRCh37.haplosufficient_largeSegmentExcluded_sigGeneExcluded.bed.gz \
          ${path} ${h37}"
        done < ${WRKDIR}/bin/rCNVmap/misc/master_noncoding_annotations.prioritized_for_annoScore_modeling.list
      done
    done
    for CNV in DUP; do
      for filt in noncoding; do
        while read class path; do
          bsub -q normal -sla miket_sc -u nobody -J ${pheno}_${CNV}_noncoding_${class} \
          "${WRKDIR}/bin/rCNVmap/bin/gather_annoScore_data.sh -z \
          -p ${class} \
          -o ${WRKDIR}/data/perAnno_burden/${pheno}/${CNV}/${VF}/${filt}/${pheno}.${CNV}.${VF}.noncoding.${class}.annoScoreData.bed \
          ${WRKDIR}/data/CNV/CNV_MASTER/CTRL/CTRL.${CNV}.${VF}.GRCh37.noncoding_largeSegmentExcluded.bed.gz \
          ${WRKDIR}/data/CNV/CNV_MASTER/${pheno}/${pheno}.${CNV}.${VF}.GRCh37.noncoding_largeSegmentExcluded.bed.gz \
          ${path} ${h37}"
        done < ${WRKDIR}/bin/rCNVmap/misc/master_noncoding_annotations.prioritized_for_annoScore_modeling.list
      done
    done
  done
done


#####Submit annoScore model for all phenotypes
while read pheno; do
  #Get number of subjects in group
  nCASE=$( awk -v pheno=${pheno} '{ if ($1==pheno) print $4 }' \
           ${WRKDIR}/data/plot_data/figure1/sample_counts_by_group.txt )
  for CNV in CNV DEL DUP; do
    if [ -e ${WRKDIR}/analysis/perAnno_burden/${pheno}/${CNV} ]; then
      rm -rf ${WRKDIR}/analysis/perAnno_burden/${pheno}/${CNV}
    fi
    mkdir ${WRKDIR}/analysis/perAnno_burden/${pheno}/${CNV}
    for VF in E4; do
      if [ -e ${WRKDIR}/analysis/perAnno_burden/${pheno}/${CNV}/${VF} ]; then
        rm -rf ${WRKDIR}/analysis/perAnno_burden/${pheno}/${CNV}/${VF}
      fi
      mkdir ${WRKDIR}/analysis/perAnno_burden/${pheno}/${CNV}/${VF}
      for filt in haplosufficient noncoding; do
        if [ -e ${WRKDIR}/analysis/perAnno_burden/${pheno}/${CNV}/${VF}/${filt} ]; then
          rm -rf ${WRKDIR}/analysis/perAnno_burden/${pheno}/${CNV}/${VF}/${filt}
        fi
        mkdir ${WRKDIR}/analysis/perAnno_burden/${pheno}/${CNV}/${VF}/${filt}
        #Launch model in batch mode across all annotations
        bsub -q normal -u nobody -sla miket_sc -J ${pheno}_${CNV}_${VF}_${filt}_annoScoreModel \
        "${WRKDIR}/bin/rCNVmap/analysis_scripts/run_annoScore_model_batchMode.sh \
        ${pheno} ${CNV} ${VF} ${filt} \
        ${WRKDIR}/bin/rCNVmap/misc/master_noncoding_annotations.prioritized_for_annoScore_modeling.list"
      done
    done
  done
done < <( fgrep -v "#" ${WRKDIR}/bin/rCNVmap/misc/analysis_group_HPO_mappings.list | \
          cut -f1 | fgrep -v CTRL )
#Final analysis: subset of all possible combinations
for pheno in GERM NEURO NDD PSYCH SOMA; do 
  #Get number of subjects in group
  nCASE=$( awk -v pheno=${pheno} '{ if ($1==pheno) print $4 }' \
           ${WRKDIR}/data/plot_data/figure1/sample_counts_by_group.txt )
  nCTRL=38628
  for CNV in DEL DUP; do
    if [ ${CNV} == "DEL" ]; then
      filt=haplosufficient
    else
      filt=noncoding
    fi
    for VF in E4; do
      #Iterates over elements list and runs model
      while read class path; do
        annoScoreData=${WRKDIR}/data/perAnno_burden/${pheno}/${CNV}/${VF}/${filt}/${pheno}.${CNV}.${VF}.${filt}.${class}.annoScoreData.bed.gz
        if [ -e ${annoScoreData} ]; then
          OUTFILE=${WRKDIR}/analysis/perAnno_burden/${pheno}/${CNV}/${VF}/${filt}/${pheno}.${CNV}.${VF}.${filt}.${class}.annoScore_stats.bed
          #Runs model from gzipped file
          bsub -q normal -u nobody -sla miket_sc -J ${pheno}_${CNV}_${VF}_${filt}_annoScoreModel_${class} \
          "${WRKDIR}/bin/rCNVmap/bin/run_annoScore_model.R \
          -o ${OUTFILE} \
          ${annoScoreData} \
          ${nCTRL} \
          ${nCASE}
          #Compress output
          if [ -e ${OUTFILE} ]; then
            gzip -f ${OUTFILE}
          fi"
        else
          echo "OUTPUT FOR ${pheno} ${CNV} ${VF} ${filt} vs ${path} IS MISSING. SKIPPING..."
        fi
      done < ${WRKDIR}/bin/rCNVmap/misc/master_noncoding_annotations.prioritized_for_annoScore_modeling.list
    done
  done
done


#####Collect significant elements per track per phenotype
while read pheno; do
  #Make output directories (if necessary)
  if ! [ -e ${WRKDIR}/analysis/perAnno_burden/signif_elements/${pheno} ]; then
    mkdir ${WRKDIR}/analysis/perAnno_burden/signif_elements/${pheno}
  fi
  if ! [ -e ${WRKDIR}/analysis/perAnno_burden/signif_elements/CTRL ]; then
    mkdir ${WRKDIR}/analysis/perAnno_burden/signif_elements/CTRL
  fi
  for CNV in CNV DEL DUP; do
    for VF in E4; do
      for filt in haplosufficient noncoding; do
        #Launch collection script for all annotations
        bsub -q normal -u nobody -sla miket_sc -J ${pheno}_${CNV}_${VF}_${filt}_annoScoreModel \
        "${WRKDIR}/bin/rCNVmap/analysis_scripts/collect_significant_elements_perClass_perPheno_annoScore.sh \
        ${pheno} ${CNV} ${VF} ${filt} \
        ${WRKDIR}/bin/rCNVmap/misc/master_noncoding_annotations.prioritized_for_annoScore_modeling.list"
      done
    done
  done
done < <( fgrep -v "#" ${WRKDIR}/bin/rCNVmap/misc/analysis_group_HPO_mappings.list | \
          cut -f1 | fgrep -v CTRL )
#Final analysis for paper: subset of all combinations
for pheno in GERM NEURO NDD PSYCH SOMA; do
  #Make output directories (if necessary)
  if ! [ -e ${WRKDIR}/analysis/perAnno_burden/signif_elements/${pheno} ]; then
    mkdir ${WRKDIR}/analysis/perAnno_burden/signif_elements/${pheno}
  fi
  if ! [ -e ${WRKDIR}/analysis/perAnno_burden/signif_elements/CTRL ]; then
    mkdir ${WRKDIR}/analysis/perAnno_burden/signif_elements/CTRL
  fi
  for CNV in DEL DUP; do
    if [ ${CNV} == "DEL" ]; then
      filt=haplosufficient
    else
      filt=noncoding
    fi
    for VF in E4; do
      #Launch collection script for all annotations
      bsub -q normal -u nobody -sla miket_sc -J ${pheno}_${CNV}_${VF}_${filt}_annoScoreModel \
      "${WRKDIR}/bin/rCNVmap/analysis_scripts/collect_significant_elements_perClass_perPheno_annoScore.sh \
      ${pheno} ${CNV} ${VF} ${filt} \
      ${WRKDIR}/bin/rCNVmap/misc/master_noncoding_annotations.prioritized_for_annoScore_modeling.list"
    done
  done
done


#####Collect significant elements across all tracks per phenotype
#Make lists of tissue-defined elements
while read tissue; do
  fgrep ${tissue} ${WRKDIR}/bin/rCNVmap/misc/master_noncoding_annotations.alternative_sort.list > \
  ${WRKDIR}/lists/all_${tissue}_genome_annotations.list
done < <( cut -f1 ${WRKDIR}/bin/rCNVmap/misc/OrganGroup_Consolidation_NoncodingAnnotation_Linkers.list | \
          sort | uniq )
#Make list of tissue-agnostic annotations
cut -f1 ${WRKDIR}/bin/rCNVmap/misc/OrganGroup_Consolidation_NoncodingAnnotation_Linkers.list | \
sort | uniq | fgrep -vf - \
${WRKDIR}/bin/rCNVmap/misc/master_noncoding_annotations.alternative_sort.list > \
${WRKDIR}/lists/tissue_agnostic_genome_annotations.list
#Make list of enhancer prioritization annotations

#Iterate over phenotypes
while read pheno; do
  #Make output directories (if necessary)
  if ! [ -e ${WRKDIR}/analysis/perAnno_burden/signif_elements/${pheno}/merged ]; then
    mkdir ${WRKDIR}/analysis/perAnno_burden/signif_elements/${pheno}/merged
  fi
  for CNV in CNV DEL DUP; do
    for VF in E4; do
      for filt in haplosufficient noncoding; do
        #Launch merge & filtering script across all annotations
        bsub -q normal -u nobody -sla miket_sc -J ${pheno}_${CNV}_${VF}_${filt}_mergeSignificantElements_all \
        "${WRKDIR}/bin/rCNVmap/analysis_scripts/collect_significant_elements_merged_perPheno_annoScore.sh \
        ${pheno} ${CNV} ${VF} ${filt} \
        ${WRKDIR}/bin/rCNVmap/misc/master_noncoding_annotations.alternative_sort.list \
        bonf \
        ${WRKDIR}/analysis/perAnno_burden/signif_elements/${pheno}/merged/${pheno}.${CNV}.${VF}.${filt}.bonf_sig_elements_merged.all_classes.bed"
        #Launch merge & filtering script for tissue-agnostic annotations
        bsub -q normal -u nobody -sla miket_sc -J ${pheno}_${CNV}_${VF}_${filt}_mergeSignificantElements_tissueAgnostic \
        "${WRKDIR}/bin/rCNVmap/analysis_scripts/collect_significant_elements_merged_perPheno_annoScore.sh \
        ${pheno} ${CNV} ${VF} ${filt} \
        ${WRKDIR}/lists/tissue_agnostic_genome_annotations.list \
        bonf \
        ${WRKDIR}/analysis/perAnno_burden/signif_elements/${pheno}/merged/${pheno}.${CNV}.${VF}.${filt}.bonf_sig_elements_merged.tissue_agnostic.bed"
        #Iterate over tissues and launch merge & filtering script for tissue-dependent annotations
        while read tissue; do
          bsub -q short -u nobody -sla miket_sc -J ${pheno}_${CNV}_${VF}_${filt}_mergeSignificantElements_${tissue} \
          "${WRKDIR}/bin/rCNVmap/analysis_scripts/collect_significant_elements_merged_perPheno_annoScore.sh \
          ${pheno} ${CNV} ${VF} ${filt} \
          ${WRKDIR}/lists/all_${tissue}_genome_annotations.list \
          bonf \
          ${WRKDIR}/analysis/perAnno_burden/signif_elements/${pheno}/merged/${pheno}.${CNV}.${VF}.${filt}.bonf_sig_elements_merged.${tissue}.bed"
        done < <( cut -f1 ${WRKDIR}/bin/rCNVmap/misc/OrganGroup_Consolidation_NoncodingAnnotation_Linkers.list | \
                  sort | uniq )
        #Launch merge & filtering script across all annotations
        bsub -q normal -u nobody -sla miket_sc -J ${pheno}_${CNV}_${VF}_${filt}_mergeSignificantElements_enhancerPrioritization \
        "${WRKDIR}/bin/rCNVmap/analysis_scripts/collect_significant_elements_merged_perPheno_annoScore.sh \
        ${pheno} ${CNV} ${VF} ${filt} \
        ${WRKDIR}/bin/rCNVmap/misc/master_noncoding_annotations.enhancer_prioritization.list \
        bonf \
        ${WRKDIR}/analysis/perAnno_burden/signif_elements/${pheno}/enhancer_prioritization/${pheno}.${CNV}.${VF}.${filt}.bonf_sig_elements_merged.enhancer_prioritization.bed"
      done
    done
  done
done < <( fgrep -v "#" ${WRKDIR}/bin/rCNVmap/misc/analysis_group_HPO_mappings.list | \
          cut -f1 | fgrep -v CTRL )
#Final analysis for paper: subset of all combinations
for pheno in GERM NEURO NDD PSYCH SOMA; do
  #Make output directories (if necessary)
  if ! [ -e ${WRKDIR}/analysis/perAnno_burden/signif_elements/${pheno}/enhancer_prioritization ]; then
    mkdir ${WRKDIR}/analysis/perAnno_burden/signif_elements/${pheno}/enhancer_prioritization
  fi
  for CNV in DEL DUP; do
    if [ ${CNV} == "DEL" ]; then
      filt=haplosufficient
    else
      filt=noncoding
    fi
    for VF in E4; do
      # #Launch merge & filtering script across all annotations
      # bsub -q normal -u nobody -sla miket_sc -J ${pheno}_${CNV}_${VF}_${filt}_mergeSignificantElements_all \
      # "${WRKDIR}/bin/rCNVmap/analysis_scripts/collect_significant_elements_merged_perPheno_annoScore.sh \
      # ${pheno} ${CNV} ${VF} ${filt} \
      # ${WRKDIR}/bin/rCNVmap/misc/master_noncoding_annotations.alternative_sort.list \
      # bonf \
      # ${WRKDIR}/analysis/perAnno_burden/signif_elements/${pheno}/merged/${pheno}.${CNV}.${VF}.${filt}.bonf_sig_elements_merged.all_classes.bed"
      #Launch merge & filtering script across all annotations
      bsub -q normal -u nobody -sla miket_sc -J ${pheno}_${CNV}_${VF}_${filt}_mergeSignificantElements_enhancerPrioritization \
      "${WRKDIR}/bin/rCNVmap/analysis_scripts/collect_significant_elements_merged_perPheno_annoScore.sh \
      ${pheno} ${CNV} ${VF} ${filt} \
      ${WRKDIR}/bin/rCNVmap/misc/master_noncoding_annotations.enhancer_prioritization.list \
      bonf \
      ${WRKDIR}/analysis/perAnno_burden/signif_elements/${pheno}/enhancer_prioritization/${pheno}.${CNV}.${VF}.${filt}.bonf_sig_elements_merged.enhancer_prioritization.bed"
    done
  done
done


#####Get count of significant loci by phenotype
#Merged across all annotations
VF=E4
while read pheno; do
  for dummy in 1; do
    echo ${pheno}
    for CNV in DEL DUP; do
      for filt in haplosufficient noncoding; do
        fgrep -v "#" ${WRKDIR}/analysis/perAnno_burden/signif_elements/${pheno}/merged/${pheno}.${CNV}.${VF}.${filt}.bonf_sig_elements_merged.all_classes.bed | \
        awk '{ if ($3-$2>=5000 && $3-$2<500000) print $0 }' | wc -l
      done
    done
  done | paste -s
done < <( fgrep -v "#" ${WRKDIR}/bin/rCNVmap/misc/analysis_group_HPO_mappings.list | \
          cut -f1 | fgrep -v CTRL )
#Final analysis: subset of all annotations
VF=E4
for pheno in GERM NEURO NDD PSYCH SOMA; do
  for dummy in 1; do
    echo ${pheno}
    for CNV in DEL DUP; do
      if [ ${CNV} == "DEL" ]; then
        filt=haplosufficient
      else
        filt=noncoding
      fi
      # fgrep -v "#" ${WRKDIR}/analysis/perAnno_burden/signif_elements/${pheno}/merged/${pheno}.${CNV}.${VF}.${filt}.bonf_sig_elements_merged.all_classes.bed | \
      # awk '{ if ($3-$2>=5000 && $3-$2<500000) print $0 }' | wc -l
      fgrep -v "#" ${WRKDIR}/analysis/perAnno_burden/signif_elements/${pheno}/enhancer_prioritization/${pheno}.${CNV}.${VF}.${filt}.bonf_sig_elements_merged.enhancer_prioritization.bed | \
      awk '{ if ($3-$2>=5000 && $3-$2<500000) print $0 }' | wc -l
    done
  done | paste -s
done


#####Merge significant loci across phenotypes & between DEL/DUP
#NOTE: UPDATED FOR FINAL ANALYSIS -- ONLY RUN ON GERM/NEURO/NDD/PSYCH/SOMA
#Create working directory
if ! [ -e ${WRKDIR}/analysis/perAnno_burden/signif_elements/all_merged/ ]; then
  mkdir ${WRKDIR}/analysis/perAnno_burden/signif_elements/all_merged/
fi
#Bedcluster across phenotypes with 50% reciprocal overlap required
#Min size = 5kb; applied *BEFORE* merging
#Max size = 500kb; applied *BEFORE* merging
minSize=5000
maxSize=500000
VF=E4
for annoSet in all_classes; do
  for CNV in DEL DUP; do
    if [ ${CNV} == "DEL" ]; then
      filt=haplosufficient
    else
      filt=noncoding
    fi
    echo -e "${annoSet}_${CNV}_${filt}"
    #Create master list of all significant elements
    for pheno in GERM NEURO NDD PSYCH SOMA; do
      fgrep -v "#" ${WRKDIR}/analysis/perAnno_burden/signif_elements/${pheno}/merged/${pheno}.${CNV}.${VF}.${filt}.bonf_sig_elements_merged.all_classes.bed | \
      awk -v OFS="\t" -v pheno=${pheno} -v CNV=${CNV} -v filt=${filt} -v minSize=${minSize} -v maxSize=${maxSize} \
      '{ if ($3-$2>=minSize && $3-$2<=maxSize) print $1, $2, $3, pheno"_"CNV"_"filt"_"NR, pheno"_"CNV"_"filt"_"NR, CNV }' 
    done | sort -Vk1,1 -k2,2n -k3,3n > \
    ${WRKDIR}/analysis/perAnno_burden/signif_elements/all_merged/${annoSet}_${CNV}_${VF}_${filt}.signif_loci.pre_merge.bed
    #Run bedtools intersect (50% recip)
    bedtools intersect -r -f 0.5 -wa -wb \
    -a ${WRKDIR}/analysis/perAnno_burden/signif_elements/all_merged/${annoSet}_${CNV}_${VF}_${filt}.signif_loci.pre_merge.bed \
    -b ${WRKDIR}/analysis/perAnno_burden/signif_elements/all_merged/${annoSet}_${CNV}_${VF}_${filt}.signif_loci.pre_merge.bed > \
    ${WRKDIR}/analysis/perAnno_burden/signif_elements/all_merged/${annoSet}_${CNV}_${VF}_${filt}.signif_loci.pre_merge.all_vs_all.bed
    #Run bedcluster
    cut -f4 ${WRKDIR}/analysis/perAnno_burden/signif_elements/all_merged/${annoSet}_${CNV}_${VF}_${filt}.signif_loci.pre_merge.bed | \
    sort | uniq > ${TMPDIR}/${annoSet}_${CNV}_${VF}_${filt}.input_element_IDs.tmp
    /data/talkowski/rlc47/code/svcf/scripts/bedcluster -p ${annoSet}_${CNV}_${VF}_${filt}_mergedSignificantLoci -m \
    ${TMPDIR}/${annoSet}_${CNV}_${VF}_${filt}.input_element_IDs.tmp \
    ${WRKDIR}/analysis/perAnno_burden/signif_elements/all_merged/${annoSet}_${CNV}_${VF}_${filt}.signif_loci.pre_merge.all_vs_all.bed \
    ${WRKDIR}/analysis/perAnno_burden/signif_elements/all_merged/${annoSet}_${CNV}_${VF}_${filt}.signif_loci.merged.bed
  done
done
#Create working directory for enhancer prioritized analysis
if ! [ -e ${WRKDIR}/analysis/perAnno_burden/signif_elements/enhancer_prioritization/ ]; then
  mkdir ${WRKDIR}/analysis/perAnno_burden/signif_elements/enhancer_prioritization/
fi
#Bedcluster across phenotypes with 50% reciprocal overlap required
#Min size = 5kb; applied *BEFORE* merging
#Max size = 500kb; applied *BEFORE* merging
minSize=5000
maxSize=500000
VF=E4
for annoSet in all_classes; do
  for CNV in DEL DUP; do
    if [ ${CNV} == "DEL" ]; then
      filt=haplosufficient
    else
      filt=noncoding
    fi
    echo -e "${annoSet}_${CNV}_${filt}"
    #Create master list of all significant elements
    for pheno in GERM NEURO NDD PSYCH SOMA; do
      fgrep -v "#" ${WRKDIR}/analysis/perAnno_burden/signif_elements/${pheno}/enhancer_prioritization/${pheno}.${CNV}.${VF}.${filt}.bonf_sig_elements_merged.enhancer_prioritization.bed | \
      awk -v OFS="\t" -v pheno=${pheno} -v CNV=${CNV} -v filt=${filt} -v minSize=${minSize} -v maxSize=${maxSize} \
      '{ if ($3-$2>=minSize && $3-$2<=maxSize) print $1, $2, $3, pheno"_"CNV"_"filt"_"NR, pheno"_"CNV"_"filt"_"NR, CNV }' 
    done | sort -Vk1,1 -k2,2n -k3,3n > \
    ${WRKDIR}/analysis/perAnno_burden/signif_elements/enhancer_prioritization/${annoSet}_${CNV}_${VF}_${filt}.signif_loci.pre_merge.bed
    #Run bedtools intersect (50% recip)
    bedtools intersect -r -f 0.5 -wa -wb \
    -a ${WRKDIR}/analysis/perAnno_burden/signif_elements/enhancer_prioritization/${annoSet}_${CNV}_${VF}_${filt}.signif_loci.pre_merge.bed \
    -b ${WRKDIR}/analysis/perAnno_burden/signif_elements/enhancer_prioritization/${annoSet}_${CNV}_${VF}_${filt}.signif_loci.pre_merge.bed > \
    ${WRKDIR}/analysis/perAnno_burden/signif_elements/enhancer_prioritization/${annoSet}_${CNV}_${VF}_${filt}.signif_loci.pre_merge.all_vs_all.bed
    #Run bedcluster
    cut -f4 ${WRKDIR}/analysis/perAnno_burden/signif_elements/enhancer_prioritization/${annoSet}_${CNV}_${VF}_${filt}.signif_loci.pre_merge.bed | \
    sort | uniq > ${TMPDIR}/${annoSet}_${CNV}_${VF}_${filt}.input_element_IDs.tmp
    /data/talkowski/rlc47/code/svcf/scripts/bedcluster -p ${annoSet}_${CNV}_${VF}_${filt}_mergedSignificantLoci -m \
    ${TMPDIR}/${annoSet}_${CNV}_${VF}_${filt}.input_element_IDs.tmp \
    ${WRKDIR}/analysis/perAnno_burden/signif_elements/enhancer_prioritization/${annoSet}_${CNV}_${VF}_${filt}.signif_loci.pre_merge.all_vs_all.bed \
    ${WRKDIR}/analysis/perAnno_burden/signif_elements/enhancer_prioritization/${annoSet}_${CNV}_${VF}_${filt}.signif_loci.merged.bed
  done
done
#Bedcluster across DEL/DUP with 50% reciprocal overlap required
# for annoSet in all_classes; do
#   for filt in haplosufficient noncoding; do
#     echo -e "${annoSet}_${filt}"
#     #Create master list of all significant elements
#     for CNV in DEL DUP; do
#       fgrep -v "#" ${WRKDIR}/analysis/perAnno_burden/signif_elements/all_merged/${annoSet}_${CNV}_${VF}_${filt}.signif_loci.merged.bed | \
#       awk -v OFS="\t" '{ print $1, $2, $3, $7, $7, "element" }' | uniq
#     done | sort -Vk1,1 -k2,2n -k3,3n -k4,4 | uniq > \
#     ${WRKDIR}/analysis/perAnno_burden/signif_elements/all_merged/${annoSet}_DELDUP_${VF}_${filt}.signif_loci.pre_merge.bed
#     #Run bedtools intersect (50% recip)
#     bedtools intersect -r -f 0.5 -wa -wb \
#     -a ${WRKDIR}/analysis/perAnno_burden/signif_elements/all_merged/${annoSet}_DELDUP_${VF}_${filt}.signif_loci.pre_merge.bed \
#     -b ${WRKDIR}/analysis/perAnno_burden/signif_elements/all_merged/${annoSet}_DELDUP_${VF}_${filt}.signif_loci.pre_merge.bed > \
#     ${WRKDIR}/analysis/perAnno_burden/signif_elements/all_merged/${annoSet}_DELDUP_${VF}_${filt}.signif_loci.pre_merge.all_vs_all.bed
#     #Run bedcluster
#     cut -f4 ${WRKDIR}/analysis/perAnno_burden/signif_elements/all_merged/${annoSet}_DELDUP_${VF}_${filt}.signif_loci.pre_merge.all_vs_all.bed | \
#     sort | uniq > ${TMPDIR}/${annoSet}_DELDUP_${VF}_${filt}.input_element_IDs.tmp
#     /data/talkowski/rlc47/code/svcf/scripts/bedcluster -p ${annoSet}_DELDUP_${VF}_${filt}_mergedSignificantLoci -m \
#     ${TMPDIR}/${annoSet}_DELDUP_${VF}_${filt}.input_element_IDs.tmp \
#     ${WRKDIR}/analysis/perAnno_burden/signif_elements/all_merged/${annoSet}_DELDUP_${VF}_${filt}.signif_loci.pre_merge.all_vs_all.bed \
#     ${WRKDIR}/analysis/perAnno_burden/signif_elements/all_merged/${annoSet}_DELDUP_${VF}_${filt}.signif_loci.merged.bed
#   done
# done 
#< <( cut -f1 ${WRKDIR}/bin/rCNVmap/misc/OrganGroup_Consolidation_NoncodingAnnotation_Linkers.list | \
#                  sort | uniq | cat <( echo -e "all_classes\ntissue_agnostic" ) - )
#Bedcluster for haplosufficient DEL and noncoding DUP (analysis for paper)
for annoSet in all_classes; do
  echo -e "${annoSet}"
  #Create master list of all significant elements
  cat <( fgrep -v "#" ${WRKDIR}/analysis/perAnno_burden/signif_elements/enhancer_prioritization/${annoSet}_DEL_${VF}_haplosufficient.signif_loci.merged.bed | \
          awk -v OFS="\t" '{ print $1, $2, $3, $7, $7, "element" }' | uniq ) \
      <( fgrep -v "#" ${WRKDIR}/analysis/perAnno_burden/signif_elements/enhancer_prioritization/${annoSet}_DUP_${VF}_noncoding.signif_loci.merged.bed | \
          awk -v OFS="\t" '{ print $1, $2, $3, $7, $7, "element" }' | uniq ) | \
      sort -Vk1,1 -k2,2n -k3,3n -k4,4 | uniq > \
  ${WRKDIR}/analysis/perAnno_burden/signif_elements/enhancer_prioritization/${annoSet}_haplosuffDELnoncodingDUP_${VF}.signif_loci.pre_merge.bed
  #Run bedtools intersect (50% recip)
  bedtools intersect -r -f 0.5 -wa -wb \
  -a ${WRKDIR}/analysis/perAnno_burden/signif_elements/enhancer_prioritization/${annoSet}_haplosuffDELnoncodingDUP_${VF}.signif_loci.pre_merge.bed \
  -b ${WRKDIR}/analysis/perAnno_burden/signif_elements/enhancer_prioritization/${annoSet}_haplosuffDELnoncodingDUP_${VF}.signif_loci.pre_merge.bed > \
  ${WRKDIR}/analysis/perAnno_burden/signif_elements/enhancer_prioritization/${annoSet}_haplosuffDELnoncodingDUP_${VF}.signif_loci.pre_merge.all_vs_all.bed
  #Run bedcluster
  cut -f4 ${WRKDIR}/analysis/perAnno_burden/signif_elements/enhancer_prioritization/${annoSet}_haplosuffDELnoncodingDUP_${VF}.signif_loci.pre_merge.all_vs_all.bed | \
  sort | uniq > ${TMPDIR}/${annoSet}_haplosuffDELnoncodingDUP_${VF}.input_element_IDs.tmp
  /data/talkowski/rlc47/code/svcf/scripts/bedcluster -p ${annoSet}_haplosuffDELnoncodingDUP_${VF}_mergedSignificantLoci -m \
  ${TMPDIR}/${annoSet}_haplosuffDELnoncodingDUP_${VF}.input_element_IDs.tmp \
  ${WRKDIR}/analysis/perAnno_burden/signif_elements/enhancer_prioritization/${annoSet}_haplosuffDELnoncodingDUP_${VF}.signif_loci.pre_merge.all_vs_all.bed \
  ${WRKDIR}/analysis/perAnno_burden/signif_elements/enhancer_prioritization/${annoSet}_haplosuffDELnoncodingDUP_${VF}.signif_loci.merged.bed
done
#Bedcluster for haplosufficient DEL and noncoding DUP (analysis for paper) - enhancer prioritization
for annoSet in all_classes; do
  echo -e "${annoSet}"
  #Create master list of all significant elements
  cat <( fgrep -v "#" ${WRKDIR}/analysis/perAnno_burden/signif_elements/all_merged/${annoSet}_DEL_${VF}_haplosufficient.signif_loci.merged.bed | \
          awk -v OFS="\t" '{ print $1, $2, $3, $7, $7, "element" }' | uniq ) \
      <( fgrep -v "#" ${WRKDIR}/analysis/perAnno_burden/signif_elements/all_merged/${annoSet}_DUP_${VF}_noncoding.signif_loci.merged.bed | \
          awk -v OFS="\t" '{ print $1, $2, $3, $7, $7, "element" }' | uniq ) | \
      sort -Vk1,1 -k2,2n -k3,3n -k4,4 | uniq > \
  ${WRKDIR}/analysis/perAnno_burden/signif_elements/all_merged/${annoSet}_haplosuffDELnoncodingDUP_${VF}.signif_loci.pre_merge.bed
  #Run bedtools intersect (50% recip)
  bedtools intersect -r -f 0.5 -wa -wb \
  -a ${WRKDIR}/analysis/perAnno_burden/signif_elements/all_merged/${annoSet}_haplosuffDELnoncodingDUP_${VF}.signif_loci.pre_merge.bed \
  -b ${WRKDIR}/analysis/perAnno_burden/signif_elements/all_merged/${annoSet}_haplosuffDELnoncodingDUP_${VF}.signif_loci.pre_merge.bed > \
  ${WRKDIR}/analysis/perAnno_burden/signif_elements/all_merged/${annoSet}_haplosuffDELnoncodingDUP_${VF}.signif_loci.pre_merge.all_vs_all.bed
  #Run bedcluster
  cut -f4 ${WRKDIR}/analysis/perAnno_burden/signif_elements/all_merged/${annoSet}_haplosuffDELnoncodingDUP_${VF}.signif_loci.pre_merge.all_vs_all.bed | \
  sort | uniq > ${TMPDIR}/${annoSet}_haplosuffDELnoncodingDUP_${VF}.input_element_IDs.tmp
  /data/talkowski/rlc47/code/svcf/scripts/bedcluster -p ${annoSet}_haplosuffDELnoncodingDUP_${VF}_mergedSignificantLoci -m \
  ${TMPDIR}/${annoSet}_haplosuffDELnoncodingDUP_${VF}.input_element_IDs.tmp \
  ${WRKDIR}/analysis/perAnno_burden/signif_elements/all_merged/${annoSet}_haplosuffDELnoncodingDUP_${VF}.signif_loci.pre_merge.all_vs_all.bed \
  ${WRKDIR}/analysis/perAnno_burden/signif_elements/all_merged/${annoSet}_haplosuffDELnoncodingDUP_${VF}.signif_loci.merged.bed
done
#FILTER FINAL LOCI
#If two elements overlap, keep the smaller of the two
#Remove any elements overlapping probe deserts
VF=E4
for annoSet in all_classes; do
  echo -e "${annoSet}"
  #First, run overlap
  bedtools intersect -wa -wb \
  -a <( cut -f1-3,7 ${WRKDIR}/analysis/perAnno_burden/signif_elements/all_merged/${annoSet}_haplosuffDELnoncodingDUP_${VF}.signif_loci.merged.bed ) \
  -b <( cut -f1-3,7 ${WRKDIR}/analysis/perAnno_burden/signif_elements/all_merged/${annoSet}_haplosuffDELnoncodingDUP_${VF}.signif_loci.merged.bed ) > \
  ${TMPDIR}/all_overlaps.bed
  #Second, get list of elements that don't overlap a different element
  cut -f4 ${TMPDIR}/all_overlaps.bed | sort -Vk1,1 | uniq -c | \
  awk -v OFS="\t" '{ if ($1==1) print $2 }' > \
  ${TMPDIR}/elements_to_keep.IDs.list
  #Third, iterate over all remaining elements and only keep the smallest overlapping element
  # among all possible overlapping elements per element
  while read ID; do
    awk -v ID=${ID} -v OFS="\t" '{ if ($4==ID || $8==ID) print $4, $3-$2"\n"$8, $7-$6 }' \
    ${TMPDIR}/all_overlaps.bed | sort -nk2,2 | head -n1 | cut -f1
  done < <( cut -f4 ${TMPDIR}/all_overlaps.bed | sort -Vk1,1 | uniq | \
            fgrep -wvf ${TMPDIR}/elements_to_keep.IDs.list ) | \
  sort -Vk1,1 | uniq >> ${TMPDIR}/elements_to_keep.IDs.list
  #Finally, get those IDs from the original bed file, remove those overlapping probe deserts, and write to file
  fgrep -wf ${TMPDIR}/elements_to_keep.IDs.list \
  ${WRKDIR}/analysis/perAnno_burden/signif_elements/all_merged/${annoSet}_haplosuffDELnoncodingDUP_${VF}.signif_loci.merged.bed | \
  cut -f1-3,7 | bedtools coverage -a ${WRKDIR}/data/misc/CTRL_probeDeserts.bed -b - | \
  awk -v OFS="\t" '{ if ($NF<=0.5) print $1, $2, $3, $4 }' | \
  sort -Vk1,1 -k2,2n -k3,3n -Vk4,4 | uniq > \
  ${WRKDIR}/analysis/perAnno_burden/signif_elements/all_merged/${annoSet}_haplosuffDELnoncodingDUP_${VF}.signif_loci.merged.filtered.bed
done

#FILTER FINAL LOCI - enhancer priotization
#If two elements overlap, keep the smaller of the two
#Remove any elements overlapping probe deserts
VF=E4
for annoSet in all_classes; do
  echo -e "${annoSet}"
  #First, run overlap
  bedtools intersect -wa -wb \
  -a <( cut -f1-3,7 ${WRKDIR}/analysis/perAnno_burden/signif_elements/enhancer_prioritization/${annoSet}_haplosuffDELnoncodingDUP_${VF}.signif_loci.merged.bed ) \
  -b <( cut -f1-3,7 ${WRKDIR}/analysis/perAnno_burden/signif_elements/enhancer_prioritization/${annoSet}_haplosuffDELnoncodingDUP_${VF}.signif_loci.merged.bed ) > \
  ${TMPDIR}/all_overlaps.bed
  #Second, get list of elements that don't overlap a different element
  cut -f4 ${TMPDIR}/all_overlaps.bed | sort -Vk1,1 | uniq -c | \
  awk -v OFS="\t" '{ if ($1==1) print $2 }' > \
  ${TMPDIR}/elements_to_keep.IDs.list
  #Third, iterate over all remaining elements and only keep the smallest overlapping element
  # among all possible overlapping elements per element
  while read ID; do
    awk -v ID=${ID} -v OFS="\t" '{ if ($4==ID || $8==ID) print $4, $3-$2"\n"$8, $7-$6 }' \
    ${TMPDIR}/all_overlaps.bed | sort -nk2,2 | head -n1 | cut -f1
  done < <( cut -f4 ${TMPDIR}/all_overlaps.bed | sort -Vk1,1 | uniq | \
            fgrep -wvf ${TMPDIR}/elements_to_keep.IDs.list ) | \
  sort -Vk1,1 | uniq >> ${TMPDIR}/elements_to_keep.IDs.list
  #Finally, get those IDs from the original bed file, remove those overlapping probe deserts, and write to file
  fgrep -wf ${TMPDIR}/elements_to_keep.IDs.list \
  ${WRKDIR}/analysis/perAnno_burden/signif_elements/enhancer_prioritization/${annoSet}_haplosuffDELnoncodingDUP_${VF}.signif_loci.merged.bed | \
  cut -f1-3,7 | bedtools coverage -a ${WRKDIR}/data/misc/CTRL_probeDeserts.bed -b - | \
  awk -v OFS="\t" '{ if ($NF<=0.5) print $1, $2, $3, $4 }' | \
  sort -Vk1,1 -k2,2n -k3,3n -Vk4,4 | uniq > \
  ${WRKDIR}/analysis/perAnno_burden/signif_elements/enhancer_prioritization/${annoSet}_haplosuffDELnoncodingDUP_${VF}.signif_loci.merged.filtered.bed
done


#Split final clustered loci by phenotype
#NOTE: UPDATED FOR FINAL ANALYSIS -- ONLY RUN ON GERM/NEURO/NDD/PSYCH/SOMA
#Create output directory
if ! [ -e ${WRKDIR}/analysis/perAnno_burden/signif_elements/all_merged/final_loci ]; then
  mkdir ${WRKDIR}/analysis/perAnno_burden/signif_elements/all_merged/final_loci
fi
for pheno in GERM NEURO NDD PSYCH SOMA; do
  echo ${pheno}
  if [ -e ${WRKDIR}/analysis/perAnno_burden/signif_elements/all_merged/final_loci/${pheno} ]; then
    rm -rf ${WRKDIR}/analysis/perAnno_burden/signif_elements/all_merged/final_loci/${pheno}
  fi
  mkdir ${WRKDIR}/analysis/perAnno_burden/signif_elements/all_merged/final_loci/${pheno}
  for annoSet in all_classes; do
    #Haplosuff DEL
    bedtools intersect -f 0.5 -a ${WRKDIR}/analysis/perAnno_burden/signif_elements/all_merged/${annoSet}_haplosuffDELnoncodingDUP_${VF}.signif_loci.merged.filtered.bed \
    -b ${WRKDIR}/analysis/perAnno_burden/signif_elements/${pheno}/merged/${pheno}.DEL.${VF}.haplosufficient.bonf_sig_elements_merged.${annoSet}.bed | \
    sort -Vk1,1 -k2,2n -k3,3n -Vk4,4 | uniq > \
    ${WRKDIR}/analysis/perAnno_burden/signif_elements/all_merged/final_loci/${pheno}/${pheno}_DEL_${VF}.final_merged_loci.${annoSet}.bed
    #Noncoding DUP
    bedtools intersect -f 0.5 -a ${WRKDIR}/analysis/perAnno_burden/signif_elements/all_merged/${annoSet}_haplosuffDELnoncodingDUP_${VF}.signif_loci.merged.filtered.bed \
    -b ${WRKDIR}/analysis/perAnno_burden/signif_elements/${pheno}/merged/${pheno}.DUP.${VF}.noncoding.bonf_sig_elements_merged.${annoSet}.bed | \
    sort -Vk1,1 -k2,2n -k3,3n -Vk4,4 | uniq > \
    ${WRKDIR}/analysis/perAnno_burden/signif_elements/all_merged/final_loci/${pheno}/${pheno}_DUP_${VF}.final_merged_loci.${annoSet}.bed
  done
done
#NOTE: UPDATED FOR FINAL ANALYSIS -- ONLY RUN ON GERM/NEURO/NDD/PSYCH/SOMA
#Create output directory - enhancer prioritization
if ! [ -e ${WRKDIR}/analysis/perAnno_burden/signif_elements/enhancer_prioritization/final_loci ]; then
  mkdir ${WRKDIR}/analysis/perAnno_burden/signif_elements/enhancer_prioritization/final_loci
fi
for pheno in GERM NEURO NDD PSYCH SOMA; do
  echo ${pheno}
  if [ -e ${WRKDIR}/analysis/perAnno_burden/signif_elements/enhancer_prioritization/final_loci/${pheno} ]; then
    rm -rf ${WRKDIR}/analysis/perAnno_burden/signif_elements/enhancer_prioritization/final_loci/${pheno}
  fi
  mkdir ${WRKDIR}/analysis/perAnno_burden/signif_elements/enhancer_prioritization/final_loci/${pheno}
  for annoSet in all_classes; do
    #Haplosuff DEL
    bedtools intersect -f 0.5 -a ${WRKDIR}/analysis/perAnno_burden/signif_elements/enhancer_prioritization/${annoSet}_haplosuffDELnoncodingDUP_${VF}.signif_loci.merged.filtered.bed \
    -b ${WRKDIR}/analysis/perAnno_burden/signif_elements/${pheno}/merged/${pheno}.DEL.${VF}.haplosufficient.bonf_sig_elements_merged.${annoSet}.bed | \
    sort -Vk1,1 -k2,2n -k3,3n -Vk4,4 | uniq > \
    ${WRKDIR}/analysis/perAnno_burden/signif_elements/enhancer_prioritization/final_loci/${pheno}/${pheno}_DEL_${VF}.final_merged_loci.${annoSet}.bed
    #Noncoding DUP
    bedtools intersect -f 0.5 -a ${WRKDIR}/analysis/perAnno_burden/signif_elements/enhancer_prioritization/${annoSet}_haplosuffDELnoncodingDUP_${VF}.signif_loci.merged.filtered.bed \
    -b ${WRKDIR}/analysis/perAnno_burden/signif_elements/${pheno}/merged/${pheno}.DUP.${VF}.noncoding.bonf_sig_elements_merged.${annoSet}.bed | \
    sort -Vk1,1 -k2,2n -k3,3n -Vk4,4 | uniq > \
    ${WRKDIR}/analysis/perAnno_burden/signif_elements/enhancer_prioritization/final_loci/${pheno}/${pheno}_DUP_${VF}.final_merged_loci.${annoSet}.bed
  done
done

#####Calculate pairwise correlations for all elements
VF=E4
for pheno in GERM; do
  zcat ${WRKDIR}/data/CNV/CNV_MASTER/${pheno}/${pheno}.DEL.${VF}.GRCh37.haplosufficient_largeSegmentExcluded_sigGeneExcluded.bed.gz
  zcat ${WRKDIR}/data/CNV/CNV_MASTER/${pheno}/${pheno}.DUP.${VF}.GRCh37.noncoding_largeSegmentExcluded.bed.gz
done | fgrep -v "#" | sort -Vk1,1 -k2,2n -k3,3n | cut -f1-4 | uniq > \
${TMPDIR}/GERM_CNVs_pooled.bed
# zcat ${WRKDIR}/analysis/perAnno_burden/cleaned_noncoding_loci.wAnnotations.forManualCuration.txt.gz | \
# cut -f1-4 | sed '1d' | sort -Vk1,1 -k2,2n -k3,3n | uniq > ${TMPDIR}/loci_for_jaccard.bed
# bsub -q normal -sla miket_sc -J noncoding_CNVjaccard -u nobody \
# "${WRKDIR}/bin/rCNVmap/analysis_scripts/calc_CNV_correlation_between_locusPairs.sh \
#  ${WRKDIR}/analysis/perAnno_burden/signif_elements/all_merged/all_classes_haplosuffDELnoncodingDUP_E4.signif_loci.merged.filtered.bed \
#  ${TMPDIR}/GERM_CNVs_pooled.bed \
#  ${WRKDIR}/analysis/perAnno_burden/cleaned_noncoding_loci.jaccard_matrix.txt"
bsub -q normal -sla miket_sc -J noncoding_CNVjaccard -u nobody \
"${WRKDIR}/bin/rCNVmap/analysis_scripts/calc_CNV_correlation_between_locusPairs.sh \
 ${WRKDIR}/analysis/perAnno_burden/signif_elements/enhancer_prioritization/all_classes_haplosuffDELnoncodingDUP_E4.signif_loci.merged.filtered.bed \
 ${TMPDIR}/GERM_CNVs_pooled.bed \
 ${WRKDIR}/analysis/perAnno_burden/cleaned_noncoding_loci.jaccard_matrix.txt"

#####Cluster significant elements into regulatory blocks
#Note: must have clustered element IDs locally and uploaded to cluster here:
# ${WRKDIR}/analysis/perAnno_burden/clustered_elements_regBlocks.list
annoSet=all_classes; VF=E4
while read eIDs; do
  for wrapper in 1; do
    #Get coordinates of all contributing loci
    echo ${eIDs} | sed 's/\;/\n/g' | fgrep -wf - \
    ${WRKDIR}/analysis/perAnno_burden/signif_elements/all_merged/${annoSet}_haplosuffDELnoncodingDUP_${VF}.signif_loci.merged.filtered.bed > \
    ${TMPDIR}/coordinates.bed
    #Print coordinates of merged regulatory block
    head -n1 ${TMPDIR}/coordinates.bed | cut -f1
    cut -f2 ${TMPDIR}/coordinates.bed | sort -nk1,1 | head -n1
    cut -f3 ${TMPDIR}/coordinates.bed | sort -nrk1,1 | head -n1
    #Print remaining info
    echo "SignifRegBlock"
    awk -v OFS="_" '{ print $1, $2, $3 }' ${TMPDIR}/coordinates.bed | paste -s -d\;
    echo ${eIDs}
  done | paste -s
done < ${WRKDIR}/analysis/perAnno_burden/clustered_elements_regBlocks.list | \
sort -Vk1,1 -k2,2n -k3,3n | awk -v OFS="\t" '{ print $1, $2, $3, $4"_"NR, $5, $6 }' > \
${WRKDIR}/analysis/perAnno_burden/signifRegulatoryBlocks.final.bed
#####Cluster significant elements into regulatory blocks - enhancer prioritization
#Note: must have clustered element IDs locally and uploaded to cluster here:
# ${WRKDIR}/analysis/perAnno_burden/clustered_elements_regBlocks.list
annoSet=all_classes; VF=E4
while read eIDs; do
  for wrapper in 1; do
    #Get coordinates of all contributing loci
    echo ${eIDs} | sed 's/\;/\n/g' | fgrep -wf - \
    ${WRKDIR}/analysis/perAnno_burden/signif_elements/enhancer_prioritization/${annoSet}_haplosuffDELnoncodingDUP_${VF}.signif_loci.merged.filtered.bed > \
    ${TMPDIR}/coordinates.bed
    #Print coordinates of merged regulatory block
    head -n1 ${TMPDIR}/coordinates.bed | cut -f1
    cut -f2 ${TMPDIR}/coordinates.bed | sort -nk1,1 | head -n1
    cut -f3 ${TMPDIR}/coordinates.bed | sort -nrk1,1 | head -n1
    #Print remaining info
    echo "SignifRegBlock"
    awk -v OFS="_" '{ print $1, $2, $3 }' ${TMPDIR}/coordinates.bed | paste -s -d\;
    echo ${eIDs}
  done | paste -s
done < ${WRKDIR}/analysis/perAnno_burden/clustered_elements_regBlocks.list | \
sort -Vk1,1 -k2,2n -k3,3n | awk -v OFS="\t" '{ print $1, $2, $3, $4"_"NR, $5, $6 }' > \
${WRKDIR}/analysis/perAnno_burden/signifRegulatoryBlocks.final.bed


#####NOTE: MANUALLY EVALUATE REG BLOCKS WITH SIGNIFICANT GENES
#####MANUALLY DECIDE WHICH TO KEEP AS GENES OR REG BLOCKS
#Step 1: get overlapping genes & reg blocks
cut -f1-3 ${WRKDIR}/analysis/perAnno_burden/signifRegulatoryBlocks.final.bed | \
bedtools intersect -wa -wb -a - -b \
<( fgrep -wf ${WRKDIR}/analysis/perGene_burden/signif_genes/merged/MasterPhenoGroups_DELDUPUnion_E4_exonic.geneScore_FINAL_sig.genes.list \
    ${WRKDIR}/data/master_annotations/gencode/gencode.v19.exons.protein_coding.bed ) | cut -f1-3,7 | sort -Vk1,1 -k2,2n -k3,3n -k4,4 | uniq
#Step 2: get gene set annotations for these genes
while read gene; do
  echo -e "\n\n${gene}"
  fgrep -w ${gene} ${WRKDIR}/data/master_annotations/genelists/* | \
  awk -v FS="/" '{ print $NF }' | sed 's/\.genes/\t/g' | cut -f1 | grep -ve 'GTEx\|Expr\|Gencode'
done < <( cut -f1-3 ${WRKDIR}/analysis/perAnno_burden/signifRegulatoryBlocks.final.bed | \
          bedtools intersect -wa -wb -a - -b \
          <( fgrep -wf ${WRKDIR}/analysis/perGene_burden/signif_genes/merged/MasterPhenoGroups_DELDUPUnion_E4_exonic.geneScore_FINAL_sig.genes.list \
              ${WRKDIR}/data/master_annotations/gencode/gencode.v19.exons.protein_coding.bed ) | cut -f1-3,7 | sort -Vk1,1 -k2,2n -k3,3n -k4,4 | uniq | \
          cut -f4 | sort | uniq )
#Step 3a: exclude reg blocks where manual analysis prioritizes coding effect
#Genes to exclude: ADAMTS18, CHL1, DOCK8, FBXL4, GBE1, ISPD, KCNV2, KIAA0020, MAD1L1, NKAIN2, SAMSN1, SLC1A1, SLCO1B1, VIPR2, SMYD3, CD82
echo -e "ADAMTS18\nCHL1\nDOCK8\nFBXL4\nGBE1\nISPD\nKCNV2\nKIAA0020\nMAD1L1\nNKAIN2\nSAMSN1\nSLC1A1\nSLCO1B1\nVIPR2\nSMYD3\nCD82" | \
fgrep -wf - ${WRKDIR}/data/master_annotations/gencode/gencode.v19.exons.protein_coding.bed | \
bedtools intersect -v -b - \
-a ${WRKDIR}/analysis/perAnno_burden/signifRegulatoryBlocks.final.bed > \
${WRKDIR}/analysis/perAnno_burden/signifRegulatoryBlocks.final.bed2
mv ${WRKDIR}/analysis/perAnno_burden/signifRegulatoryBlocks.final.bed2 \
${WRKDIR}/analysis/perAnno_burden/signifRegulatoryBlocks.final.bed


#####Calculate final p-values and ORs per regulatory block separately for dels and dups
#Final analysis: subset of all combinations
for VF in E4; do
  while read CNV filt; do
    bsub -q short -sla miket_sc -J regBlock_ORs_${CNV} -u nobody \
    "${WRKDIR}/bin/rCNVmap/analysis_scripts/get_ORs_sigRegBlocks.sh ${VF} ${filt} ${CNV}"
  done < <( echo -e "DEL\thaplosufficient\nDUP\tnoncoding" )
done


#####Get median size of final blocks
awk '{ print $3-$2 }' ${WRKDIR}/analysis/perAnno_burden/signifRegulatoryBlocks.final.bed | \
sort -nk1,1 | perl -e '$d=.5;@l=<>;print $l[int($d*$#l)]'



# #####Get counts of significant loci by phenotype after merging
# #Merged across all annotations
# VF=E4
# annoSet=all_classes
# while read pheno; do
#   for dummy in 1; do
#     echo ${pheno}
#     for CNV in DEL DUP; do
#       fgrep -v "#" ${WRKDIR}/analysis/perAnno_burden/signif_elements/all_merged/final_loci/${pheno}/${pheno}_${CNV}_${VF}.final_merged_loci.all_classes.bed | wc -l
#     done
#   done | paste -s
# done < <( fgrep -v "#" ${WRKDIR}/bin/rCNVmap/misc/analysis_group_HPO_mappings.list | \
#           cut -f1 | fgrep -v CTRL )
# #Specific to cancer (i.e. not observed in any germline group)
# while read pheno; do
#   for CNV in DEL DUP; do
#     fgrep -v "#" ${WRKDIR}/analysis/perAnno_burden/signif_elements/all_merged/final_loci/${pheno}/${pheno}_${CNV}_${VF}.final_merged_loci.all_classes.bed | \
#     cut -f4
#   done
# done < <( fgrep -v "#" ${WRKDIR}/bin/rCNVmap/misc/analysis_group_HPO_mappings.list | \
#           awk '{ if ($2=="GERM") print $1 }' ) | sort | uniq | \
# fgrep -wvf - \
# ${WRKDIR}/analysis/perAnno_burden/signif_elements/all_merged/${annoSet}_haplosuffDELnoncodingDUP_${VF}.signif_loci.merged.filtered.bed | wc -l
# #Count of del-only, del+dup, and dup-only
# VF=E4
# while read pheno; do
#   for dummy in 1; do
#     echo ${pheno}
#     #DEL-only
#     fgrep -v "#" ${WRKDIR}/analysis/perAnno_burden/signif_elements/all_merged/final_loci/${pheno}/${pheno}_DUP_${VF}.final_merged_loci.all_classes.bed | \
#     cut -f4 | fgrep -wvf - \
#     ${WRKDIR}/analysis/perAnno_burden/signif_elements/all_merged/final_loci/${pheno}/${pheno}_DEL_${VF}.final_merged_loci.all_classes.bed | wc -l
#     #DEL+DUP
#     fgrep -v "#" ${WRKDIR}/analysis/perAnno_burden/signif_elements/all_merged/final_loci/${pheno}/${pheno}_DUP_${VF}.final_merged_loci.all_classes.bed | \
#     cut -f4 | fgrep -wf - \
#     ${WRKDIR}/analysis/perAnno_burden/signif_elements/all_merged/final_loci/${pheno}/${pheno}_DEL_${VF}.final_merged_loci.all_classes.bed | wc -l
#     #DUP-only
#     fgrep -v "#" ${WRKDIR}/analysis/perAnno_burden/signif_elements/all_merged/final_loci/${pheno}/${pheno}_DEL_${VF}.final_merged_loci.all_classes.bed | \
#     cut -f4 | fgrep -wvf - \
#     ${WRKDIR}/analysis/perAnno_burden/signif_elements/all_merged/final_loci/${pheno}/${pheno}_DUP_${VF}.final_merged_loci.all_classes.bed | wc -l
#   done | paste -s
# done < <( fgrep -v "#" ${WRKDIR}/bin/rCNVmap/misc/analysis_group_HPO_mappings.list | \
#           cut -f1 | fgrep -v CTRL )

#Get significant germline elements within 1Mb of high-confidence autosomal disease genes
VF=E4
dist=1000000
bedtools intersect -wa -u -b ${WRKDIR}/analysis/perAnno_burden/signifRegulatoryBlocks.final.bed \
-a <( fgrep -wf ${WRKDIR}/data/master_annotations/genelists/DDD_2017.genes.list \
      ${WRKDIR}/data/master_annotations/gencode/gencode.v19.gene_boundaries.all.bed | \
      awk -v OFS="\t" -v dist=${dist} '{ print $1, $2-dist, $3+dist, $4 }' | \
      awk -v OFS="\t" '{ if ($2<1) $2=1; print $0 }' | grep -e '^[0-9]' | grep -v '\-' )
# | \
# cut -f4 | sed 's/\-/\t/g' | cut -f1 | sort | uniq | fgrep -wf - \
# ${WRKDIR}/data/master_annotations/genelists/ExAC_haplosufficient.genes.list
# #Haplosufficient genes that appear in the above list because of coding effects (exclude): MEF2C
# #Get significant germline elements within 1Mb of rCNV-burdened genes that are also pLI-constrained
# for pheno in GERM NEURO SOMA NDD DD PSYCH SCZ; do
#   for CNV in DEL DUP; do
#     cat ${WRKDIR}/analysis/perGene_burden/signif_genes/merged/${pheno}_${CNV}_E4_exonic.geneScore_Bonferroni_sig.union.genes.list
#   done
# done | sort | uniq > ${TMPDIR}/GERM_all.genes.list
# for pheno in GERM NEURO NDD DD PSYCH SCZ SOMA; do
#   cat ${WRKDIR}/analysis/perAnno_burden/signif_elements/all_merged/final_loci/${pheno}/${pheno}_*_${VF}.final_merged_loci.all_classes.bed
# done | bedtools intersect -wa -u -b - \
# -a <( fgrep -wf ${TMPDIR}/GERM_all.genes.list \
#       ${WRKDIR}/data/master_annotations/gencode/gencode.v19.gene_boundaries.all.bed | \
#       awk -v OFS="\t" -v dist=${dist} '{ print $1, $2-dist, $3+dist, $4 }' | \
#       awk -v OFS="\t" '{ if ($2<1) $2=1; print $0 }' | grep -e '^[0-9]' ) | \
# cut -f4 | sed 's/\-/\t/g' | cut -f1 | sort | uniq | fgrep -wf \
# ${WRKDIR}/data/master_annotations/genelists/ExAC_constrained.genes.list

# #Get significant cancer elements within 1Mb of high-confidence cancer driver genes
# VF=E4
# dist=1000000
# for pheno in CNCR; do
#   cat ${WRKDIR}/analysis/perAnno_burden/signif_elements/all_merged/final_loci/${pheno}/${pheno}_*_${VF}.final_merged_loci.all_classes.bed
# done | bedtools intersect -wa -u -b - \
# -a <( fgrep -wf ${WRKDIR}/data/master_annotations/genelists/COSMIC_all.genes.list \
#       ${WRKDIR}/data/master_annotations/gencode/gencode.v19.gene_boundaries.all.bed | \
#       awk -v OFS="\t" -v dist=${dist} '{ print $1, $2-dist, $3+dist, $4 }' | \
#       awk -v OFS="\t" '{ if ($2<1) $2=1; print $0 }' | grep -e '^[0-9]' ) | \
# cut -f4 | sed 's/\-/\t/g' | cut -f1 | sort | uniq | fgrep -wf - \
# ${WRKDIR}/data/master_annotations/genelists/ExAC_haplosufficient.genes.list
# #Haplosufficient genes that appear in the list because of coding effects (exclude): FHIT, PTPN13, RAD51B, TGFBR2


#Get genes with at least one noncoding significant regulatory element within 1Mb AND coding CNV hit AND ExAC constrained
VF=E4
dist=1000000
context=exonic
bedtools intersect -wa -u -b ${WRKDIR}/analysis/perAnno_burden/signifRegulatoryBlocks.final.bed \
-a <( cat ${WRKDIR}/data/master_annotations/genelists/ExAC_*constrained*.genes.list | fgrep -wf - \
      ${WRKDIR}/data/master_annotations/gencode/gencode.v19.gene_boundaries.all.bed | \
      awk -v OFS="\t" -v dist=${dist} '{ print $1, $2-dist, $3+dist, $4 }' | \
      awk -v OFS="\t" '{ if ($2<1) $2=1; print $0 }' | grep -e '^[0-9]' | grep -v '\-' | \
      fgrep -wf ${WRKDIR}/analysis/perGene_burden/signif_genes/merged/MasterPhenoGroups_DELDUPUnion_${VF}_${context}.geneScore_FINAL_sig.genes.list )


#Get final regulatory blocks shared with old cancer regulatory blocks
dist=1000000
for CNV_GERM in DEL DUP; do
  for CNV_CNCR in DEL DUP; do
    echo -e "\n\n${CNV_GERM} in GERM and ${CNV_CNCR} in CNCR:"
    bedtools intersect -wa -u -a <( sed '1d' ${WRKDIR}/data/plot_data/suppTables/suppTables_5_6_${CNV_GERM}.txt | cut -f1-3 ) \
    -b ${WRKDIR}/analysis/perAnno_burden/signif_elements/all_merged/final_loci/CNCR/CNCR_${CNV_CNCR}_E4.final_merged_loci.all_classes.bed | \
    bedtools intersect -wa -u -b - \
    -a <( fgrep -wf ${WRKDIR}/data/master_annotations/genelists/*constrained*.genes.list \
      ${WRKDIR}/data/master_annotations/gencode/gencode.v19.gene_boundaries.all.bed | \
       cut -f2- -d\: | awk -v OFS="\t" -v dist=${dist} '{ print $1, $2-dist, $3+dist, $4 }' | \
      awk -v OFS="\t" '{ if ($2<1) $2=1; print $0 }' | grep -e '^[0-9]' | grep -v '\-' )
  done
done




#####Find reg blocks in the same TAD as at least one gene expressed in LCLs
for CNV in DEL DUP; do
  while read ID sites; do
    for wrapper in 1; do
      echo -e "${ID}\t${CNV}"
      #Check
      echo -e "${sites}" | sed -e 's/\_/\t/g' -e 's/\;/\n/g' | \
        bedtools intersect -u -b - \
        -a ${WRKDIR}/data/master_annotations/ | \
        cut -f4 | sort | uniq | wc -l
      done
      #De novo CNVs only
      for mem in probands siblings; do
        echo -e "${sites}" | sed -e 's/\_/\t/g' -e 's/\;/\n/g' | \
        bedtools intersect -u -b - \
        -a ${TMPDIR}/SSC_CNVs.p10E9.hg19.${mem}.${CNV}.bed | fgrep DeNovo | \
        cut -f4 | sort | uniq | wc -l
      done
    done | paste -s
  done < <( sed '1d' ${WRKDIR}/data/plot_data/suppTables/suppTables_5_6_${CNV}.txt | \
            cut -f4,5 )
done



