import requests
import json
import time
import sys

class APIError(Exception):
    """Base exception for API errors"""
    pass

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

def signin(base_url, email, password):
    try:
        endpoint = "signin"
        url = f"{base_url}/{endpoint}"
        creds = {
            "email": f"{email}",
            "password": f"{password}"
        } 
        res = post_request(url, None, creds)
        return res
    except APIError as e:
        print(f"Failed to signin: {str(e)}")
        sys.exit(1)

def get_nodes(base_url, token):
    try:
        endpoint = "nodes"
        url = f"{base_url}/{endpoint}"
        res = get_request(url, token)
        return res
    except APIError as e:
        print(f"Failed to get nodes: {str(e)}")
        sys.exit(1)

def wait_for_nodes_online(base_url, token, max_retries=40, retry_interval=10):
    try:
        for attempt in range(max_retries):
            print("waiting for nodes to come online")
            res = get_nodes(base_url, token)
            nodes = json.loads(res.text)
            if nodes == []:
                print("no nodes found")
                time.sleep(retry_interval)
                continue
            if all([node["state"] == "online" for node in nodes]):
                print("nodes are online")
                return
            time.sleep(retry_interval)
        raise APIError("Nodes did not come online within the maximum retry period")
    except (APIError, json.JSONDecodeError) as e:
        print(f"Error waiting for nodes: {str(e)}")
        sys.exit(1)

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
        
def assign_all(base_url, token):
    try:
        endpoint = "media"
        url = f"{base_url}/{endpoint}"
        res = get_request(url, token)
        media = json.loads(res.text)
        for m in media:
            if m["assignment"] == "free" and m["media"] == "SSD":
                assign(base_url, m["mediaid"], token)
        return 0
    except (APIError, json.JSONDecodeError) as e:
        print(f"Failed to assign all media: {str(e)}")
        sys.exit(1)
            
def wait_for_media_assigned(base_url, token, max_retries=40, retry_interval=10):
    try:
        for attempt in range(max_retries):
            print("waiting for media to be assigned")
            res = get_media(base_url, token)
            medias = json.loads(res.text)
            filtered_medias = [media for media in medias if media["media"] == "SSD"]
            if all([media["assignment"] == "assigned" for media in filtered_medias]):
                print("media are assigned")
                return
            time.sleep(retry_interval)
        raise APIError("Media did not get assigned within the maximum retry period")
    except (APIError, json.JSONDecodeError) as e:
        print(f"Error waiting for media assignment: {str(e)}")
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
    
def create_policy(base_url, token, policy_body):
    try:
        print(f"creating policy {policy_body['name']}")
        endpoint = "policies"
        url = f"{base_url}/{endpoint}"
        res = post_request(url, token, policy_body)
        print(f"policy {policy_body['name']} created successfully")
        return res
    except APIError as e:
        print(f"Failed to create policy: {str(e)}")
        sys.exit(1)

def create_volume(base_url, token, volume_body):
    try:
        print(f"creating volume {volume_body['name']}")
        endpoint = "volumes"
        url = f"{base_url}/{endpoint}"
        res = post_request(url, token, volume_body)
        job_id = json.loads(res.text)["Message"]
        if wait_for_job(base_url, token, job_id) == 0:
            print(f"volume {volume_body['name']} created successfully")
        return job_id
    except (APIError, json.JSONDecodeError) as e:
        print(f"Failed to create volume: {str(e)}")
        sys.exit(1)

def create_attachment(base_url, token, attachment_body, volume_name, snapshot_name="top"):
    try:
        print(f"creating attachment on volume {volume_name}")
        endpoint = f"volumes/{volume_name}/snapshots/{snapshot_name}/attachments"
        url = f"{base_url}/{endpoint}"
        res = post_request(url, token, attachment_body)
        job_id = json.loads(res.text)["Message"]
        if wait_for_job(base_url, token, job_id) == 0:
            print(f"attachment on volume {volume_name} created successfully")
        return job_id
    except (APIError, json.JSONDecodeError) as e:
        print(f"Failed to create attachment: {str(e)}")
        sys.exit(1) 