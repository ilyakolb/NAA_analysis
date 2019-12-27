#!/bin/bash

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

echo "=================================================="
echo "Compiling weekly $PLATE_TYPE results at $PLATES_PATH on `date`"
echo

if [ ! -d "$PLATES_PATH" ]
then
	echo "The plate folder could not be found."
	exit 1
fi

# Run the MATLAB code on the indicated folder.
source /usr/local/matutil/mcr_select.sh 2013a
./compile_results "$PLATES_PATH" "$PLATE_TYPE" "$SEGMENTATION_THRESHOLD"

# TODO: send an e-mail on failure?

source /usr/local/matutil/mcr_select.sh clean

echo -e "\nCompilation completed."
