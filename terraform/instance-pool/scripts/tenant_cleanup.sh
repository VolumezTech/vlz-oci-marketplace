#!/bin/bash

# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'  # No Color

BASE_URL="https://oci.api.volumez.com" 

# Check if both email and password are provided as arguments
if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: $0 <email> <password>"
    exit 1
fi

# Assign arguments to variables
email="$1"
password="$2"

# Construct the JSON payload
payload=$(jq -n \
            --arg email "$email" \
            --arg password "$password" \
            '{email: $email, password: $password}')

# Execute the curl command
response=$(curl -X POST "$BASE_URL/signin" \
     -H "content-type: application/json" \
     -d "$payload")
echo $response
TOKEN=$(echo "$response" | jq -r '.IdToken')
LOG_FILE=tenant_cleanup.log


print_error() {
    local message="$1"
    echo -e "${RED}ERROR:$message${NC}"  # Red color
}

print_ok() {
    local message="$1"
    echo -e "${GREEN}OK:$message${NC}"  # Green color
}

api_get() {
    local url_path=$1
    local cmd
    local limit=1000000  # Seems like paging not implemented
    cmd="curl --fail-with-body -X GET \"$BASE_URL/$url_path/?limit=$limit\" -H 'content-type: application/json' -H \"authorization: $TOKEN\""
    cmd_for_log=$(echo "$cmd" | sed -E 's/-H .*//')
    echo -n "running: $cmd_for_log " >> "$LOG_FILE"
    response=$(eval "$cmd" ) >> "$LOG_FILE"
    if [ $? -eq 0 ]; then
        echo -n "[Success]" >> "$LOG_FILE"
        echo >> "$LOG_FILE"
        echo $response
    else
        echo "[Error]" | tee -a "$LOG_FILE"
        print_error "$cmd Failed"
    fi
}

api_delete() {
    local url_path=$1
    local cmd
    cmd="curl --fail-with-body -X DELETE \"$BASE_URL/$url_path\" -H 'content-type: application/json' -H \"authorization: $TOKEN\""
    cmd_for_log=$(echo "$cmd" | sed -E 's/-H .*//')
    echo -n "running: $cmd_for_log " >> "$LOG_FILE"
    response=$(eval "$cmd" ) >> "$LOG_FILE"
    if [ $? -eq 0 ]; then
        echo -n "[Success]" >> "$LOG_FILE"
        echo >> $LOG_FILE
        echo $response
    else
        echo "$response [Error]" >> "$LOG_FILE"
        print_error "deleting $url_path Failed"
        echo "Trying force"
        cmd="curl --fail-with-body -X DELETE \"$BASE_URL/$url_path?force=true\" -H 'content-type: application/json' -H \"authorization: $TOKEN\""
        cmd_for_log=$(echo "$cmd" | sed -E 's/-H .*//')
        echo -n "running: $cmd_for_log " >> "$LOG_FILE"
        response=$(eval "$cmd" ) >> "$LOG_FILE"
        if [ $? -eq 0 ]; then
            echo  -n "[Success]" >> "$LOG_FILE"
            echo $response
        else
            echo "$response [Error]" >> "$LOG_FILE"
        fi
    fi
}

api_delete_force() {
    local url_path=$1
    local cmd
    cmd="curl --fail-with-body -X DELETE \"$BASE_URL/$url_path/?force=yes\" -H 'content-type: application/json' -H \"authorization: $TOKEN\""
    cmd_for_log=$(echo "$cmd" | sed -E 's/-H .*//')
    echo -n "running: $cmd_for_log " >> "$LOG_FILE"
    response=$(eval "$cmd" ) >> "$LOG_FILE"
    if [ $? -eq 0 ]; then
        echo -n "[Success]" >> "$LOG_FILE"
        echo >> $LOG_FILE
        echo $response
    else
        echo "$response [Error]" >> "$LOG_FILE"
    fi
}


