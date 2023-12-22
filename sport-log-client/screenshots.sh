#!/bin/bash

USERNAME=ScreenshotUser
PASSWORD=ScreenshotPassword0
AP_USERNAME='wodify-login'
AP_PASSWORD=Wodify-Login-Password1
BASE_URL='http://localhost:8001'
EMULATOR_DEVICE=Pixel_6_API_34
GIT_REF=$(git show-ref --head --hash=7 HEAD)

GREEN='\033[1;32m'
RED='\033[1;31m'
NC='\033[0m' # No Color
step() {
    printf "\n$GREEN$1$NC\n\n"
}
error() {
    printf "\n$RED$1$NC\n"
}

step "check for mapbox token"
if [ ! $SDK_REGISTRY_TOKEN ]; then
    error "SDK_REGISTRY_TOKEN required"
    exit 1
fi

step "start server"
cd ../sport-log-server
cargo build
pkill -f sport-log-server
cargo run &
SERVER_PID=$!
sleep 2

cd ../sport-log-client

step "delete user if exits"
curl -u $USERNAME:$PASSWORD -X DELETE "$BASE_URL/v0.3/user"

step "create user"
# requires user self auth
curl -X POST "$BASE_URL/v0.3/user" \
    -H 'Accept: application/json' \
    -H 'Content-Type: application/json' \
    -d @../test-data/user.json

step "check git ref"
NEW_VERSION=$(curl -s -u $USERNAME:$PASSWORD "$BASE_URL/v0.3/app/info?git_ref=$GIT_REF")
if [ "$NEW_VERSION" = '{"new_version":false}' ]; then
    echo "git ref up to date"
else
    if [ "$NEW_VERSION" = '{"new_version":true}' ]; then
        error "git ref out of date"
    elif [ "$NEW_VERSION" = '{"status":400,"message":{"other":{"error":"the git ref was not found in the ref log"}}}' ]; then
        error "git ref not found"
    else
        error "unexpected response: $NEW_VERSION"
    fi
    kill $SERVER_PID
    exit 2
fi

step "run ap setup"
# requires ap self auth
entities=(platform action_provider)
for entity in "${entities[@]}"; do
    curl -X POST "$BASE_URL/v0.3/ap/$entity" \
        -H 'Accept: application/json' \
        -H 'Content-Type: application/json' \
        -d @../test-data/$entity.json
done
curl -u $AP_USERNAME:$AP_PASSWORD -X POST "$BASE_URL/v0.3/ap/action" \
    -H 'Accept: application/json' \
    -H 'Content-Type: application/json' \
    -d @../test-data/action.json

step "run user setup"
entities=(diary wod strength_session strength_set metcon_session route cardio_session platform_credential action_rule action_event)
for entity in "${entities[@]}"; do
    cat ../test-data/$entity.json | \
    sed "s/2023-07-04/$(date +%Y-%m-%d)/g" | \
    sed "s/2023-07-05/$(date -d +1day +%Y-%m-%d)/g" | \
    sed "s/2023-07-02/$(date -d -2day +%Y-%m-%d)/g" | \
    curl -u $USERNAME:$PASSWORD -X POST "$BASE_URL/v0.3/$entity" \
        -H 'Accept: application/json' \
        -H 'Content-Type: application/json' \
        -d @-
done

step "start emulator"
~/Android/Sdk/emulator/emulator @$EMULATOR_DEVICE & 
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
flutter test integration_test/screenshots.dart --flavor production --dart-define GIT_REF=$GIT_REF

step "remove new_screenshots if exists"
rm -r new_screenshots

step "copy screenshots"
mkdir new_screenshots
adb pull sdcard/Download new_screenshots
mv new_screenshots/Download/* new_screenshots

step "terminate emulator"
kill $EMULATOR_PID
sleep 5

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
