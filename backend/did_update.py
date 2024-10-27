# did_update.py

from subprocess import run

def update_did(did, new_key=None, new_service=None):
    command = ["algoid", "edit", did]

    if new_key:
        command += ["key", "add", "--name", new_key]
    if new_service:
        command += ["service", "add", "--service", new_service]

    run(command)
    print("DID updated successfully.")
