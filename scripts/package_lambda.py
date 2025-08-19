#!/usr/bin/env python3
"""Package FastAPI and Flask lambdas + deps for AWS Lambda deployment.

- Installs deps into a temporary dir
- Copies sources and handler files
- Zips into build/<name>.zip for both lambdas

Requires: Python 3.11+, pip
"""

import os
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BUILD_DIR = ROOT / "build"
REQUIREMENTS = ROOT / "requirements.txt"

# Lambda package names
FASTAPI_ZIP = BUILD_DIR / "fastapi_lambda.zip"
FLASK_ZIP = BUILD_DIR / "flask_lambda.zip"


def run(cmd: list[str]):
    print("$", " ".join(cmd))
    subprocess.check_call(cmd)


def clean():
    shutil.rmtree(BUILD_DIR, ignore_errors=True)
    BUILD_DIR.mkdir(parents=True, exist_ok=True)


def _pick_packaging_python() -> str:
    """Pick the Python to use for pip installs into the Lambda package.

    Prefer python3.12 to match the Lambda runtime; fall back to current interpreter.
    """
    candidates = [
        os.environ.get("LAMBDA_PYTHON", "python3.12"),
        sys.executable,
    ]
    for exe in candidates:
        try:
            subprocess.check_output([exe, "-V"])  # ensure it runs
            return exe
        except Exception:
            continue
    return sys.executable


def install_deps(target_dir: Path):
    if not REQUIREMENTS.exists():
        print("requirements.txt not found; skipping deps install")
        return
    py = _pick_packaging_python()
    print(f"Installing dependencies with {py} to match Lambda runtime (python3.12)")
    run([py, "-m", "pip", "install", "-r", str(REQUIREMENTS), "-t", str(target_dir)])


def build_fastapi_zip():
    package_dir = BUILD_DIR / "fastapi_package"
    shutil.rmtree(package_dir, ignore_errors=True)
    package_dir.mkdir(parents=True, exist_ok=True)

    install_deps(package_dir)

    # Copy FastAPI app and handler
    shutil.copytree(ROOT / "app", package_dir / "app")
    shutil.copy2(ROOT / "handler.py", package_dir / "handler.py")
    if (ROOT / ".env").exists():
        shutil.copy2(ROOT / ".env", package_dir / ".env")

    shutil.make_archive(FASTAPI_ZIP.with_suffix(""), "zip", package_dir)
    print(f"Built: {FASTAPI_ZIP}")


def build_flask_zip():
    package_dir = BUILD_DIR / "flask_package"
    shutil.rmtree(package_dir, ignore_errors=True)
    package_dir.mkdir(parents=True, exist_ok=True)

    install_deps(package_dir)

    # Copy Flask app and handler
    shutil.copytree(ROOT / "flask_app", package_dir / "flask_app")
    shutil.copy2(ROOT / "flask_handler.py", package_dir / "flask_handler.py")
    if (ROOT / ".env").exists():
        shutil.copy2(ROOT / ".env", package_dir / ".env")

    shutil.make_archive(FLASK_ZIP.with_suffix(""), "zip", package_dir)
    print(f"Built: {FLASK_ZIP}")


def main():
    clean()
    build_fastapi_zip()
    build_flask_zip()


if __name__ == "__main__":
    main()
