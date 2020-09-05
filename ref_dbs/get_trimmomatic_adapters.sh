#!/usr/bin/env bash
set -e -u -o pipefail
START_DIR=$PWD
SOURCE_URL="http://www.usadellab.org/cms/uploads/supplementary/Trimmomatic/Trimmomatic-Src-0.39.zip"
ZIP_NAME="Trimmomatic-Src-0.39.zip"
INST_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

echo "Working in Installation Directory: ${INST_DIR}"
cd "${INST_DIR}"
echo ""
echo "Downloading Trimmomatic Setup Package..."
echo "    from: ${SOURCE_URL}"
curl -o "${ZIP_NAME}" "${SOURCE_URL}"
echo "Unzipping Package..."
unzip -q "${ZIP_NAME}"
echo "Extracting Trimmomatic Adapters..."
mv -v "$(realpath ./trimmomatic-0.39/adapters)" "$(realpath ./trimmomatic_adapters)"
echo "Cleaning up Trimmomatic Package..."
rm -r "${ZIP_NAME}" ./trimmomatic-0.39
echo "Done."
echo ""
cd "${START_DIR}"
