#!/bin/bash

# Copyright Olaru Alexandru (oda13k). MIT License

help()
{
    echo "usage: $0 [OPTIONS...] SOURCE"
    echo "Create an archival backup of SOURCE meant for long-term storage with bitrot in mind."
    echo "The program creates a tar archive (called a snapshot), storing COPIES copies of SOURCE as tar archive(s)."
    echo "No compression is used."
    echo "SOURCE can either be a file or a directory."
    echo ""
    echo "OPTIONS:"
    echo "  -h, --help             Print this message and exit"
    echo "  -c, --copies COPIES    How many redundancy copies of SOURCE to store, by default 3"
    echo "  -d, --dest-dir PATH    Directory path where to put the snapshot archive, by default the current working directory."
}

fail()
{
    if ! [[ -z "${TMP}" ]]; then
        rm -r ${TMP}
    fi

    exit 1
}

while [[ $# -gt 0 ]]; do
    case $1 in
    -h|--help)
        help
        exit 
        ;;

    -c|--copies)
        COPIES=$2

        if ! [[ "${COPIES}" =~ ^[1-9][0-9]?+$ ]]; then
            help
            printf "\n$1 requires a positive integer argument.\n"
            exit 1
        fi

        shift
        shift
        ;;

    -d|--dest-dir)
        DEST_DIR=$2

        if [[ -z "${DEST_DIR}" ]]; then
            help
            printf "\n$1 requires an argument.\n"
            exit 1
        fi

        shift
        shift
        ;;

    *)
        if [[ -z "${SOURCE}" ]]; then
            SOURCE=$1
        else
            help
            printf "\nUnknown positional argument '$1'.\n"
            exit 1
        fi

        shift
        ;;
    esac
done

if [[ -z "${SOURCE}" ]]; then
    help
    printf "\nMissing SOURCE.\n"
    exit 1
fi

if [[ -z "${COPIES}" ]]; then
    COPIES=3
fi

if [[ -z "${DEST_DIR}" ]]; then
    DEST_DIR=$(pwd)
else
    DEST_DIR=$(realpath ${DEST_DIR})
fi

SOURCE_NAME=$(basename ${SOURCE})

SNAPSHOT_NAME=${SOURCE_NAME}-$(date +"%Y-%0m-%0d-at-%0H-%0M-%0S")
SNAPSHOT_PATH=${DEST_DIR}/${SNAPSHOT_NAME}.tar

printf "Create snapshot '${SNAPSHOT_PATH}'? [y/n]: "
read RESPONSE
if [[ "${RESPONSE}" != "y" ]]; then
    exit
fi

TMP_ARCHIVE=archive.tar

TMP=$(mktemp --directory) || fail

mkdir ${TMP}/${SNAPSHOT_NAME} || fail

tar cf ${TMP}/${TMP_ARCHIVE} -C $(dirname $(realpath ${SOURCE})) ${SOURCE_NAME} || fail

for ((i = 1; i <= ${COPIES}; i++));
do 
    cp ${TMP}/${TMP_ARCHIVE} ${TMP}/${SNAPSHOT_NAME}/${i}.tar || fail
done

tar cf ${SNAPSHOT_PATH} -C ${TMP} ${SNAPSHOT_NAME} || fail

rm -r ${TMP}

echo "Done."

