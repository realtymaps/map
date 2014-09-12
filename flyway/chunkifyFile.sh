#!/bin/bash
set -e

if [ "$#" -lt 2 ]
then
    echo "usage: `basename $0` <linesPerChunk> <sourceFile>"
    exit 1
fi


CHUNK_SIZE="$1"
ORIGINAL_FILE="$2"
ORIGINAL_FILENAME=`basename $ORIGINAL_FILE`

array=(${ORIGINAL_FILENAME//__/ })
MIGRATION_VERSION=${array[0]}
MIGRATION_DESCRIPTION=${array[1]%.*}

LINES=`wc -l $ORIGINAL_FILE`
LINES=`echo $LINES | cut -f 1 -d ' '`
MAX_CHUNKS=$((LINES/CHUNK_SIZE))
MAX_CHUNKS=$((MAX_CHUNKS+1))
PADDING=${#MAX_CHUNKS}

(
    for CURR_CHUNK in `seq 1 $MAX_CHUNKS`
    do
        CURR_LINE=0
        printf -v CURR_CHUNK "%0${PADDING}d" $CURR_CHUNK
        CURR_CHUNK_FILE="${MIGRATION_VERSION}.${CURR_CHUNK}__${MIGRATION_DESCRIPTION}_${CURR_CHUNK}.sql"
        echo "BEGIN TRANSACTION;" > $CURR_CHUNK_FILE
        while read -r line && [ $CURR_LINE -lt $CHUNK_SIZE ]
        do
            echo "$line" >> $CURR_CHUNK_FILE
            CURR_LINE=$((CURR_LINE+1))
        done
        echo "COMMIT;" >> $CURR_CHUNK_FILE
    done
) < $ORIGINAL_FILE