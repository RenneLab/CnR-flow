#!/usr/bin/env bash
START_DIR=$PWD
SOURCE_URL="http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/faCount"
INST_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

echo "Working in Installation Directory: ${INST_DIR}"
cd "${INST_DIR}"
echo ""
echo "Downloading faCount binary executable..."
echo "    from: ${SOURCE_URL}"
curl -o "faCount" "${SOURCE_URL}"
echo "Done."
echo ""
cd "${START_DIR}"
