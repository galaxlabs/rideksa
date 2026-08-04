#!/usr/bin/env python3
"""
RideKSA - Release sync for the Vercel-hosted landing page.

The landing site lives at rideksa/landing and is deployed to Vercel from the
GitHub repo galaxlabs/rideksa-landing (git push = auto deploy).

This script:
  1. Verifies the release APK exists and computes its SHA-256.
  2. Copies the APK + checksum into rideksa/landing/.
  3. Patches landing/index.html with the new SHA-256, size and version line.
  4. Prepends a new entry to landing/releases.json (changelog section on the page).
  5. Commits and pushes to GitHub -> Vercel redeploys automatically.
  6. Creates a GitHub release (tag v<version>+<build>) with the APK attached,
     which the in-app update checker reads from /releases/latest.

Usage:
  python release_sync.py --apk build/app/outputs/flutter-apk/app-release.apk \\
      --version 0.0.6 --build 9 --notes "Fixed A" --notes "Added B"

Prereqs:
  - gh CLI authenticated (git push to github.com/galaxlabs)
  - Vercel project "rideksa-landing" linked to that repo (auto-deploy on push)
  - GitHub repo GH_REPO exists with a matching release tag/asset
"""
import argparse
import hashlib
import json
import os
import re
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
LANDING_DIR = os.path.join(HERE, "landing")
INDEX_HTML = os.path.join(LANDING_DIR, "index.html")
RELEASES_JSON = os.path.join(LANDING_DIR, "releases.json")
REMOTE_URL = "https://rideksa-landing-galaxlabs-projects.vercel.app"
APK_NAME = "app-release.apk"
GH_REPO = "galaxlabs/rideksa"  # must match UpdateCheckerService.githubRepo


def run(cmd):
    print(f"+ {' '.join(cmd)}")
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(result.stderr)
        sys.exit(result.returncode)
    return result.stdout.strip()


def sha256(path, chunk=1024 * 1024):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        while True:
            block = f.read(chunk)
            if not block:
                break
            h.update(block)
    return h.hexdigest()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--apk", required=True, help="Path to the release APK")
    parser.add_argument("--version", required=True, help="Version name, e.g. 0.0.6")
    parser.add_argument("--build", type=int, required=True, help="Version code / build number, e.g. 9")
    parser.add_argument("--date", default=None, help="Release date, default today (YYYY-MM-DD)")
    parser.add_argument("--notes", action="append", default=None, help="Feature line (repeatable)")
    args = parser.parse_args()

    if not os.path.exists(args.apk):
        sys.exit(f"APK not found: {args.apk}")

    digest = sha256(args.apk)
    print(f"SHA-256: {digest}")

    # 1. Copy APK + checksum into the landing project (Vercel serves from repo)
    run(["cp", args.apk, os.path.join(LANDING_DIR, APK_NAME)])
    with open(os.path.join(LANDING_DIR, f"{APK_NAME}.sha256"), "w") as f:
        f.write(f"{digest}  {APK_NAME}\n")

    # 2. Patch index.html checksum + file size label
    with open(INDEX_HTML, "r", encoding="utf-8") as f:
        html = f.read()
    apk_size_mb = round(os.path.getsize(args.apk) / (1024 * 1024))
    new_html, n1 = re.subn(r"[0-9a-f]{64}", digest, html, count=1)
    new_html, n2 = re.subn(
        r"Download RideKSA\.apk \([0-9.]+ MB\)",
        f"Download RideKSA.apk ({apk_size_mb} MB)",
        new_html,
        count=1,
    )
    new_html, n3 = re.subn(
        r"Version [0-9.]+ \(build \d+\)",
        f"Version {args.version} (build {args.build})",
        new_html,
        count=1,
    )
    if n1 or n2 or n3:
        with open(INDEX_HTML, "w", encoding="utf-8") as f:
            f.write(new_html)
        print("index.html checksum/size/version updated")

    # 3. Prepend new entry to releases.json (changelog section on the page)
    with open(RELEASES_JSON, "r", encoding="utf-8") as f:
        releases = json.load(f)
    date = args.date
    if date is None:
        date = subprocess.run(
            ["python", "-c", "import datetime; print(datetime.date.today().isoformat())"],
            capture_output=True, text=True,
        ).stdout.strip()
    new_entry = {
        "version": args.version,
        "build": args.build,
        "date": date,
        "features": args.notes if args.notes else ["Release notes available on the download page."],
    }
    releases.insert(0, new_entry)
    with open(RELEASES_JSON, "w", encoding="utf-8") as f:
        json.dump(releases, f, indent=2, ensure_ascii=False)
        f.write("\n")
    print("releases.json updated")

    # 4. Commit + push (Vercel auto-deploys from git)
    run(["git", "-C", LANDING_DIR, "add", INDEX_HTML, RELEASES_JSON,
         os.path.join(LANDING_DIR, APK_NAME),
         os.path.join(LANDING_DIR, f"{APK_NAME}.sha256")])
    run(["git", "-C", LANDING_DIR, "commit", "-m",
         f"release: RideKSA v{args.version} (build {args.build}) {digest[:8]} ({apk_size_mb} MB)"])
    run(["git", "-C", LANDING_DIR, "push", "origin", "main"])

    # 5. Create GitHub release so the in-app updater sees /releases/latest
    tag = f"v{args.version}+{args.build}"
    notes = "\n".join(f"- {n}" for n in (args.notes or ["Release."]))
    run(["gh", "release", "create", tag,
         os.path.join(LANDING_DIR, APK_NAME),
         "--repo", GH_REPO,
         "--title", f"RideKSA v{args.version} (build {args.build})",
         "--notes", notes])

    print(f"\nDone. Download page: {REMOTE_URL}")
    print(f"Checksum: {digest}")


if __name__ == "__main__":
    main()
