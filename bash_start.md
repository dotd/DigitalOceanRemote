# Background
from: https://docs.digitalocean.com/reference/doctl/how-to/install/

### Step 1: install doctl
```
brew install doctl
```
### Step 2: create token
Explanation: https://docs.digitalocean.com/reference/api/create-personal-access-token/

Link: https://cloud.digitalocean.com/account/api/tokens

### Step 3: Use the API token to grant account access to doctl

```
# Initiate new context
doctl auth init --context digital_ocean_remote

# Show contexts
doctl auth list

# Swith to the context
doctl auth switch --context  digital_ocean_remote

# Show account basics
doctl account get

# Create a droplet
doctl compute droplet create --region sfo2 --image ubuntu-24-04-x64 --size s-1vcpu-1gb doserver

# Erasing:
doctl compute droplet delete <DROPLET-ID>
```

### How to know to where to do ssh?
```
# General information on droplets
doctl compute droplet list

# Specific ip4:
doctl compute droplet get doserver --format PublicIPv4
```

