import requests
import json
import argparse
import time
import sys
from vlz_api_functions import (
    APIError,
    signin,
    wait_for_nodes_online,
    assign_all,
    wait_for_media_assigned,
    get_nodes,
    create_policy,
    create_volume,
    create_attachment
)

OCI_URL = "https://oci.api.volumez.com"

def post_request(url, token, json_payload):
    try:
        headers = {'authorization': token} if token else {}
        response = requests.post(url=url, json=json_payload, headers=headers)
        response.raise_for_status()
        return response
    except requests.exceptions.RequestException as e:
        raise APIError(f"POST request failed: {str(e)}")

def get_request(url, token):
    try:
        headers = {'authorization': token} if token else {}
        response = requests.get(url=url, headers=headers)
        response.raise_for_status()
        return response
    except requests.exceptions.RequestException as e:
        raise APIError(f"GET request failed: {str(e)}")

def get_media(base_url, token):
    try:
        endpoint = "media"
        url = f"{base_url}/{endpoint}"
        res = get_request(url, token)
        return res
    except APIError as e:
        print(f"Failed to get media: {str(e)}")
        sys.exit(1)
    
def assign(base_url, media_id, token):
    try:
        endpoint = "media"
        url = f"{base_url}/{endpoint}/{media_id}/assign"
        res = get_request(url, token)
        print(f"{media_id} assigning, jobId={res.text}")
    except APIError as e:
        print(f"Failed to assign media {media_id}: {str(e)}")
        sys.exit(1)
        
def get_job(base_url, token, job_id):
    try:
        endpoint = "jobs"
        url = f"{base_url}/{endpoint}/{job_id}"
        res = get_request(url, token)
        return res
    except APIError as e:
        print(f"Failed to get job {job_id}: {str(e)}")
        sys.exit(1)

def wait_for_job(base_url, token, job_id, max_retries=60, retry_interval=5):
    try:
        for attempt in range(max_retries):
            res = get_job(base_url, token, job_id)
            job = json.loads(res.text)
            print(f'waiting for {job["type"]} to complete')
            if job["state"] == "done":
                print(f'job {job["type"]} completed')
                return 0
            elif job["state"] == "error":
                raise APIError(f'job {job["type"]} failed')
            time.sleep(retry_interval)
        raise APIError(f'job {job["type"]} did not complete within the maximum retry period')
    except (APIError, json.JSONDecodeError) as e:
        print(f"Error waiting for job: {str(e)}")
        sys.exit(1)
    
def main():
    try:
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
        time.sleep(30)
        assign_all(OCI_URL, token)
        wait_for_media_assigned(OCI_URL, token)
        
        nodes = get_nodes(OCI_URL, token)
        zone = nodes.json()[0]["zone"]
        app_node = None
        for node in nodes.json():
            if "app" in node["label"]:
                app_node = node
                break
        
        if not app_node:
            raise APIError("No app node found in the nodes list")
        
        policy_body = {
            "name": env_size.lower(),
            "iopswrite": 80000 if env_size == "Small" else 150000 if env_size == "Medium" else 300000,
            "iopsread": 160000 if env_size == "Small" else 300000 if env_size == "Medium" else 600000,
            "bandwidthwrite": 600 if env_size == "Small" else 1300 if env_size == "Medium" else 2400,
            "bandwidthread": 1200 if env_size == "Small" else 2800 if env_size == "Medium" else 4800,
            "latencywrite": 500,
            "latencyread": 500,
            "localzoneread": True,
            "capacityoptimization": "performance",
            "capacityreservation": 100,
            "resiliencymedia": 1,
            "resiliencynode": 1,
            "resiliencyzone": 0,
            "encryption": False,
            "sed": False,
        }
        create_policy(OCI_URL, token, policy_body)
        for i in range(2):
            vol_name = f"volume{i+1}"
            volume_body = {
                "name": vol_name,
                "type": "file",
                "size": 512 if i == 1 else 2500 if env_size == "Small" else 6000 if env_size == "Medium" else 10000,
                "policy": env_size.lower(),
                "zone": zone,   
            }
            create_volume(OCI_URL, token, volume_body)
        
        mounts = ["/mnt/volumez/pg_vol", "/mnt/volumez/pg_wal"]
        for i in range(2):
            vol_name = f"volume{i+1}"
            attachment_body = {
                "volume": vol_name,
                "snapshot": "top",
                "node": app_node["name"],
                "mountpoint": mounts[i],
            }
            create_attachment(OCI_URL, token, attachment_body, vol_name)
            
    except Exception as e:
        print(f"An unexpected error occurred: {str(e)}")
        sys.exit(1)
    
if __name__=="__main__":
    main()