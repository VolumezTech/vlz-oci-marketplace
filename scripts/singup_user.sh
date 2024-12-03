#!/bin/bash

# Check if the correct number of arguments are provided
if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <email> <password>"
  exit 1
fi

EMAIL="$1"
PASSWORD="$2"

echo "Signing up user with email: $EMAIL"

curl -X POST \
  https://oci.api.volumez.com/signup \
  -H 'Content-Type: application/json' \
  -d "{
    \"email\": \"$EMAIL\",
    \"name\": \"name\",
    \"password\": \"$PASSWORD\",
    \"cloudProvider\": \"oracle\"
  }"