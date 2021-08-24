# Map Matcher

## Installation

git clone
~/.m2/settings.xml
mvn package -DskipTests
wget https://download.geofabrik.de/europe/austria-latest.osm.pbf
mv austria-latest.osm.pbf map-data

delete graph-cache if exists
java -jar matching-web/target/graphhopper-map-matching-web-3.0-SNAPSHOT.jar import --vehicle foot map-data/austria-latest.osm.pbf
java -jar matching-web/target/graphhopper-map-matching-web-3.0-SNAPSHOT.jar match --vehicle foot tracks/track1.gpx

config.yml
java -jar matching-web/target/graphhopper-map-matching-web-3.0-SNAPSHOT.jar server config.yml
curl -XPOST -H "Content-Type: application/gpx+xml" -d @tracks/track1.gpx "localhost:8989/match?vehicle=car&type=json" > snapped.json
curl -XPOST -H "Content-Type: application/gpx+xml" -d @tracks/track1.gpx "localhost:8989/match?vehicle=car&type=gpx" > snapped.gpx
curl -XPOST -H "Content-Type: application/gpx+xml" -d @tracks/track1.gpx "localhost:8989/match?profile=foot&type=gpx" > snapped.gpx
