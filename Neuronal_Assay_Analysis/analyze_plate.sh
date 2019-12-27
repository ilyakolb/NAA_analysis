#!/bin/bash

PLATE_PATH="$1"
if [ $# -ge 2 ]
then
	SEGMENTATION_THRESHOLD="$2"
else
	SEGMENTATION_THRESHOLD=""
fi

echo "=================================================="
echo "Analyzing plate folder at $PLATE_PATH with th=$SEGMENTATION_THRESHOLD on `date`"
echo

if [ ! -d "$PLATE_PATH" ]
then
	echo "The plate folder could not be found."
	exit 1
fi

# Run the MATLAB code on the indicated folder wrapped in a virtual display.
source /usr/local/matutil/mcr_select.sh 2013a
xvfb-run --auto-servernum --server-args="-screen 0 2400x2400x24" ./plate_script "$PLATE_PATH" "$SEGMENTATION_THRESHOLD"

# TODO: send an e-mail on failure?

# Get rid of temporary files.
source /usr/local/matutil/mcr_select.sh clean
