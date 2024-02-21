#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

sudo yum makecache
sudo yum -y install osm2pgsql wget unzip zip

echo "Download OSM data for Lviv region."
wget https://download.openstreetmap.fr/extracts/europe/ukraine/lviv_oblast-latest.osm.pbf
echo "Download OSM data for Lviv region is completed."

echo "Run OSM Migration."
osm2pgsql -s -U $DB_USERNAME -W $DB_PASSWORD -l -d $DB_NAME -H $DB_ADDRESS --hstore lviv_oblast-latest.osm.pbf || { echo "OSM Migration failed"; exit 1; }
echo "OSM Migration is completed."