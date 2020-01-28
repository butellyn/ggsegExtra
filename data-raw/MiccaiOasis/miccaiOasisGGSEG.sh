OUTDIR=`pwd`
INDIR=`pwd`
SCRDIR=`pwd`


# Subset parcellation to only include cortical ROIs
fslmaths ${INDIR}/mniMICCAI_LabelsWithWM.nii.gz -thr 100 -uthr 207 ${INDIR}/mniMICCAI_LabelsCortical.nii.gz

# Try 0-indexing
fslmaths ${INDIR}/mniMICCAI_LabelsCortical.nii.gz -thr 99 -bin ${INDIR}/mniMICCAI_CorticalMask.nii.gz
fslmaths ${INDIR}/mniMICCAI_CorticalMask.nii.gz -mul 99 ${INDIR}/mniMICCAI_CorticalMask99.nii.gz
fslmaths ${INDIR}/mniMICCAI_LabelsCortical.nii.gz -sub ${INDIR}/mniMICCAI_CorticalMask99.nii.gz ${INDIR}/mniMICCAI_LabelsCortical0.nii.gz
fslmaths ${INDIR}/mniMICCAI_LabelsCortical0.nii.gz -kernel sphere 3.5 -dilD ${INDIR}/mniMICCAI_LabelsCortical0_dilated.nii.gz


# Project volume to surface (trying 0 indexing)
if [ ! -d ${OUTDIR}/output ]; then mkdir ${OUTDIR}/output; fi

mri_vol2surf --sd ${SUBJECTS_DIR} --src ${INDIR}/mniMICCAI_LabelsCortical0_dilated.nii.gz --mni152reg --out ${OUTDIR}/output/miccai_2012_surf_rh.mgh --hemi rh --projfrac 0.5

mri_vol2surf --sd ${SUBJECTS_DIR} --src ${INDIR}/mniMICCAI_LabelsCortical0_dilated.nii.gz --mni152reg --out ${OUTDIR}/output/miccai_2012_surf_lh.mgh --hemi lh --projfrac 0.5

# Create a color table. Run an R session in ${SUBJECTS_DIR}/fsaverage/mri
Rscript ${SCRDIR}/mic_ctab.R

# Create a series of individual label files
mkdir ${OUTDIR}/Labels
nums=`seq 1 108` # old: 100 207
for i in $nums ; do
	mri_vol2label --c ${OUTDIR}/output/miccai_2012_surf_rh.mgh --id ${i} --surf fsaverage rh --l ${OUTDIR}/Labels/rh_MIC_${i}.label ;
	mri_vol2label --c ${OUTDIR}/output/miccai_2012_surf_lh.mgh --id ${i} --surf fsaverage lh --l ${OUTDIR}/Labels/lh_MIC_${i}.label ;
done

# Create annotation files
surfids_L=`ls ${OUTDIR}/Labels/lh* | cut -d "_" -f 4 | cut -d "." -f 1`
LABS_L=""
for thisid in ${surfids_L}; do
  if [ $((${thisid}%2)) -eq 0 ] ; then
    LABS_L=${LABS_L}"--l ${OUTDIR}/Labels/lh_MIC_${thisid}.label ";
  fi
done

surfids_R=`ls ${OUTDIR}/Labels/rh* | cut -d "_" -f 4 | cut -d "." -f 1`
LABS_R=""
for thisid in ${surfids_R}; do
  if [ $((${thisid}%2)) -eq 1 ] ; then
    LABS_R=${LABS_R}"--l ${OUTDIR}/Labels/rh_MIC_${thisid}.label ";
  fi
done

# January 10, 2020: STUCK HERE
# With 0-indexing, I am getting many vertices that have more than one label... potentially all of them
# January 14, 2020: Now with background/unknown as 0, looks a bit better, but tons of right hemisphere ROIs are being found on left...
# January 16, 2020: Splitting the color lookup tables by right and left, and ignoring mapping of indices, all of the right
# labels are showing up on the right and all of the left on the left, but they still aren't mapping correctly. It does not
# seem like freesurfer respects indices when mapping labels to an image, and instead seems to go based on some order.
sudo mris_label2annot --sd ${SUBJECTS_DIR} --s fsaverage --ctab ${OUTDIR}/output/miccaiCtab_L.txt ${LABS_L} --h lh --a mic

