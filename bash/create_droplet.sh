#!/bin/bash

# ==============================================================================
#           DigitalOcean Droplet Creation Script
#
# This script automates the process of creating a DigitalOcean Droplet.
# It ensures an SSH key exists, uploads it to your DigitalOcean account,
# and then creates a Droplet configured to use that key for access.
#
# Prerequisites:
#   - `doctl` command-line tool installed and authenticated.
#   - `ssh-keygen` command available on your system.
# ==============================================================================

# --- Configuration ---
# Set your desired Droplet name and the name for the SSH key in DigitalOcean.
DROPLET_NAME="my-web-server-01"
SSH_KEY_FULL_PATH="$HOME/.ssh/id_rsa_key1"
SSH_KEY_ASSOCIATION_NAME="my-automation-key"

# Set your desired Droplet specifications.
# Find slugs with: `doctl compute region list`, `doctl compute size list`, `doctl compute image list-distribution`
REGION="nyc3"
SIZE="s-1vcpu-1gb"
IMAGE="ubuntu-24-04-x64"

# --- Script ---
# Exit immediately if a command exits with a non-zero status.
set -e

echo "🚀 Starting Droplet creation process..."

# --- Check for Prerequisites ---
if ! command -v doctl &> /dev/null; then
    echo "❌ Error: 'doctl' command not found. Please install the DigitalOcean CLI and authenticate it."
    exit 1
fi
if ! command -v ssh-keygen &> /dev/null; then
    echo "❌ Error: 'ssh-keygen' command not found, which is required to create SSH keys."
    exit 1
fi

# --- Step 1: Ensure Local SSH Key Exists ---
echo "🔑 Checking for local SSH key..."
SSH_PUBLIC_KEY_PATH="$SSH_KEY_FULL_PATH.pub"
SSH_PRIVATE_KEY_PATH="$SSH_KEY_FULL_PATH"
echo "SSH_PUBLIC_KEY_PATH: $SSH_PUBLIC_KEY_PATH"
echo "SSH_PRIVATE_KEY_PATH: $SSH_PRIVATE_KEY_PATH"

# Some helping commands
# Show ssh keys
echo "ls -lath ~/.ssh/:"
ls -lath ~/.ssh/

# Show ssh key fingerprints
echo "Show ssh key fingerprints:"
doctl compute ssh-key list --no-header

# remove keys without confirmation
# doctl compute ssh-key delete <KEY-ID> --force

if [ ! -f "$SSH_PRIVATE_KEY_PATH" ]; then
    echo "   SSH key not found at '$SSH_PRIVATE_KEY_PATH'. Generating a new one..."
    # Generate a new SSH key without a passphrase non-interactively.
    ssh-keygen -t rsa -b 4096 -f "$SSH_PRIVATE_KEY_PATH" -N ""
    echo "   ✅ New SSH key generated."
else
    echo "   ✅ SSH key already exists locally."
fi

ls -lath ~/.ssh/

# --- Step 2: Import SSH Key to DigitalOcean ---
echo "☁️  Checking for SSH key in your DigitalOcean account..."

# Get the fingerprint of the key if it already exists in the account.
KEY_FINGERPRINT=$(doctl compute ssh-key list --format Name,FingerPrint --no-header | grep "$SSH_KEY_ASSOCIATION_NAME" | awk '{print $2}')
echo "KEY_FINGERPRINT: $KEY_FINGERPRINT"

if [ -z "$KEY_FINGERPRINT" ]; then
    echo "   SSH key '$SSH_KEY_ASSOCIATION_NAME' not found in DigitalOcean. Importing..."
    # Import the key and capture the output to get the fingerprint.
    IMPORT_OUTPUT=$(doctl compute ssh-key import "$SSH_KEY_ASSOCIATION_NAME" --public-key-file "$SSH_PUBLIC_KEY_PATH" --format FingerPrint --no-header)
    KEY_FINGERPRINT=$IMPORT_OUTPUT
    echo "   ✅ Key imported successfully. Fingerprint: $KEY_FINGERPRINT"
else
    echo "   ✅ SSH key '$SSH_KEY_NAME' already exists in your account."
fi
echo "After import:"
doctl compute ssh-key list 

echo "KEY_FINGERPRINT: $KEY_FINGERPRINT"
if [ -z "$KEY_FINGERPRINT" ]; then
    echo "❌ Error: Could not find or import the SSH key fingerprint. Exiting."
    exit 1
fi

# --- Step 3: Create DigitalOcean Droplet ---
echo "💧 Checking if Droplet '$DROPLET_NAME' already exists..."

# Check if a droplet with the same name already exists to avoid errors.
if doctl compute droplet list --format Name --no-header | grep -w -q "$DROPLET_NAME"; then
    echo "   Droplet '$DROPLET_NAME' already exists. Skipping creation."
else
    echo "   Creating Droplet '$DROPLET_NAME'... This might take a few minutes."
    doctl compute droplet create "$DROPLET_NAME" \
      --size "$SIZE" \
      --image "$IMAGE" \
      --region "$REGION" \
      --ssh-keys "$KEY_FINGERPRINT" \
      --wait # The --wait flag pauses the script until the Droplet is active.
    echo "   ✅ Droplet created successfully."
fi


# --- Step 4: Retrieve Droplet IP and Display Info ---
echo "🌐 Retrieving Droplet IP address..."
DROPLET_IP=$(doctl compute droplet get "$DROPLET_NAME" --format PublicIPv4 --no-header)

if [ -z "$DROPLET_IP" ]; then
    echo "❌ Error: Could not retrieve IP address for Droplet '$DROPLET_NAME'."
    exit 1
fi

echo ""
echo "--------------------------------------------------------"
echo "🎉 Droplet is Ready!"
echo ""
echo "   Name:         $DROPLET_NAME"
echo "   IP Address:   $DROPLET_IP"
echo "   Region:       $REGION"
echo "   Image:        $IMAGE"
echo ""
echo "   To connect to your Droplet, run:"
echo "   ssh root@$DROPLET_IP"
echo "--------------------------------------------------------"

