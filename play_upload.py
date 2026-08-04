#!/usr/bin/env python3
"""
RideKSA - Google Play CLI uploader.

Uploads an AAB and manages app drafts/releases via the Play Developer API.

Prereqs (one-time, in Play Console web UI):
  1. Setup > API access > "Create new service account" -> link GCP project
     rideksa-84949, grant a role, then download the JSON key.
  2. Make sure an app entry exists for com.galaxylabs.ftms.

Usage:
  python play_upload.py --key service-account.json --aab app-release.aab
  python play_upload.py --key service-account.json --list
  python play_upload.py --key service-account.json --create-app
"""
import argparse
import os
import sys

from google.oauth2 import service_account
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload

PACKAGE = "com.galaxylabs.ftms"
SCOPES = ["https://www.googleapis.com/auth/androidpublisher"]


def get_service(key_path):
    creds = service_account.Credentials.from_service_account_file(key_path, scopes=SCOPES)
    return build("androidpublisher", "v3", credentials=creds)


def list_apps(service):
    try:
        result = service.edits().insert(body={}, packageName=PACKAGE).execute()
        print(f"App reachable. Edit id: {result.get('id')}")
    except Exception as e:
        print(f"App NOT reachable: {e}")


def create_app(service):
    body = {
        "packageName": PACKAGE,
        "languageCode": "en-US",
        "primaryLanguageCode": "en-US",
        "applicationLabel": "RideKSA",
    }
    try:
        result = service.applications().insert(body=body).execute()
        print("App created:", result)
    except Exception as e:
        print(f"Create failed: {e}")


def upload_aab(service, aab_path):
    edits = service.edits()
    edit = edits.insert(body={}, packageName=PACKAGE).execute()
    edit_id = edit["id"]
    print(f"Edit created: {edit_id}")

    media = MediaFileUpload(aab_path, mimetype="application/octet-stream", resumable=True)
    bundle = edits.bundles().upload(
        packageName=PACKAGE, editId=edit_id, media_body=media
    ).execute()
    version_code = bundle.get("versionCode")
    print(f"AAB uploaded, versionCode={version_code}")

    track = {
        "releases": [{
            "name": "Internal testing",
            "status": "completed",
            "versionCodes": [version_code],
            "releaseNotes": [{
                "language": "en-US",
                "text": "RideKSA internal testing build.",
            }],
        }]
    }
    edits.tracks().update(
        packageName=PACKAGE, editId=edit_id, track="internal", body=track
    ).execute()
    print("Release assigned to 'internal' track")

    edits.commit(packageName=PACKAGE, editId=edit_id).execute()
    print("Edit committed -> build is now in Internal testing on Play Console")


def upload_closed_testing(service, aab_path, countries, release_notes, tester_group=None):
    edits = service.edits()
    edit = edits.insert(body={}, packageName=PACKAGE).execute()
    edit_id = edit["id"]
    print(f"Edit created: {edit_id}")

    media = MediaFileUpload(aab_path, mimetype="application/octet-stream", resumable=True)
    bundle = edits.bundles().upload(
        packageName=PACKAGE, editId=edit_id, media_body=media
    ).execute()
    version_code = bundle.get("versionCode")
    print(f"AAB uploaded, versionCode={version_code}")

    existing_codes = []
    existing_status = None
    try:
        track = edits.tracks().get(packageName=PACKAGE, editId=edit_id, track="alpha").execute()
        for rel in track.get("releases", []):
            existing_codes.extend(int(v) for v in rel.get("versionCodes", []))
            existing_status = rel.get("status")
    except Exception as e:
        print(f"Could not read existing alpha track: {e}")
    all_codes = [version_code]
    print(f"Replacing alpha release versionCodes with: {all_codes} (existing: {existing_codes} status={existing_status})")

    release = {
        "name": "Closed testing",
        "status": "completed",
        "versionCodes": all_codes,
        "releaseNotes": [{
            "language": "en-US",
            "text": release_notes,
        }],
    }

    edits.tracks().update(
        packageName=PACKAGE, editId=edit_id, track="alpha", body={"releases": [release]}
    ).execute()
    print("Release assigned to 'alpha' (closed testing) track")

    if tester_group:
        edits.testers().update(
            packageName=PACKAGE, editId=edit_id, track="alpha",
            body={"googleGroups": [tester_group]},
        ).execute()
        print(f"Testers (google group) set: {tester_group}")
    else:
        print("WARNING: no tester Google Group provided - add testers in Play Console UI")

    edits.commit(packageName=PACKAGE, editId=edit_id).execute()
    print("Edit committed -> closed testing release created")

    if countries:
        print("NOTE: country availability for testing tracks must be set in the Play Console UI "
              "(API country targeting is production-only). Requested countries: " + ",".join(countries))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--key", required=True, help="Path to service account JSON key")
    parser.add_argument("--aab", help="Path to the AAB file to upload")
    parser.add_argument("--list", action="store_true", help="Check app is reachable")
    parser.add_argument("--create-app", action="store_true", help="Create app draft")
    parser.add_argument("--closed-testing", action="store_true",
                        help="Upload AAB as a closed testing (alpha) release")
    parser.add_argument("--countries", nargs="+", default=[],
                        help="Country codes for the closed testing track, e.g. SA AE")
    parser.add_argument("--release-notes", default="RideKSA closed testing build.",
                        help="Release notes text (en-US)")
    parser.add_argument("--tester-group", default="",
                        help="Google Group email for testers (API only supports groups)")
    args = parser.parse_args()

    if not os.path.exists(args.key):
        sys.exit(f"Key file not found: {args.key}")

    service = get_service(args.key)

    if args.list:
        list_apps(service)
    elif args.create_app:
        create_app(service)
    elif args.closed_testing:
        if not os.path.exists(args.aab):
            sys.exit(f"AAB not found: {args.aab}")
        upload_closed_testing(service, args.aab, args.countries,
                              args.release_notes, args.tester_group)
    elif args.aab:
        if not os.path.exists(args.aab):
            sys.exit(f"AAB not found: {args.aab}")
        upload_aab(service, args.aab)
    else:
        parser.print_help()


if __name__ == "__main__":
    main()