sudo mris_label2annot --sd ${SUBJECTS_DIR} --s fsaverage --ctab ${OUTDIR}/output/miccaiCtab_R.txt ${LABS_R} --h rh --a mic

# Check how the surface looks - note lots of holes etc.
# Tons of holes, and labels don't line up. Ah well!
freeview --surface ${FREESURFER_HOME}/subjects/fsaverage/surf/rh.inflated:annot=${FREESURFER_HOME}/subjects/fsaverage/label/rh.mic.annot --surface ${FREESURFER_HOME}/subjects/fsaverage/surf/lh.inflated:annot=${FREESURFER_HOME}/subjects/fsaverage/label/lh.mic.annot

# Create gifti surface and labels on surface files
FSDIR=${FREESURFER_HOME}/subjects/fsaverage

# Gifti inflated surface
sudo mris_convert ${FSDIR}/surf/rh.inflated ${FSDIR}/inflated_rh.surf.gii
sudo mris_convert ${FSDIR}/surf/lh.inflated ${FSDIR}/inflated_lh.surf.gii

# Gifti Miccai labels surface
sudo mris_convert --annot ${FSDIR}/label/rh.mic.annot ${FSDIR}/surf/rh.inflated ${FSDIR}/fsaverage_mic_rh.label.gii
sudo mris_convert --annot ${FSDIR}/label/lh.mic.annot ${FSDIR}/surf/lh.inflated ${FSDIR}/fsaverage_mic_lh.label.gii

# Fill and smooth
${SCRDIR}/smooth_labels.sh ${FSDIR}/fsaverage_mic_rh.label.gii ${FSDIR}/inflated_rh.surf.gii ${OUTDIR}/output/fsaverage_mic_rh.smooth.label.gii
${SCRDIR}/smooth_labels.sh ${FSDIR}/fsaverage_mic_lh.label.gii ${FSDIR}/inflated_lh.surf.gii ${OUTDIR}/output/fsaverage_mic_lh.smooth.label.gii

sudo mv ${OUTDIR}/output/fsaverage_mic_rh.smooth.label.gii ${FSDIR}/fsaverage_mic_rh.smooth.label.gii
sudo mv ${OUTDIR}/output/fsaverage_mic_lh.smooth.label.gii ${FSDIR}/fsaverage_mic_lh.smooth.label.gii


# Back to viewing with freesurfer
sudo mris_convert --annot ${FSDIR}/fsaverage_mic_rh.smooth.label.gii ${FSDIR}/inflated_rh.surf.gii ${FSDIR}/rh.mic.smooth.annot
sudo mris_convert --annot ${FSDIR}/fsaverage_mic_lh.smooth.label.gii ${FSDIR}/inflated_lh.surf.gii ${FSDIR}/lh.mic.smooth.annot

#freeview --surface ${FREESURFER_HOME}/subjects/fsaverage/surf/rh.inflated:annot=${FREESURFER_HOME}/subjects/fsaverage/label/rh.mic.smooth.annot:colormap="lut" --surface ${FREESURFER_HOME}/subjects/fsaverage/surf/lh.inflated:annot=${FREESURFER_HOME}/subjects/fsaverage/label/lh.mic.smooth.annot:colormap="lut"
# ^ Not working... color label problem... or annot problem

#Screengrabs with tksurfer. This can be rerun somewhere other than fsaverage.
${SCRDIR}/mkPics.sh

# Rename the unknowns to medial wall... no unknowns
#mv ${OUTDIR}/miccaiPics/lh_\?\?\?_med.tif ${OUTDIR}/miccaiPics/lh_medialwall_med.tif
#mv ${}/PicsMICCAI/rh_\?\?\?_med.tif ${}/PicsMICCAI/rh_medialwall_med.tif

#rm ${}/PicsMICCAI/*_\?*

# Finally, let the R spatial tools work their magic...
# This creates ho_atlas.Rda which contains a couple of data frames, almost ready for inclusion in ggsegExtra.
Rscript ${SCRDIR}/mkMic.R
