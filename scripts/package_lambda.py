#!/usr/bin/env python3
"""Package FastAPI + deps for AWS Lambda deployment.

- Installs deps into a temporary dir
- Copies app/ and handler.py
- Zips into build/<LAMBDA_NAME>.zip

Requires: Python 3.11+, pip
"""

import os
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BUILD_DIR = ROOT / "build"
PACKAGE_DIR = BUILD_DIR / "package"
REQUIREMENTS = ROOT / "requirements.txt"
LAMBDA_NAME = os.getenv("LAMBDA_NAME", "fastapi_aws_lambda")
OUTPUT_ZIP = BUILD_DIR / f"{LAMBDA_NAME}.zip"


def run(cmd: list[str]):
    print("$", " ".join(cmd))
    subprocess.check_call(cmd)


def clean():
    shutil.rmtree(BUILD_DIR, ignore_errors=True)
    PACKAGE_DIR.mkdir(parents=True, exist_ok=True)


def install_deps():
    if not REQUIREMENTS.exists():
        print("requirements.txt not found; skipping deps install")
        return
    run([sys.executable, "-m", "pip", "install", "-r", str(REQUIREMENTS), "-t", str(PACKAGE_DIR)])


def copy_source():
    # Copy app/
    shutil.copytree(ROOT / "app", PACKAGE_DIR / "app")
    # Copy handler
    shutil.copy2(ROOT / "handler.py", PACKAGE_DIR / "handler.py")
    # Copy .env (optional for local/run; Lambda env comes from TF)
    if (ROOT / ".env").exists():
        shutil.copy2(ROOT / ".env", PACKAGE_DIR / ".env")


def make_zip():
    shutil.make_archive(OUTPUT_ZIP.with_suffix(""), "zip", PACKAGE_DIR)


def main():
    clean()
    install_deps()
    copy_source()
    make_zip()
    print(f"Built: {OUTPUT_ZIP}")


if __name__ == "__main__":
    main()
