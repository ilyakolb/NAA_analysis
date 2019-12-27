#!/bin/sh

if [ $# -eq 0 ]
then
    echo -e "Usage:\n\tanalyze_plates.sh plates_folder [protocol] [threshold]\n\nIf no protocol is specified then GCaMP is assumed."
    exit -1
fi

PLATES_PATH="$1"
if [ $# -ge 2 ]
then
	PLATE_TYPE="$2"
else
	PLATE_TYPE="GCaMP"
fi
if [ $# -ge 3 ]
then
	SEGMENTATION_THRESHOLD="$3"
else
	SEGMENTATION_THRESHOLD=""
fi

if [ ! -d "$PLATES_PATH" ]
then
	echo "No folder was found at $PLATES_PATH"
	exit 1
fi

PLATES_NAME=$(basename "$PLATES_PATH")
CLEAN_PLATES_NAME=$(echo "$PLATES_NAME" | sed "s/[^a-zA-Z0-9 ]/_/g")

LOG_DIR="/groups/flylight/GENIE/GENIE Pipeline/Analysis/Log Files/$PLATES_NAME"
mkdir -p "$LOG_DIR"
chmod g+w "$LOG_DIR"

# Make sure all annotations files are group-writable
# TODO: still need to do this?
chmod g+w "/groups/flylight/GENIE/GENIE Pipeline/Imaging Data/2012*/result*GCaMP/*GCaMP.mat" 2>/dev/null

IFS=$'\n'

for PLATE_PATH in $(ls -1d $PLATES_PATH/P[0-9]*_$PLATE_TYPE)
do
	unset IFS
	
	PLATE_NAME=$(basename "$PLATE_PATH")
	CLEAN_PLATE_NAME=$(echo "$PLATE_NAME" | sed "s/[^a-zA-Z0-9 ]/_/g")
	PLATE_PREFIX=$(echo "$PLATE_NAME" | cut -c -2)
	
	if [ "$PLATE_PREFIX" != "P0" ]
	then
		# Submit the job to the cluster.  Memory seems to peek at around 9.5 GB so we would need to reserve two nodes.
		# Unfortunately random crashes occur unless the whole node is requested.
		qsub -N "GENIE-NAA-Analyze-${CLEAN_PLATES_NAME}-${CLEAN_PLATE_NAME}" -A kimd -pe batch 16 -b y -j y -cwd -o "$LOG_DIR/$PLATE_NAME.log" -V time ./analyze_plate.sh "\"$PLATE_PATH\"" "$SEGMENTATION_THRESHOLD"
	fi
done

# Submit a dependent job to compile the results, it will only run once all the others have completed.
qsub -N "GENIE-NAA-Compile-Results-${CLEAN_PLATES_NAME}-${PLATE_TYPE}" -hold_jid "GENIE-NAA-Analyze-${CLEAN_PLATES_NAME}-*" -A kimd -M "$USER@janelia.hhmi.org" -m e -pe batch 2 -b y -j y -cwd -o "$LOG_DIR/compile_${PLATE_TYPE}.log" -V time ./compile_results.sh "\"$PLATES_PATH\"" "\"$PLATE_TYPE\"" "$SEGMENTATION_THRESHOLD"
