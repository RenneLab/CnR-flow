#!/usr/bin/env bash
START_DIR=$PWD
SOURCE_URL="https://zenodo.org/record/3374112/files/cutruntools.tar.gz?download=1 "
TAR_NAME="cutruntools.tar.gz"
INST_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

#mkdir -p "${START_DIR}/${INST_DIR}"
#cd "${START_DIR}/${INST_DIR}"
echo "Working in Installation Directory: ${INST_DIR}"
cd "${INST_DIR}"
echo ""
echo "Downloading CUT&RUNTools Source Package..."
echo "    from: ${SOURCE_URL}"
curl -o "${TAR_NAME}" "${SOURCE_URL}"
echo "Unpacking TAR: ${TAR_NAME}"
tar -xf ${TAR_NAME}
echo "Fetching kseq_test related files."
cp ./cutruntools/*kseq* ./
echo "Fetching filter_below related files."
cp ./cutruntools/filter_below.awk ./
echo "Building kseq_test executable..."
bash ./make_kseq_test.sh
echo "Cleaning up source files..."
rm -r cutruntools ${TAR_NAME}
echo "Done."
echo ""
cd "${START_DIR}"