check_token() {
    curl --fail-with-body -X GET $BASE_URL/version -H 'content-type: application/json' -H "authorization: $TOKEN"  > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        print_error "Token is invalid"
        exit 1
    else 
        print_ok "Token is valid"
    fi
}

get_attachments() {
    response=$(api_get "attachments")
    ATTACHMENTS=$(echo "$response" | grep -oE '"(node|snapshotname|volumename)"\s*:\s*"[^"]+"')
}

del_attach() {
    local volid=$1
    local snapid=$2
    local nodeid=$3
    response=$(api_delete_force "volumes/$volid/snapshots/$snapid/attachments/$nodeid")
}

del_attachments() {
    local line1
    local line2
    local line3
    echo "$ATTACHMENTS" | while read -r line1 && read -r line2 && read -r line3; do
        node=$(echo "$line1" | sed -E 's/"node":"([^"]+)"/\1/')
        snapshot=$(echo "$line2" | sed -E 's/"snapshotname":"([^"]+)"/\1/')
        volume=$(echo "$line3" | sed -E 's/"volumename":"([^"]+)"/\1/')
  
        del_attach $volume $snapshot $node
    done
}

del_vol() {
    local name=$1
    api_delete "volumes/$name"
}

del_volumes() {
    response=$(api_get "volumes")    
    VOLUMES=$(echo "$response" | grep -oE '"(name)"\s*:\s*"[^"]+"'|awk -F \: '{print $2}'|xargs)
    for vol in $VOLUMES; do 
        del_vol $vol
    done

}

get_nodes() {
    local limit=1000000  # Seems like paging not implemented 
    response=$(api_get "nodes")

    # Extract all nodes
    NODES_AND_STATUS=$(echo "$response" | grep -oE '"(name|state)"\s*:\s*"[^"]+"'|awk -F \: '{print $2}')
    ONLINE_NODES=$(echo $NODES_AND_STATUS |grep -oE '"[^"]+" "online"' | sed 's/ "online"//')
    OFFLINE_NODES=$(echo $NODES_AND_STATUS |grep -oE '"[^"]+" "offline"' | sed 's/ "offline"//')
}

del_node() {
    local name=$1
    response=$(api_delete "nodes/$name")
}

del_nodes() {
    for node in $(echo $ONLINE_NODES | xargs); do
        del_node $node
    done
    for node in $(echo $OFFLINE_NODES | xargs); do
        del_node $node
    done
}

unassing_media() {
    #TODO: move unassing to patch
    local media_id=$1
    api_get media/$media_id/unassign
}

unassing_medias() {
    local all_medias
    local media_id
    local line1
    local line2
    response=$(api_get "media")
    all_medias=$(echo $response |grep -oE '"(mediaid|assignment)"\s*:\s*"[^"]+"')
    # echo $all_medias

    echo "$all_medias" | while read -r line1 && read -r line2; do
        media_id=$(echo "$line1" | sed -E 's/"mediaid":"([^"]+)"/\1/')
        assignment=$(echo "$line2" | sed -E 's/"assignment":"([^"]+)"/\1/')
        if [[ "$assignment" == "assigned" ]] ; then
            unassing_media $media_id
        fi
    done
}

wait_for_running_jobs() {
    while true; do
        num_of_running_jobs=$(api_get "jobs" | grep -o '"progress":[0-9]\{1,3\}' | grep -v "100" | wc -l)
        if [ "$num_of_running_jobs" -eq 0 ]; then
            break
        fi
        sleep 2
    done
}

fresh_log() {
    cat /dev/null > $LOG_FILE  
}

# main #

# 0. init 
fresh_log
check_token

# 1. delete attachments 
get_attachments
del_attachments
wait_for_running_jobs

# 2. delete volumes
del_volumes
wait_for_running_jobs

# 3.unassing medias
unassing_medias
wait_for_running_jobs

# 4. delete nodes
get_nodes
del_nodes