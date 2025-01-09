#!/usr/bin/env bash
mkdir Servers
pushd Servers
mkdir GTNH
pushd GTNH
wget https://downloads.gtnewhorizons.com/ServerPacks/GT_New_Horizons_2.7.2_Server_Java_17-21.zip
unzip ./GT_New_Horizons_2.7.2_Server_Java_17-21.zip
rm ./GT_New_Horizons_2.7.2_Server_Java_17-21.zip
sed -i 's/false/true/g' eula.txt
sed -i -e 's/S:enable_explosions=TRUE/S:enable_explosions=DEFAULT/' -e 's/B:only_backup_claimed_chunks=false/B:only_backup_claimed_chunks=true/' -e 's/B:back=false/B:back=true/' -e 's/B:home=false/B:home=true/' -e 's/B:rtp=false/B:rtp=true/' -e 's/B:tpa=false/B:tpa=true/' -e 's/B:chunk_claiming=false/B:chunk_claiming=true/' -e 's/B:disable_player_suffocation_damage=false/B:disable_player_suffocation_damage=true/' serverutilities/serverutilities.cfg
cat > serverutilities/server/ranks.txt << EOF
[player]
power: 1
default_player_rank: true
serverutilities.claims.max_chunks: 1000
serverutilities.chunkloader.max_chunks: 1000
serverutilities.back.warmup: 5s
serverutilities.back.cooldown: 0s
serverutilities.back.respawn: false
serverutilities.homes.max: 3
serverutilities.homes.warmup: 5s
serverutilities.homes.cooldown: 0s
serverutilities.homes.cross_dim: true
serverutilities.rtp.cooldown: 10m
serverutilities.rtp.warmup: 5s
serverutilities.spawn.cooldown: 0s
serverutilities.spawn.warmup: 5s
serverutilities.tpa.warmup: 5s
serverutilities.tpa.cooldown: 0s
serverutilities.tpa.cross_dim: true
EOF

pushd mods/
rm RWG*
wget https://github.com/GTNewHorizons/Realistic-Terrain-Generation/releases/download/1.1.3-GTNH/RTG-1.1.3-GTNH.jar
wget https://github.com/GTNewHorizons/Climate-Control/releases/download/0.10.0-GTNH/ClimateControl-0.10.0-GTNH.jar
popd
sed -i 's/S:"World Generator"=RWG/S:"World Generator"=RTG/' config/defaultworldgenerator.cfg
sed -i 's/level-type=rwg/level-type=rtg/' server.properties
sed -i 's/spawn-protection=1/spawn-protection=0/' server.properties
