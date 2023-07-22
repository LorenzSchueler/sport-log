#!/bin/bash

step() {
    GREEN='\033[1;32m'
    NC='\033[0m' # No Color
    printf "\n$GREEN$1$NC\n\n"
}

USERNAME=ScreenshotUser
PASSWORD=ScreenshotPassword0
BASE_URL='http://localhost:8001'

step "set mapbox token"
#export SDK_REGISTRY_TOKEN=<token> # TODO use GH token

step "start server"
cd ../sport-log-server
cargo run &
SERVER_PID=$!
sleep 2

cd ../sport-log-client

step "delete user if exits"
curl -u $USERNAME:$PASSWORD -X DELETE "$BASE_URL/v0.3/user"

step "run setup"
curl -X POST "$BASE_URL/v0.3/user" \
    -H 'Accept: application/json' \
    -H 'Content-Type: application/json' \
    -d @integration_test/user.json
entities=(diary strength_session strength_set metcon_session route cardio_session platform platform_credential action action_rule action_event)
for entity in "${entities[@]}"; do
    curl -u $USERNAME:$PASSWORD -X POST "$BASE_URL/v0.3/$entity" \
        -H 'Accept: application/json' \
        -H 'Content-Type: application/json' \
        -d @integration_test/$entity.json
done

step "start emulator"
~/Android/Sdk/emulator/emulator @Pixel_6_API_34 & 
EMULATOR_PID=$!
step "wait for device to start"
while !(adb devices | grep emulator); do
    sleep 1
done
while !(adb shell getprop init.svc.bootanim | grep stopped); do
    sleep 1
done
sleep 2

step "delete old screenshots"
adb shell rm 'sdcard/Download/*.png'

step "create new screenshots"
flutter test integration_test/screenshots.dart --flavor production --dart-define GIT_REF=$(git show-ref --head --hash=7 HEAD)

step "remove new_screenshots if exists"
rm -r new_screenshots

step "copy screenshots"
mkdir new_screenshots
adb pull sdcard/Download new_screenshots
mv new_screenshots/Download/* new_screenshots

step "terminate emulator"
kill $EMULATOR_PID # TODO does not work

step "run teardown (delete user)"
curl -u $USERNAME:$PASSWORD -X DELETE "$BASE_URL/v0.3/user"

step "terminate server"
kill $SERVER_PID

step "compare screenshots"
for image in new_screenshots/*.png; do 
    FILE=$(basename $image)
    if ! test -e screenshots/$FILE; then
        echo $FILE is new
        cp $image screenshots
    elif compare screenshots/$FILE $image /dev/null; then
        echo $FILE not changed
    else
        echo $FILE changed $(compare -metric AE screenshots/$FILE $image /dev/null 2>&1)
        cp $image screenshots
    fi
done

step "remove new_screenshots"
rm -r new_screenshots
