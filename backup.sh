#!/bin/bash

help()
{
    echo "$0 SOURCE [DEST_DIR]"
    echo "Create a date-snapshot backup of SOURCE stored in 3 copies into DEST_DIR. If DEST_DIR is ommited, CWD will be used."
}

SOURCE=$1
DEST_DIR=$2
REDUNDANCY_COPIES=3

if [[ -z "${SOURCE}" ]]; then
    help
    printf "\nMissing SOURCE.\n"
    exit 1
fi

if [[ -z "${DEST_DIR}" ]]; then
    DEST_DIR=$(pwd)
else
    DEST_DIR=$(realpath ${DEST_DIR})
fi

SOURCE_NAME=$(basename ${SOURCE})

SNAPSHOT_NAME=${SOURCE_NAME}-$(date +"%Y-%0m-%0d-at-%0H-%0M-%0S")
SNAPSHOT_PATH=${DEST_DIR}/${SNAPSHOT_NAME}.tar

printf "Is the snapshot path ok? (${SNAPSHOT_PATH}) [y/n]: "
read RESPONSE

if [[ "${RESPONSE}" != "y" ]]; then
    exit
fi

TMP=$(mktemp --directory)
if [ $? -ne 0 ]; then
    echo "Failed to create temp working directory."
    exit 1
fi

mkdir ${TMP}/${SNAPSHOT_NAME}
if [ $? -ne 0 ]; then
    rm -r ${TMP}
    echo "Failed to create temp snapshot directory."
    exit 1
fi

ARCHIVE_NAME=archive.tar

tar cf ${TMP}/${ARCHIVE_NAME} -C $(dirname $(realpath ${SOURCE})) ${SOURCE_NAME}
if [ $? -ne 0 ]; then
    rm -r ${TMP}
    echo "Failed to create source archive."
    exit 1
fi

for ((i = 1; i <= ${REDUNDANCY_COPIES}; i++));
do 
    cp ${TMP}/${ARCHIVE_NAME} ${TMP}/${SNAPSHOT_NAME}/${i}.tar
    if [ $? -ne 0 ]; then
        rm -r ${TMP}
        echo "Failed to copy source archive."
        exit 1
    fi
done

tar cf ${SNAPSHOT_PATH} -C ${TMP} ${SNAPSHOT_NAME}
if [ $? -ne 0 ]; then
    rm -r ${TMP}
    echo "Failed to create snapshot."
    exit 1
fi

rm -r ${TMP}

echo "Done."

