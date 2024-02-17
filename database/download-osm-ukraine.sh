#!/bin/bash

sudo apt-get update
sudo apt-get install -y osm2pgsql wget unzip zip

echo "Download OSM data for Lviv region."
wget https://download.openstreetmap.fr/extracts/europe/ukraine/lviv_oblast-latest.osm.pbf
echo "Download OSM data for Lviv region is completed."

echo "Run OSM Migration."
sudo osm2pgsql -s -U $DB_USERNAME -W $DB_PASSWORD -l -d $DB_NAME -H $DB_ADDRESS --hstore lviv_oblast-latest.osm.pbf
echo "OSM Migration is completed."

if [ $? -eq 0 ]; then
    echo "OSM migration completed successfully."
else
    echo "OSM migration failed." >&2
    exit 1
fi
