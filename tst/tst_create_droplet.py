from src import digital_ocean_utils

def tst_create_droplet():
    digital_ocean_utils.get_ssh_key_identifier()
    #digital_ocean_utils.create_droplet()

if __name__ == "__main__":
    tst_create_droplet()
