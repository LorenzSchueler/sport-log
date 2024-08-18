#!/bin/bash

set -e

echo -e "GET $BASE_URL/version"
curl -s -f "$BASE_URL/version"

# adm routes
echo -e "\n\nPOST $BASE_URL/v0.4/adm/platform"
curl -s -f -u admin:$ADMIN_PASSWORD -X POST "$BASE_URL/v0.4/adm/platform" \
    -H 'Content-Type: application/json' \
    -d @data/platform.json
echo -e "\n\nGET $BASE_URL/v0.4/adm/platform"
curl -s -f -u admin:$ADMIN_PASSWORD "$BASE_URL/v0.4/adm/platform" \
    -H 'Accept: application/json'
echo -e "\n\nPUT $BASE_URL/v0.4/adm/platform"
curl -s -f -u admin:$ADMIN_PASSWORD -X PUT "$BASE_URL/v0.4/adm/platform" \
    -H 'Content-Type: application/json' \
    -d @data/platform.json

echo -e "\n\nPOST $BASE_URL/v0.4/adm/action_provider"
curl -s -f -u admin:$ADMIN_PASSWORD -X POST "$BASE_URL/v0.4/adm/action_provider" \
    -H 'Content-Type: application/json' \
    -d @data/action_provider.json
echo -e "\n\nGET $BASE_URL/v0.4/adm/action_provider"
curl -s -f -u admin:$ADMIN_PASSWORD "$BASE_URL/v0.4/adm/action_provider" \
    -H 'Accept: application/json'

# create action so that action events can be created
echo -e "\n\nPOST $BASE_URL/v0.4/ap/action"
curl -s -f -u admin:$ADMIN_PASSWORD -X POST "$BASE_URL/v0.4/ap/action" \
    -H 'Content-Type: application/json' \
    -H 'id: 2432838314050000638' \
    -d @data/action.json

echo -e "\n\nPOST $BASE_URL/v0.4/adm/user"
curl -s -f -u admin:$ADMIN_PASSWORD -X POST "$BASE_URL/v0.4/adm/user" \
    -H 'Content-Type: application/json' \
    -d @data/user.json

echo -e "\n\nPOST $BASE_URL/v0.4/adm/action_event"
curl -s -f -u admin:$ADMIN_PASSWORD -X POST "$BASE_URL/v0.4/adm/action_event" \
    -H 'Content-Type: application/json' \
    -d @data/action_event.json
echo -e "\n\nPUT $BASE_URL/v0.4/adm/action_event"
curl -s -f -u admin:$ADMIN_PASSWORD -X PUT "$BASE_URL/v0.4/adm/action_event" \
    -H 'Content-Type: application/json' \
    -d @data/action_event.json
echo -e "\n\nDELETE $BASE_URL/v0.4/adm/action_event"
curl -s -f -u admin:$ADMIN_PASSWORD -X DELETE "$BASE_URL/v0.4/adm/action_event" \
    -H 'Content-Type: application/json' \
    -d '[]'

echo -e "\n\nGET $BASE_URL/v0.4/adm/creatable_action_rule"
curl -s -f -u admin:$ADMIN_PASSWORD "$BASE_URL/v0.4/adm/creatable_action_rule" \
    -H 'Accept: application/json'
echo -e "\n\nGET $BASE_URL/v0.4/adm/deletable_action_event"
curl -s -f -u admin:$ADMIN_PASSWORD "$BASE_URL/v0.4/adm/deletable_action_event" \
    -H 'Accept: application/json'

# delete platform (and cascading also actions, ...) so they can be created again
echo -e "\n\nPUT $BASE_URL/v0.4/adm/platform"
cat data/platform.json | sed "s/\"deleted\": false/\"deleted\": true/g" | \
curl -s -f -u admin:$ADMIN_PASSWORD -X PUT "$BASE_URL/v0.4/adm/platform" \
    -H 'Content-Type: application/json' \
    -d @-

# delete user so it can be created again
echo -e "\n\nDELETE $BASE_URL/v0.4/user"
curl -s -f -u admin:$ADMIN_PASSWORD -X DELETE "$BASE_URL/v0.4/user" \
    -H 'Content-Type: application/json' \
    -H 'id: 0'

