import time
from pydo import Client
from definitions import PROJECT_ROOT_DIR

def get_digital_ocean_token():
    do_token_file = f"{PROJECT_ROOT_DIR}/api_keys/digital_ocean_token.txt"
    with open(do_token_file, "r") as f:
        do_token = f.read().strip()
    return do_token



# --- Function to get SSH key ID or fingerprint ---
def get_ssh_key_identifier(client, key_name=None, key_fingerprint=None):
    """
    Retrieves the ID or fingerprint of an SSH key from your DigitalOcean account.
    You must have at least one SSH key uploaded to your DigitalOcean account.
    """
    ssh_keys_resp = client.ssh_keys.list()
    ssh_keys = ssh_keys_resp["ssh_keys"]

    if not ssh_keys:
        raise Exception("No SSH keys found in your DigitalOcean account. Please add one via the DigitalOcean control panel or API.")

    if key_name:
        for key in ssh_keys:
            if key["name"] == key_name:
                return key["fingerprint"]  # Or key["id"]
        raise ValueError(f"SSH key with name '{key_name}' not found.")
    elif key_fingerprint:
        for key in ssh_keys:
            if key["fingerprint"] == key_fingerprint:
                return key["fingerprint"]
        raise ValueError(f"SSH key with fingerprint '{key_fingerprint}' not found.")
    else:
        # If no specific key is provided, use the first one found
        print(f"No specific SSH key name or fingerprint provided. Using the first SSH key found: {ssh_keys[0]['name']} ({ssh_keys[0]['fingerprint']})")
        return ssh_keys[0]["fingerprint"]


def create_droplet(
        droplet_name = "my-pydo-ssh-droplet",
        region= "nyc3",  # Choose a region slug (e.g., "nyc1", "sfo2", "lon1")
        size = "s-1vcpu-1gb" , # Choose a Droplet size slug (e.g., "s-1vcpu-1gb", "s-2vcpu-2gb")
        image= "ubuntu-22-04-x64",  # Choose an image slug (e.g., "ubuntu-22-04-x64", "centos-stream-9")
        #ssh_key_fingerprint: str,
        #user_data: str,
        #tags: list[str]
):
    token = get_digital_ocean_token()
    client = Client(token=token)


    try:
        # --- Get SSH key identifier ---
        # Replace 'YOUR_SSH_KEY_NAME' with the name of your SSH key in DigitalOcean
        # or provide a specific fingerprint. If neither is provided, it will use the first key found.
        # ssh_key_to_use = get_ssh_key_identifier(client, key_name="My Laptop SSH Key")
        ssh_key_to_use = get_ssh_key_identifier(client) # Uses the first SSH key found

        # --- Prepare Droplet creation request body ---
        droplet_body = {
            "name": droplet_name,
            "region": region,
            "size": size,
            "image": image,
            "ssh_keys": [ssh_key_to_use],  # Use the fingerprint or ID of your SSH key
            "backups": False,
            "ipv6": True,
            "private_networking": True,
            "monitoring": True,
            "user_data": "#cloud-config\npackages:\n  - nginx\n", # Example user data to install nginx
            "tags": ["pydo-demo", "ssh-droplet"]
        }

        print(f"Attempting to create Droplet '{droplet_name}' in region '{region}'
               with image '{image}' and size '{size}'...")
        print(f"Using SSH key fingerprint: {ssh_key_to_use}")

        # --- Create the Droplet ---
        create_response = client.droplets.create(body=droplet_body)
        droplet_id = create_response["droplet"]["id"]
        print(f"Droplet creation initiated. Droplet ID: {droplet_id}")

        # --- Wait for Droplet to become active ---
        print("Waiting for Droplet to become active...")
        while True:
            droplet_info = client.droplets.get(droplet_id=droplet_id)["droplet"]
            status = droplet_info["status"]
            if status == "active":
                print(f"Droplet '{droplet_name}' is active!")
                break
            elif status == "new":
                print(f"Droplet is still provisioning (status: {status})... Retrying in 10 seconds.")
                time.sleep(10)
            else:
                raise Exception(f"Droplet creation failed with status: {status}")

        # --- Get Droplet IP address ---
        ipv4_address = None
        for network in droplet_info["networks"]["v4"]:
            if network["type"] == "public":
                ipv4_address = network["ip_address"]
                break

        if ipv4_address:
            print(f"\nDroplet '{droplet_name}' successfully created!")
            print(f"Public IP Address: {ipv4_address}")
            print(f"You can now SSH into your Droplet using: ssh root@{ipv4_address}")
        else:
            print("Could not retrieve public IPv4 address for the Droplet.")

    except Exception as e:
        print(f"An error occurred: {e}")

    finally:
        # --- Optional: Clean up (delete the Droplet) ---
        # Uncomment the following lines if you want the script to automatically
        # delete the Droplet after it's created and its IP is displayed.
        # USE WITH CAUTION IN PRODUCTION ENVIRONMENTS!
        #
        # if 'droplet_id' in locals() and droplet_id:
        #     confirm_delete = input("Do you want to delete the created Droplet? (yes/no): ").lower()
        #     if confirm_delete == 'yes':
        #         print(f"Deleting Droplet ID: {droplet_id}...")
        #         try:
        #             client.droplets.delete(droplet_id=droplet_id)
        #             print(f"Droplet ID {droplet_id} deleted successfully.")
        #         except Exception as delete_e:
        #             print(f"Error deleting Droplet: {delete_e}")
        pass # Keep this if you don't want to delete automatically