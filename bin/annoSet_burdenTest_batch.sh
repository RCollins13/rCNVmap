#!/usr/bin/env bash

##############################
#    Rare CNV Map Project    #
##############################

# Copyright (c) 2017 Ryan L. Collins
# Distributed under terms of the MIT License (see LICENSE)
# Contact: Ryan L. Collins <rlcollins@g.harvard.edu>
# Code development credits availble on GitHub

# Script to iterate over a list of noncoding annotation BED files and test for
# CNV burden from a specified set of CNVs in cases and controls

#Usage statement
usage(){
cat <<EOF
usage: annoSet_burdenTest_batch.sh [-h] [-N TIMES] [-x EXCLUDE] [-p PREFIX] [-o OUTDIR] [-f]
                                   CONTROLS CASES LIST GENOME

Script to test CNV burden at genome annotation sets in batch mode 

Positional arguments:
  CONTROLS   path to control CNV input file. Must have at least three columns: 
             chr, CNV start, CNV end
  CASES      path to case CNV input file. Must have at least three columns: 
             chr, CNV start, CNV end
  LIST       two-column, tab-delimmed list of annotations to test.
             First column: annotation name; second column: full path to annotation
  GENOME     BEDTools-style genome file (tab delimmed two-column file: chr, length)

Optional arguments:
  -h  HELP          Show this help message and exit
  -N  TIMES         Number of permutations to perform (default: 1,000)
  -x  EXCLUDE       BED-style intervals to exclude when simulating intervals
  -p  PREFIX        String to add to the front of all output files
  -o  OUTDIR        Output directory (default: current directory)
  -f  FORCE         Overwrite output even if file with same name exists
EOF
}

#Parse arguments
TIMES=1000
OUTDIR=`pwd`
EXCLUDE=0
PREFIX="annoSetTest"
FORCE=0
while getopts ":N:x:p:o:hf" opt; do
  case "$opt" in
    h)
      usage
      exit 0
      ;;
    N)
      TIMES=${OPTARG}
      ;;
    x)
      EXCLUDE=${OPTARG}
      ;;
    p)
      PREFIX=${OPTARG}
      ;;
    o)
      OUTDIR=${OPTARG}
      ;;
    f)
      FORCE=1
      ;;
  esac
done
shift $((${OPTIND} - 1))
CONTROLS=$1
CASES=$2
LIST=$3
GENOME=$4

###MUST ADD: #GET PATH TO RCNVMAP BIN SUBDIRECTORY
BIN=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

#Check for required input
if [ -z ${CONTROLS} ] || [ -z ${CASES} ] || [ -z ${LIST} ] || [ -z ${GENOME} ]; then
  usage
  exit 0
fi

#Attempts to create $OUTDIR if it doesn't exist
if ! [ -e ${OUTDIR} ]; then
  mkdir ${OUTDIR}
fi

#Exit if $OUTDIR doesn't exist
if ! [ -e ${OUTDIR} ]; then
  usage
  echo -e "\nERROR: OUTDIR DOES NOT EXIST"
  exit 0
fi

#Iterate over list of annotations and run burden tests
while read NAME ANNO; do
  if [ -e ${OUTDIR}/${PREFIX}.${NAME}.CNV_burden_results.txt ]; then
    if [ ${FORCE} -eq 0 ]; then
      echo "OUTPUT FILE FOR ${NAME} FOUND; SKIPPING"
    else
      echo "STARTING ${NAME}"
      ${BIN}/annoSet_permutation_test.sh -q -N ${TIMES} -x ${EXCLUDE} -L ${NAME} \
      -o ${OUTDIR}/${PREFIX}.${NAME}.CNV_burden_results.txt \
      ${CONTROLS} ${CASES} ${ANNO} ${GENOME}
    fi
  else
    echo "STARTING ${NAME}"
    ${BIN}/annoSet_permutation_test.sh -q -N ${TIMES} -x ${EXCLUDE} -L ${NAME} \
    -o ${OUTDIR}/${PREFIX}.${NAME}.CNV_burden_results.txt \
    ${CONTROLS} ${CASES} ${ANNO} ${GENOME}
  fi
done < ${LIST}
