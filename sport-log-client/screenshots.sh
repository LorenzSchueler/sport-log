#!/bin/bash

USERNAME=ScreenshotUser
PASSWORD=ScreenshotPassword0
AP_USERNAME='wodify-login'
AP_PASSWORD=Wodify-Login-Password1
BASE_URL='http://localhost:8001'
EMULATOR_DEVICE=Pixel_10
PACKAGE=org.sport_log.sport_log_client
APK=build/app/outputs/flutter-apk/app-production-debug.apk
# must match the directory the integration test writes its capture markers to
SCREENSHOT_DIR=/sdcard/Download
GIT_REF=$(git rev-parse --short=7 HEAD)

GREEN='\033[1;32m'
RED='\033[1;31m'
NC='\033[0m' # No Color
step() {
    printf "\n$GREEN$1$NC\n\n"
}
error() {
    printf "\n$RED$1$NC\n"
}

step "reset database"
pkill -f sport-log-server
psql "$(sed -n 's/^DATABASE_URL=//p' ../sport-log-types/.env)" \
    -c 'drop schema public cascade' -c 'create schema public'

step "start server"
cd ../sport-log-server
cargo build
cargo run &
SERVER_PID=$!
# wait until the server is ready
while ! curl -s -o /dev/null "$BASE_URL/v0.4/user"; do
    sleep 1
done

cd ../sport-log-client

step "create user"
# requires user self auth
curl -s -X POST "$BASE_URL/v0.4/user" \
    -H 'Accept: application/json' \
    -H 'Content-Type: application/json' \
    -d @../test/data/user.json

step "check git ref"
NEW_VERSION=$(curl -s -s -u $USERNAME:$PASSWORD "$BASE_URL/v0.4/app/info?git_ref=$GIT_REF")
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
    curl -s -X POST "$BASE_URL/v0.4/ap/$entity" \
        -H 'Accept: application/json' \
        -H 'Content-Type: application/json' \
        -d @../test/data/$entity.json
done
curl -s -u $AP_USERNAME:$AP_PASSWORD -X POST "$BASE_URL/v0.4/ap/action" \
    -H 'Accept: application/json' \
    -H 'Content-Type: application/json' \
    -d @../test/data/action.json

step "run user setup"
entities=(diary wod strength_session strength_set metcon_session route cardio_session platform_credential action_rule action_event)
for entity in "${entities[@]}"; do
    cat ../test/data/$entity.json | \
    sed "s/2023-07-04/$(date +%Y-%m-%d)/g" | \
    sed "s/2023-07-05/$(date -d +1day +%Y-%m-%d)/g" | \
    sed "s/2023-07-02/$(date -d -2day +%Y-%m-%d)/g" | \
    sed "s/2023-07-0\([68]\)/$(date +%Y-%m)-0\1/g" | \
    sed "s/2023-07-\(1[18]\)/$(date +%Y-%m)-\1/g" | \
    curl -s -u $USERNAME:$PASSWORD -X POST "$BASE_URL/v0.4/$entity" \
        -H 'Accept: application/json' \
        -H 'Content-Type: application/json' \
        -d @-
done

step "start emulator"
# without -gpu host the emulator may fall back to software rendering which
# renders the maps desaturated and differently on every run
~/Android/Sdk/emulator/emulator @$EMULATOR_DEVICE -gpu host &
EMULATOR_PID=$!
step "wait for device to start"
while !(adb devices | grep emulator); do
    sleep 1
done
while !(adb shell getprop init.svc.bootanim | grep stopped); do
    sleep 1
done
sleep 2

step "install app"
# the app must be installed before the test run to reset its state and grant permissions
flutter build apk --debug --flavor production --dart-define GIT_REF=$GIT_REF
if ! test -e $APK; then
    error "apk not found at $APK"
    kill $EMULATOR_PID
    kill $SERVER_PID
    exit 2
fi
adb install -r $APK || (adb uninstall $PACKAGE && adb install $APK)

step "reset app state"
adb shell pm clear $PACKAGE

