#!/bin/bash

# Fetch all SSH key IDs and names
keys=$(doctl compute ssh-key list --format "ID,Name" --no-header)

# Check if there are any keys to delete
if [ -z "$keys" ]; then
  echo "No SSH keys found to delete."
  exit 0
fi

echo "The following SSH keys will be deleted:"
echo "$keys"
echo

# Ask for confirmation before proceeding
read -p "Are you sure you want to delete all of these SSH keys? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Aborted."
  exit 1
fi

# Loop through each key and delete it
while IFS= read -r line; do
  key_id=$(echo "$line" | awk '{print $1}')
  key_name=$(echo "$line" | awk '{print $2}')
  echo "Deleting SSH key: ID - $key_id, Name - $key_name"
  doctl compute ssh-key delete "$key_id" --force
done <<< "$keys"

# Show all keys
echo "--------------------------------"
doctl compute ssh-key list 
echo "--------------------------------"

echo "All imported SSH keys have been deleted."
