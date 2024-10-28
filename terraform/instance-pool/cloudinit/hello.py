import requests
import json
import argparse
import time

OCI_URL = "https://oci.api.volumez.com"

def post_request(url, token, json_payload):
    headers = {'authorization': token} if token else {}
    return requests.post(url=url, json=json_payload, headers=headers)

def get_request(url, token):
    headers = {'authorization': token} if token else {}
    return requests.get(url=url, headers=headers)

def signin(base_url, email, password):
    endpoint = "signin"
    url = f"{base_url}/{endpoint}"
    creds = {
        "email": email,
        "password": password
    } 
    res = post_request(url, None, creds)
    if res.status_code != 200:
        print("failed to signin")
        return
    return res
    

def get_nodes(base_url, token):
    endpoint = "nodes"
    url = f"{base_url}/{endpoint}"
    res = get_request(url, token)
    if res.status_code != 200:
        print("failed to get nodes")
        return
    return res

def wait_for_nodes_online(base_url, token, max_retries=40, retry_interval=10):
    for attempt in range(max_retries):
        print("waiting for nodes to come online")
        res = get_nodes(base_url, token)
        nodes = json.loads(res.text)
        if all([node["state"] == "online" for node in nodes]):
            print("nodes are online")
            return
        time.sleep(retry_interval)
    print("nodes did not come online")
    exit(1)
    
def get_media(base_url, token):
    endpoint = "media"
    url = f"{base_url}/{endpoint}"
    res = get_request(url, token)
    if res.status_code != 200:
        print("failed to get media")
        return
    return res
    
def assign(base_url, media_id, token):
    endpoint = "media"
    url = f"{base_url}/{endpoint}/{media_id}/assign"
    res = get_request(url, token)
    if res.status_code != 200:
        print("failed to assign")
    else:
        print(f"{media_id} assigning, jobId={res.text}")
        
def assign_all(base_url, token):
    endpoint = "media"
    url = f"{base_url}/{endpoint}"
    res = get_request(url, token)
    if res.status_code != 200:
        print("failed to get media")
        return
    media = json.loads(res.text)
    for m in media:
        if m["state"] == "free" and m["type"] == "SSD":
            assign(base_url, m["id"], token)
            
def wait_for_media_assigned(base_url, token, max_retries=40, retry_interval=10):
    for attempt in range(max_retries):
        print("waiting for media to be assigned")
        res = get_media(base_url, token)
        medias = json.loads(res.text)
        filtered_medias = [media for media in medias if media["type"] == "SSD"]
        if all([media["state"] == "assigned" for media in filtered_medias]):
            print("media are assigned")
            return
        time.sleep(retry_interval)
    print("media did not get assigned")
    exit(1)
    



def main():
    parser = argparse.ArgumentParser("hello.py")
    parser.add_argument("email", help='cognito email')
    parser.add_argument("password", help='cognito password')
    args = parser.parse_args()

    res = signin(OCI_URL, args.email, args.password)
    res = json.loads(res.text)
    token = res['IdToken'] 
    
    wait_for_nodes_online(OCI_URL, token)
    assign_all(OCI_URL, token)
    wait_for_media_assigned(OCI_URL, token)
    
        
# Main execution
if __name__=="__main__":
    main()