# ap routes
# create platform and ap requires ap self auth
entities=(platform action_provider)
for entity in "${entities[@]}"; do
    echo -e "\n\nPOST $BASE_URL/v0.4/ap/$entity"
    curl -s -f -X POST "$BASE_URL/v0.4/ap/$entity" \
        -H 'Content-Type: application/json' \
        -d @data/$entity.json
    echo -e "\n\nGET $BASE_URL/v0.4/ap/$entity" \
    curl -s -f -u $AP_USERNAME:$AP_PASSWORD "$BASE_URL/v0.4/ap/$entity" \
        -H 'Accept: application/json'
done

echo -e "\n\nPOST $BASE_URL/v0.4/ap/action"
curl -s -f -u $AP_USERNAME:$AP_PASSWORD -X POST "$BASE_URL/v0.4/ap/action" \
    -H 'Content-Type: application/json' \
    -d @data/action.json
echo -e "\n\nGET $BASE_URL/v0.4/ap/action"
curl -s -f -u $AP_USERNAME:$AP_PASSWORD "$BASE_URL/v0.4/ap/action" \
    -H 'Accept: application/json'

echo -e "\n\nDELETE $BASE_URL/v0.4/ap/action_event"
curl -s -f -u $AP_USERNAME:$AP_PASSWORD -X DELETE "$BASE_URL/v0.4/ap/action_event" \
    -H 'Content-Type: application/json' \
    -d '[]'

echo -e "\n\nGET $BASE_URL/v0.4/ap/executable_action_event"
curl -s -f -u $AP_USERNAME:$AP_PASSWORD "$BASE_URL/v0.4/ap/executable_action_event" \
    -H 'Accept: application/json'

# user routes
# create user requires user self auth
echo -e "\n\nPOST $BASE_URL/v0.4/user"
curl -s -f -X POST "$BASE_URL/v0.4/user" \
    -H 'Content-Type: application/json' \
    -d @data/user.json
echo -e "\n\nGET $BASE_URL/v0.4/user"
curl -s -f -u $USERNAME:$PASSWORD "$BASE_URL/v0.4/user" \
    -H 'Accept: application/json' 
echo -e "\n\nPUT $BASE_URL/v0.4/user"
curl -s -f -u $USERNAME:$PASSWORD -X PUT "$BASE_URL/v0.4/user" \
    -H 'Content-Type: application/json' \
    -d @data/user.json

# get_app_info and download_app not tested

echo -e "\n\nGET $BASE_URL/v0.4/account_data"
curl -s -f -u $USERNAME:$PASSWORD -X GET "$BASE_URL/v0.4/account_data" \
    -H 'Accept: application/json' \
    -H 'Content-Type: application/json' \
    -d 'null'

entities=(movement diary strength_session strength_set metcon metcon_movement metcon_session route cardio_session platform_credential action_rule action_event)
for entity in "${entities[@]}"; do
    echo -e "\n\nPOST $BASE_URL/v0.4/$entity"
    curl -s -f -u $USERNAME:$PASSWORD -X POST "$BASE_URL/v0.4/$entity" \
        -H 'Content-Type: application/json' \
        -d @data/$entity.json
    echo -e "\n\nGET $BASE_URL/v0.4/$entity"
    curl -s -f -u $USERNAME:$PASSWORD "$BASE_URL/v0.4/$entity" \
        -H 'Accept: application/json' 
    echo -e "\n\nPUT $BASE_URL/v0.4/$entity"
    curl -s -f -u $USERNAME:$PASSWORD -X PUT "$BASE_URL/v0.4/$entity" \
        -H 'Content-Type: application/json' \
        -d @data/$entity.json
done

echo -e "\n\nGET $BASE_URL/v0.4/platform"
curl -s -f -u $USERNAME:$PASSWORD "$BASE_URL/v0.4/platform" \
    -H 'Accept: application/json' 
echo -e "\n\nGET $BASE_URL/v0.4/action_provider"
curl -s -f -u $USERNAME:$PASSWORD "$BASE_URL/v0.4/action_provider" \
    -H 'Accept: application/json' 
echo -e "\n\nGET $BASE_URL/v0.4/action"
curl -s -f -u $USERNAME:$PASSWORD "$BASE_URL/v0.4/action" \
    -H 'Accept: application/json' 
echo -e "\n\nGET $BASE_URL/v0.4/eorm"
curl -s -f -u $USERNAME:$PASSWORD "$BASE_URL/v0.4/eorm" \
    -H 'Accept: application/json' 

echo -e "\n\nDELETE $BASE_URL/v0.4/user"
curl -s -f -u $USERNAME:$PASSWORD -X DELETE "$BASE_URL/v0.4/user"