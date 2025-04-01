#!/bin/bash

# Check if the correct number of arguments are provided
if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <email> <password>"
  exit 1
fi

EMAIL="$1"
PASSWORD="$2"

echo "Signing up user with email: $EMAIL"

# Signup request
curl -X POST \
  https://oci.api.volumez.com/signup \
  -H 'Content-Type: application/json' \
  -d "{
    \"email\": \"$EMAIL\",
    \"name\": \"name\",
    \"password\": \"$PASSWORD\",
    \"cloudProvider\": \"oracle\"
  }"

echo -e "\nAttempting to sign in..."

# Signin request - hide output but check status
signin_response=$(curl -s -o /dev/null -w "%{http_code}" -X POST \
  https://oci.api.volumez.com/signin \
  -H 'Content-Type: application/json' \
  -d "{
    \"email\": \"$EMAIL\",
    \"password\": \"$PASSWORD\"
  }")

if [ "$signin_response" -eq 200 ]; then
  echo "Sign in successful!"
else
  echo "Sign in failed with status code: $signin_response"
fi