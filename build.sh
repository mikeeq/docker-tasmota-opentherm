#!/bin/bash

set -eu -o pipefail

# set -x

SCRIPT_PATH=${SCRIPT_PATH:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}

cd "$SCRIPT_PATH"

TASMOTA_GIT_URL=https://github.com/arendst/Tasmota
TASMOTA_GIT_LATEST_TAG="v$(curl -sI ${TASMOTA_GIT_URL}/releases/latest | grep -i 'location:' | cut -f2 -d'v' | cut -d'"' -f1 | tr -d '\r')"
TASMOTA_GIT_BRANCH_NAME=${TASMOTA_GIT_BRANCH_NAME:-$TASMOTA_GIT_LATEST_TAG}

echo >&2 "===]> Info: Cleanup docker-tasmota"
rm -rf docker-tasmota

echo >&2 "===]> Info: Clone docker-tasmota"
git clone https://github.com/tasmota/docker-tasmota.git

echo >&2 "===]> Info: cd docker-tasmota; git clone tasmota repo - tag ${TASMOTA_GIT_BRANCH_NAME}"
cd docker-tasmota
git clone --depth 1 --branch "${TASMOTA_GIT_BRANCH_NAME}" "${TASMOTA_GIT_URL}"

# https://tasmota.github.io/docs/OpenTherm/
echo >&2 "===]> Info: Add OpenTherm support to user_config_override.h"
sed -i '/^#endif..\/\/._USER_CONFIG_OVERRIDE_H_/i #ifndef USE_OPENTHERM\n#define USE_OPENTHERM\n#endif\n' user_config_override.h

echo >&2 "===]> Info: docker pull blakadder/docker-tasmota"
docker pull blakadder/docker-tasmota

echo >&2 "===]> Info: Compile.sh"
# commenting out all git commands, as tasmota is cloned beforehand in this script
sed -i 's/^\s*git/#&/' compile.sh
./compile.sh

echo >&2 "===]> Info: Copy artifacts"
cd "$SCRIPT_PATH"
mkdir -p release/
cp -rfv docker-tasmota/docker-tasmota.log release/
cp -rfv docker-tasmota/Tasmota/build_output/firmware/* release/
sha256sum release/* > release/sha256

cd docker-tasmota
echo "docker-tasmota branch: default" >> "$SCRIPT_PATH/release/sha256"
git show --oneline -s HEAD >> "$SCRIPT_PATH/release/sha256"

cd Tasmota
echo "Tasmota branch: ${TASMOTA_GIT_BRANCH_NAME}" >> "$SCRIPT_PATH/release/sha256"
git show --oneline -s HEAD >> "$SCRIPT_PATH/release/sha256"
