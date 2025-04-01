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

# Signin request - capture both response body and status code
signin_output=$(curl -s -w "\n%{http_code}" -X POST \
  https://oci.api.volumez.com/signin \
  -H 'Content-Type: application/json' \
  -d "{
    \"email\": \"$EMAIL\",
    \"password\": \"$PASSWORD\"
  }")

# Extract status code from the last line
status_code=$(echo "$signin_output" | tail -n1)
# Extract response body (everything except the last line)
response_body=$(echo "$signin_output" | sed '$d')

if [ "$status_code" -eq 200 ]; then
  echo "Sign in successful!"
else
  echo "Sign in failed with status code: $status_code"
  echo "Error details: $response_body"
fi