# Map Matcher

## Installation of [map-matching](https://github.com/graphhopper/map-matching)

- edit ~/.m2/settings.xml and add github access token
- install map-matching
    ```bash
    git clone https://github.com/graphhopper/map-matching.git
    cd mat-matching
    mvn package -DskipTests
    ```
- download OSM map (here for austria)
    ```bash
    wget https://download.geofabrik.de/europe/austria-latest.osm.pbf -O austria-latest.osm.pbf
    ```

- delete dir `graph-cache` if it exists
- import OSM maps for austria
    ```bash
    java -jar matching-web/target/graphhopper-map-matching-web-3.0-SNAPSHOT.jar import --vehicle foot map-data/austria-latest.osm.pbf
    ```
- match track1.gpx to map by hand
    ```bash
    java -jar matching-web/target/graphhopper-map-matching-web-3.0-SNAPSHOT.jar match --vehicle foot tracks/track1.gpx
    ```

**not needed**, only for webserver
- edit config.yml
-   ```bash
    java -jar matching-web/target/graphhopper-map-matching-web-3.0-SNAPSHOT.jar server config.yml
    curl -XPOST -H "Content-Type: application/gpx+xml" -d @tracks/track1.gpx "localhost:8989/match?vehicle=car&type=json" > snapped.json
    curl -XPOST -H "Content-Type: application/gpx+xml" -d @tracks/track1.gpx "localhost:8989/match?vehicle=car&type=gpx" > snapped.gpx
    curl -XPOST -H "Content-Type: application/gpx+xml" -d @tracks/track1.gpx "localhost:8989/match?profile=foot&type=gpx" > snapped.gpx
    ```
 