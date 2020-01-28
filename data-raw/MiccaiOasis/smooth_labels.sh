#!/bin/bash -x

export TD=$(mktemp -d)
trap 'rm -rf $TD; exit 0' 0 1 2 3 14 15


export LABFILE=$1
export SURFFILE=${2}
export RESULT=${3}

FSDIR=${FREESURFER_HOME}/subjects/fsaverage

wb_command -label-export-table ${LABFILE} ${TD}/a
#sed -n '0~2!p' ${TD}/a > ${TD}/names # This isn't working
i=1
while read p; do
  if [ $((${i}%2)) -eq 1 ] ; then echo ${p} >> ${TD}/names; fi ; i=$((i + 1)) ;
done < ${TD}/a

function Smooth1()
{
    i=${1}
    METRICNAME=${TD}/${i}.func.gii
    echo $i $METRICNAME
    wb_command -gifti-label-to-roi ${LABFILE} ${METRICNAME} -key ${i}
    wb_command -metric-erode ${METRICNAME} ${SURFFILE} 2 ${METRICNAME}
    wb_command -metric-remove-islands ${SURFFILE} ${METRICNAME} ${METRICNAME}
    wb_command -metric-dilate ${METRICNAME} ${SURFFILE} 5 ${METRICNAME} # January 24, 2020: Probably need to use the "nearest" flag
}

#module load gnuparallel/20190122 # Can't seem to get a Mac version of gnuparallel

export -f Smooth1

#while read p; do Smooth1 ${p} ; done < ${TD}/names
for p in `seq 1 49`; do Smooth1 ${p} ; done

#cat ${TD}/names | parallel Smooth1... trouble installing gnuparallel
#m=$(cat ${TD}/names | parallel echo -n '\ -metric ${TD}/${p}.func.gii\ ')

m=""
for p in `seq 1 49`; do m=${m}"-metric ${TD}/${p}.func.gii "; done

wb_command -metric-merge ${TD}/multicol.func.gii ${m}

wb_command -metric-reduce ${TD}/multicol.func.gii MAX ${TD}/smooth.func.gii
wb_command -label-mask ${LABFILE} ${TD}/smooth.func.gii ${TD}/smooth.label.gii

wb_command -label-dilate ${TD}/smooth.label.gii ${SURFFILE} 5 ${TD}/dilate.label.gii
wb_command -label-erode ${TD}/dilate.label.gii ${SURFFILE} 5 ${RESULT}
