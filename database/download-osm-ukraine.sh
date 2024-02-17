#!/bin/bash

apt-get update &&
apt-get install -y osm2pgsql &&
apt-get install wget unzip zip -y &&
rm -rf /var/lib/apt/lists/*

echo "Download OSM data for Lviv region."
wget https://download.openstreetmap.fr/extracts/europe/ukraine/lviv_oblast-latest.osm.pbf
echo "Download OSM data for Lviv region is completed."

echo "Run OSM Migration."
osm2pgsql -s -U postgres -l -d osm-db -H localhost --hstore lviv_oblast-latest.osm.pbf
echo "OSM Migration is completed."
