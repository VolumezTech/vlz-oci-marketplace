import requests
import json
import argparse
import time

OCI_URL = "https://oci.api.volumez.com"
VOL_NAME = "vol1"


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
        if m["assignment"] == "free" and m["media"] == "SSD":
            assign(base_url, m["mediaid"], token)
    return 0
            
def wait_for_media_assigned(base_url, token, max_retries=40, retry_interval=10):
    for attempt in range(max_retries):
        print("waiting for media to be assigned")
        res = get_media(base_url, token)
        medias = json.loads(res.text)
        filtered_medias = [media for media in medias if media["media"] == "SSD"]
        if all([media["assignment"] == "assigned" for media in filtered_medias]):
            print("media are assigned")
            return
        time.sleep(retry_interval)
    print("media did not get assigned")
    exit(1)
    
def get_job(base_url, token, job_id):
    endpoint = "jobs"
    url = f"{base_url}/{endpoint}/{job_id}"
    res = get_request(url, token)
    if res.status_code != 200:
        print("failed to get jobs")
        return
    return res

def wait_for_job(base_url, token, job_id, max_retries=40, retry_interval=2):
    for attempt in range(max_retries):
        res = get_job(base_url, token, job_id)
        job = json.loads(res.text)
        print(f'waiting for {job["type"]} to complete')
        if job["state"] == "done":
            print(f'job {job["type"]} completed')
            return 0
        elif job["state"] == "error":
            print(f'job {job["type"]} failed')
            exit(1)
        time.sleep(retry_interval)
    print(f'job {job["type"]} did not complete')
    exit(1)
    
def create_policy(base_url, token, policy_body):
    print(f"creating policy {policy_body['name']}")
    endpoint = "policies"
    url = f"{base_url}/{endpoint}"
    res = post_request(url, token, policy_body)
    if res.status_code != 200:
        print("failed to create policy: ", res.text)
        return
    print(f"policy {policy_body['name']} created successfully")
    return res

def create_volume(base_url, token, volume_body):
    print(f"creating volume {volume_body['name']}")
    endpoint = "volumes"
    url = f"{base_url}/{endpoint}"
    res = post_request(url, token, volume_body)
    if res.status_code != 200:
        print("failed to create volume: ", res.text)
        return
    job_id = json.loads(res.text)["Message"]
    if wait_for_job(base_url, token, job_id) == 0:
        print(f"volume {volume_body['name']} created successfully")
    return job_id

def create_attachment(base_url, token, attachment_body, volume_name, snapshot_name="top"):
    print(f"creating attachment on volume {volume_name}")
    endpoint = f"volumes/{volume_name}/snapshots/{snapshot_name}/attachments"
    url = f"{base_url}/{endpoint}"
    res = post_request(url, token, attachment_body)
    if res.status_code != 200:
        print("failed to create attachment: ", res.text)
        return
    job_id = json.loads(res.text)["Message"]
    if wait_for_job(base_url, token, job_id) == 0:
        print(f"attachment on volume {volume_name} created successfully")
    return job_id
    

def main():
    parser = argparse.ArgumentParser("hello.py")
    parser.add_argument("email", help='cognito email')
    parser.add_argument("password", help='cognito password')
    parser.add_argument("envSize", help='Environment Size (Small/Medium/Large)', default="Small")
    args = parser.parse_args()

    res = signin(OCI_URL, args.email, args.password)
    res = json.loads(res.text)
    token = res['IdToken'] 
    env_size = args.envSize

    wait_for_nodes_online(OCI_URL, token)
    assign_all(OCI_URL, token)
    wait_for_media_assigned(OCI_URL, token)
    
    nodes = get_nodes(OCI_URL, token)
    zone = nodes.json()[0]["zone"]
    app_node = None
    for node in nodes.json():
        if "app" in node["label"]:
            app_node = node
            break
    
    policy_body = {
        "name": env_size,
        "iopswrite": 80000 if env_size == "Small" else 160000 if env_size == "Medium" else 320000,
        "iopsread": 160000 if env_size == "Small" else 320000 if env_size == "Medium" else 640000,
        "bandwidthwrite": 600 if env_size == "Small" else 1200 if env_size == "Medium" else 2400,
        "bandwidthread": 1200 if env_size == "Small" else 2400 if env_size == "Medium" else 4800,
        "latencywrite": 500,
        "latencyread": 500,
        "localzoneread": True,
        "capacityoptimization": "performance",
        "capacityreservation": 100,
        "resiliencymedia": 0,
        "resiliencynode": 1,
        "resiliencyzone": 0,
        "encryption": False,
        "sed": False,
    }
    create_policy(OCI_URL, token, policy_body)
    
    volume_body = {
        "name": VOL_NAME,
        "type": "file",
        "size": 5000 if env_size == "Small" else 15000 if env_size == "Medium" else 20000,
        "policy": env_size,
        "zone": zone,   
    }
    create_volume(OCI_URL, token, volume_body)
    
    attachment_body = {
        "volume": VOL_NAME,
        "snapshot": "top",
        "node": app_node["name"],
    }
    create_attachment(OCI_URL, token, attachment_body, VOL_NAME)
    
if __name__=="__main__":
    main()