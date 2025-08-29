#!/usr/bin/env bash

########################################
# Server config
########################################

# Where to install the server
BASE_DIR="Servers"
SERVER_DIR="GTNH"

# Which version of GT:NH serverpack to use
GTNH_VERSION="2.7.2"
JAVA_VERSION="17-21"

# Look in the beta folder
USE_BETA="false"

# RTG and ClimateControl versions
RTG_VERSION="1.1.3-GTNH"
CLIMATE_VERSION="0.10.0-GTNH"

########################################
# Internal variables
########################################

SERVER_ZIP="GT_New_Horizons_${GTNH_VERSION}_Server_Java_${JAVA_VERSION}.zip"
STABLE_URL="https://downloads.gtnewhorizons.com/ServerPacks/${SERVER_ZIP}"
BETA_URL="https://downloads.gtnewhorizons.com/ServerPacks/betas/${SERVER_ZIP}"

if [ "$USE_BETA" = "true" ]; then
  SERVER_URL="$BETA_URL"
else
  SERVER_URL="$STABLE_URL"
fi

RTG_URL="https://github.com/GTNewHorizons/Realistic-Terrain-Generation/releases/download/${RTG_VERSION}/RTG-${RTG_VERSION}.jar"
CLIMATE_URL="https://github.com/GTNewHorizons/Climate-Control/releases/download/${CLIMATE_VERSION}/ClimateControl-${CLIMATE_VERSION}.jar"

MAKER_BRANCH="main"
MAKER_ZIP="${MAKER_BRANCH}.zip"
MAKER_URL="https://github.com/Undercoverer/gtnh-maker/archive/refs/heads/${MAKER_ZIP}"

########################################
# Script
########################################

# Setup directories
mkdir -p "${BASE_DIR}/${SERVER_DIR}"
pushd "${BASE_DIR}/${SERVER_DIR}"

# Download and extract server pack
wget "${SERVER_URL}"
unzip "./${SERVER_ZIP}"
rm "./${SERVER_ZIP}"

# Accept EULA
sed -i 's/false/true/g' eula.txt

# Server utilities config tweaks
sed -i \
  -e 's/S:enable_explosions=TRUE/S:enable_explosions=DEFAULT/' \
  -e 's/B:only_backup_claimed_chunks=false/B:only_backup_claimed_chunks=true/' \
  -e 's/B:back=false/B:back=true/' \
  -e 's/B:home=false/B:home=true/' \
  -e 's/B:rtp=false/B:rtp=true/' \
  -e 's/B:tpa=false/B:tpa=true/' \
  -e 's/B:chunk_claiming=false/B:chunk_claiming=true/' \
  -e 's/B:disable_player_suffocation_damage=false/B:disable_player_suffocation_damage=true/' \
  -e '/^ranks {/,/^}/ s/^\(\s*B:enabled\s*=\s*\)false/\1true/' \
  serverutilities/serverutilities.cfg

# Replace worldgen mods
pushd mods/
rm RWG*
wget "${RTG_URL}"
wget "${CLIMATE_URL}"
popd

# Update configs
sed -i 's/S:"World Generator"=RWG/S:"World Generator"=RTG/' config/defaultworldgenerator.cfg
sed -i 's/level-type=rwg/level-type=rtg/' server.properties
sed -i 's/spawn-protection=1/spawn-protection=0/' server.properties

# Pull config files
wget "${MAKER_URL}"
unzip "${MAKER_ZIP}"
rsync -a "gtnh-maker-${MAKER_BRANCH}/config/" "config/"
rsync -a "gtnh-maker-${MAKER_BRANCH}/serverutilities/" "serverutilities/"
rm -r "gtnh-maker-${MAKER_BRANCH}/"
rm "${MAKER_ZIP}"

popd