step "grant permissions"
permissions=(ACCESS_FINE_LOCATION ACCESS_COARSE_LOCATION ACCESS_BACKGROUND_LOCATION POST_NOTIFICATIONS ACTIVITY_RECOGNITION BLUETOOTH_SCAN BLUETOOTH_CONNECT)
for permission in "${permissions[@]}"; do
    adb shell pm grant $PACKAGE android.permission.$permission 2>/dev/null
done
adb shell settings put secure location_mode 3
# the "Viewing full screen" dialog would cover the pages which hide the system bars
adb shell settings put secure immersive_mode_confirmations confirmed

step "fix position"
adb emu geo fix 11.3897 47.2612

step "hide notifications"
adb shell settings put global adb_notify 0
adb shell cmd notification list | tr -d '\r' | while read -r key; do
    [ -n "$key" ] && adb shell "cmd notification snooze --for 3600000 '$key'" \
        < /dev/null > /dev/null
done
# snoozing keeps system ui busy for a moment and discards the demo state
sleep 5

step "freeze status bar"
# the clock and the battery level would change between runs
adb shell settings put global sysui_demo_allowed 1
demo() {
    adb shell am broadcast -a com.android.systemui.demo -e command "$@" > /dev/null
}
demo enter
demo clock -e hhmm 0900
demo battery -e level 100 -e plugged false
# hide mobile signal strength because it depends on real radio state during the run
demo network -e mobile hide -e wifi show -e level 4 -e fully true

step "delete old screenshots"
adb shell rm "$SCREENSHOT_DIR/*.png" "$SCREENSHOT_DIR/*.capture"

step "start screenshot capture"
# the integration test can only capture the flutter surface, so the screenshots
# are taken on the host where they include the system bars
capture() {
    while true; do
        for marker in $(adb shell ls $SCREENSHOT_DIR/*.capture 2>/dev/null | tr -d '\r'); do
            name=$(basename "$marker" .capture)
            adb shell screencap -p "$SCREENSHOT_DIR/$name.png"
            adb shell rm "$marker"
        done
        sleep 0.2
    done
}
capture &
CAPTURE_PID=$!

step "create new screenshots"
flutter test integration_test/screenshots.dart --flavor production --dart-define GIT_REF=$GIT_REF

step "stop screenshot capture"
kill $CAPTURE_PID

step "remove new_screenshots if exists"
rm -rf new_screenshots

step "copy screenshots"
mkdir new_screenshots
adb pull $SCREENSHOT_DIR new_screenshots
mv new_screenshots/Download/* new_screenshots

step "round corners"
# the framebuffer capture is rectangular while the display has rounded corners
CORNER_RADIUS=$(adb shell dumpsys window \
    | grep -om1 'RoundedCorner{position=TopLeft, radius=[0-9]*' \
    | grep -o '[0-9]*$')
echo "corner radius: $CORNER_RADIUS"
for image in new_screenshots/*.png; do
    read -r width height < <(identify -format '%w %h' "$image")
    # the excluded chunks contain the creation date which differs between runs
    convert "$image" -define png:exclude-chunk=time,date -alpha set \
        \( -size "${width}x${height}" xc:none -draw \
            "roundrectangle 0,0,$((width - 1)),$((height - 1)),$CORNER_RADIUS,$CORNER_RADIUS" \) \
        -compose DstIn -composite "$image"
done

step "terminate emulator"
kill $EMULATOR_PID
sleep 5

step "run teardown (delete user)"
curl -s -u $USERNAME:$PASSWORD -X DELETE "$BASE_URL/v0.4/user"

step "terminate server"
kill $SERVER_PID

step "compare screenshots"
for image in new_screenshots/*.png; do 
    FILE=$(basename $image)
    if ! test -e screenshots/$FILE; then
        echo $FILE is new
        cp $image screenshots
    else
        DIFFERENT_PIXELS=$(compare -metric AE screenshots/$FILE $image null: 2>&1)
        if [ "$DIFFERENT_PIXELS" = 0 ]; then
            echo $FILE not changed
        else
            echo $FILE changed $DIFFERENT_PIXELS
            cp $image screenshots
        fi
    fi
done

step "remove new_screenshots"
rm -r new_screenshots
