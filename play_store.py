#!/usr/bin/env python3
"""
RideKSA - Google Play Console CLI (app details + store listing).

The Play Developer API v3 supports a subset of Play Console setup:
  - App details (category, contact info, default language)
  - Store listing (title, short/full description, screenshots/video)

Sections that DO NOT have a public API and MUST be done in the web UI:
  Privacy policy, Sign-in details, Ads, Content rating, Target audience,
  Data safety, Government apps, Financial features, Health.

Usage:
  python play_store.py --key KEY app-details [--category AUTO_AND_VEHICLES] [--email E] [--website W] [--phone P] [--language en-US]
  python play_store.py --key KEY listing [--title T] [--short S] [--full F]
  python play_store.py --key KEY screenshots --dir build/screenshots
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


def new_edit(service):
    edit = service.edits().insert(body={}, packageName=PACKAGE).execute()
    return edit["id"]


def app_details(service, category, email, website, phone, language):
    edit_id = new_edit(service)
    body = {
        "defaultLanguage": language,
    }
    if email:
        body["contactEmail"] = email
    if phone:
        body["contactPhone"] = phone
    if website:
        body["contactWebsite"] = website
    try:
        service.edits().details().update(
            packageName=PACKAGE, editId=edit_id, body=body
        ).execute()
        print(f"App details updated: email={email} website={website} phone={phone} language={language}")
    except Exception as e:
        print(f"details update failed: {e}")
        sys.exit(1)
    try:
        service.edits().commit(packageName=PACKAGE, editId=edit_id).execute()
        print("App details edit committed.")
    except Exception as e:
        print(f"Commit failed: {e}")
        sys.exit(1)


def listing(service, title, short, full, language):
    edit_id = new_edit(service)
    body = {"language": language}
    if title:
        body["title"] = title
    if short:
        body["shortDescription"] = short
    if full:
        body["fullDescription"] = full
    try:
        service.edits().listings().update(
            packageName=PACKAGE, editId=edit_id, language=language, body=body
        ).execute()
        print(f"Store listing updated ({language}):")
        print(f"  title        : {title}")
        print(f"  short desc   : {short}")
        print(f"  full desc    : {len(full) if full else 0} chars")
    except Exception as e:
        print(f"listing update failed: {e}")
        sys.exit(1)
    try:
        service.edits().commit(packageName=PACKAGE, editId=edit_id).execute()
        print("Store listing edit committed.")
    except Exception as e:
        print(f"Commit failed: {e}")
        sys.exit(1)


def screenshots(service, folder, language):
    if not os.path.isdir(folder):
        sys.exit(f"Screenshot dir not found: {folder}")
    imgs = sorted(
        f for f in os.listdir(folder)
        if f.lower().endswith((".png", ".jpg", ".jpeg", ".webp"))
    )
    if not imgs:
        sys.exit(f"No png/jpg/webp images in {folder}")
    edit_id = new_edit(service)
    for f in imgs:
        path = os.path.join(folder, f)
        media = MediaFileUpload(path, mimetype="image/png", resumable=True)
        try:
            service.edits().images().upload(
                packageName=PACKAGE, editId=edit_id,
                language=language, imageType="phoneScreenshots",
                media_body=media,
            ).execute()
            print(f"Uploaded phone screenshot: {f}")
        except Exception as e:
            print(f"Upload failed for {f}: {e}")
    try:
        service.edits().commit(packageName=PACKAGE, editId=edit_id).execute()
        print("Screenshots edit committed.")
    except Exception as e:
        print(f"Commit failed: {e}")
        sys.exit(1)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--key", required=True, help="Path to service account JSON key")
    sub = parser.add_subparsers(dest="cmd", required=True)

    ad = sub.add_parser("app-details", help="Set contact + default language")
    ad.add_argument("--category", default="", help="ignored - not supported by Play v3 API")
    ad.add_argument("--email", default="galaxylab2020@gmail.com")
    ad.add_argument("--website", default="https://rideksa-84949.web.app")
    ad.add_argument("--phone", default="")
    ad.add_argument("--language", default="en-US")

    ls = sub.add_parser("listing", help="Set store listing text")
    ls.add_argument("--title")
    ls.add_argument("--short")
    ls.add_argument("--full")
    ls.add_argument("--language", default="en-US")

    sc = sub.add_parser("screenshots", help="Upload phone screenshots from a folder")
    sc.add_argument("--dir", required=True)
    sc.add_argument("--language", default="en-US")

    args = parser.parse_args()

    if not os.path.exists(args.key):
        sys.exit(f"Key file not found: {args.key}")

    service = get_service(args.key)

    if args.cmd == "app-details":
        app_details(service, args.category, args.email, args.website, args.phone, args.language)
    elif args.cmd == "listing":
        if not (args.title or args.short or args.full):
            sys.exit("Provide at least one of --title/--short/--full")
        listing(service, args.title, args.short, args.full, args.language)
    elif args.cmd == "screenshots":
        screenshots(service, args.dir, args.language)


if __name__ == "__main__":
    main()
