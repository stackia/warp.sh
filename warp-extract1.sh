#!/bin/bash

# Script to read a keychain item named 'WARPSecret'

# Check if running on macOS
if [[ "$(uname)" != "Darwin" ]]; then
  echo "Error: This script only works on macOS."
  exit 1
fi

# Read the keychain item
WARP_SECRET=$(security find-generic-password -a "WARPSecret" -s "WARP" -w 2>/dev/null)

if [ $? -eq 0 ]; then
  echo "Successfully retrieved WARPSecret from keychain."
else
  echo "Error: Could not find keychain item 'WARPSecret'"
  echo "You may need to create this item in Keychain Access first."
  exit 1
fi

# Extract the registration_id, secret_key, api_token
DEVICE_ID=$(echo "$WARP_SECRET" | jq -r '.registration_id[0]')
PRIVATE_KEY=$(echo "$WARP_SECRET" | jq -r '.secret_key')
API_TOKEN=$(echo "$WARP_SECRET" | jq -r '.api_token')

CLIENT_ID=$(curl \
  --header 'User-Agent: 1.1.1.1/6.81' \
  --header 'CF-Client-Version: a-6.81-2410012252.0' \
  --header 'Accept: application/json; charset=UTF-8' \
  --tls-max 1.2 \
  --ciphers 'ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES256-CCM:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-CCM:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES256-SHA:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES128-SHA:AES256-GCM-SHA384:AES256-CCM:AES128-GCM-SHA256:AES128-CCM:AES256-SHA256:AES128-SHA256:AES256-SHA:AES128-SHA:DHE-RSA-AES256-GCM-SHA384:DHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES256-CCM:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES128-CCM:DHE-RSA-AES256-SHA256:DHE-RSA-AES128-SHA256:DHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA' \
  --disable \
  --silent \
  --show-error \
  --fail \
  --header 'Content-Type: application/json' -H "Authorization: Bearer ${API_TOKEN}" \
  "https://api.cloudflareclient.com/v0a2483/reg/t.${DEVICE_ID}" | jq -r '.config.client_id')

echo "Device ID: $DEVICE_ID"
echo "API Token: $API_TOKEN"
echo "Private Key: $PRIVATE_KEY"

# Base64 decode and convert to decimal
# Note: We need to pad the base64 string if needed
CLIENT_ID_HEX=$(echo $CLIENT_ID | base64 -d | xxd -p -c 1)
CLIENT_ID_DECIMAL=$(printf '%s\n' "${CLIENT_ID_HEX}" | while read -r hex; do printf "%d, " "0x${hex}"; done)
CLIENT_ID_DECIMAL="${CLIENT_ID_DECIMAL%, }"
echo "Client ID (OpenClash): [$CLIENT_ID_DECIMAL]"
CLIENT_ID_SURGE=$(echo "$CLIENT_ID_DECIMAL" | sed 's/, /\//g')
echo "Client ID (Surge): $CLIENT_ID_SURGE"
