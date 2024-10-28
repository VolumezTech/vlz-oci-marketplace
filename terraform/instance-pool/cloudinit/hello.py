import requests
import json

# Base URL for the API
BASE_URL = "https://oci.api.volumez.com"

# Authorization token (replace with your actual token)
AUTH_TOKEN = "eyJraWQiOiJoUEhDVWNDOXVqeHp4eCthUXdHalFDaDlhYVBxVytRR2dBWDhVYWFxNnlVPSIsImFsZyI6IlJTMjU2In0.eyJzdWIiOiI0ODEwZGE5Mi0zMjlmLTRjY2ItYTRkOS1jNmZkNzNhZDM2OTciLCJjb2duaXRvOmdyb3VwcyI6WyJhMmRlNTJmMi1kNTMyLTQzZDAtYTdiYi1lNzllMGI3MzhkNTQiXSwiZW1haWxfdmVyaWZpZWQiOmZhbHNlLCJjb2duaXRvOnByZWZlcnJlZF9yb2xlIjoiYXJuOmF3czppYW06OjIyNTgxMDEzMzE2ODpyb2xlXC9jb2duaXRvLWFwaWdhdGV3YXktc3RvcmluZy5pbyIsImlzcyI6Imh0dHBzOlwvXC9jb2duaXRvLWlkcC51cy1lYXN0LTEuYW1hem9uYXdzLmNvbVwvdXMtZWFzdC0xX2ozOFFhdEt1TSIsImNvZ25pdG86dXNlcm5hbWUiOiI0ODEwZGE5Mi0zMjlmLTRjY2ItYTRkOS1jNmZkNzNhZDM2OTciLCJvcmlnaW5fanRpIjoiNzhiMzhmMTYtYmRmMS00ZGE0LWJkYzMtMmIwNWE1M2E5MzVlIiwiY3VzdG9tOmNvbmZpcm1hdGlvbl9jb2RlIjoiZjY0NzZhNTgtNDg3Zi00YjY2LWJmNDItMWI3OWQ1M2U2ZmU5IiwiY29nbml0bzpyb2xlcyI6WyJhcm46YXdzOmlhbTo6MjI1ODEwMTMzMTY4OnJvbGVcL2NvZ25pdG8tYXBpZ2F0ZXdheS1zdG9yaW5nLmlvIl0sImF1ZCI6IjM0MDU2YTdsdjloZzVvcGI3aGVxanZhZnYwIiwiZXZlbnRfaWQiOiIxNjA2NGQ1MS01NGY1LTQ5YjYtOTM5Yy1hNjg2MGM1MTlmNmYiLCJ0b2tlbl91c2UiOiJpZCIsImF1dGhfdGltZSI6MTczMDExODA1NywibmFtZSI6Ikl0YXkgR2lub3IiLCJleHAiOjE3MzAyMDQ0NTYsImlhdCI6MTczMDExODA1NywianRpIjoiODNmYmRjZjUtYmVkYi00NWY4LWI2MGYtYmEzZmNkOGM0YzQxIiwiZW1haWwiOiJpdGF5Lmdpbm9yQHZvbHVtZXouY29tIn0.G5PgXpuS4WhNAKVCja6BNpiEWHGPw1gfOGHNcKNPCIQ8IrURxMOU6NSHVOO4seQI0-LpfrQM_jbERp9MXep9Gs8iU4AN1lHwdiOQ3i9DCHofcfrti5b4zYOBdikglgwrT6E65CMCN2NoRWBiptB_nb55IfHSWkLaBLyV0UrzBpWANZU3tfZDGnS9MD-I8bq1dzE8sdon3kelLRkPWV3n39F7_T0vMy4lSuSFXuLF1kCw1RiDt8kcQjPk_pU0nYwFHMOGHX1r5RzUcUVcu50oDfOSgqYJd5jA96ZqPyw-0w-o0gGJ6JRISxUYx9456M8Xaj9-UymVipCnVHRFfiNZTQ"

# Headers including authorization
headers = {
    "Authorization": f"{AUTH_TOKEN}",
    "Content-Type": "application/json"
}

def get_request(endpoint):
    """
    Send a GET request to the specified endpoint.
    """
    url = f"{BASE_URL}/{endpoint}"
    response = requests.get(url, headers=headers)
    return response.json()

def post_request(endpoint, data):
    """
    Send a POST request to the specified endpoint with the given data.
    """
    url = f"{BASE_URL}/{endpoint}"
    response = requests.post(url, headers=headers, data=json.dumps(data))
    return response.json()

def put_request(endpoint, data):
    """
    Send a PUT request to the specified endpoint with the given data.
    """
    url = f"{BASE_URL}/{endpoint}"
    response = requests.put(url, headers=headers, data=json.dumps(data))
    return response.json()

# Example usage

# GET request
def get_nodes():
    endpoint = f"nodes"
    return get_request(endpoint)

# POST request
def create_user(user_data):
    endpoint = "users"
    return post_request(endpoint, user_data)

# PUT request
def update_user(user_id, user_data):
    endpoint = f"users/{user_id}"
    return put_request(endpoint, user_data)

# Main execution
if __name__ == "__main__":
    # Example GET request
    nodes = get_nodes()
    print("GET Nodes Info:", nodes)