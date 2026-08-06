#!/usr/bin/env python3
import plistlib, pathlib, os, sys

runner_temp = os.environ.get("RUNNER_TEMP", "/tmp")
output_path = os.path.join(runner_temp, "entitlements.plist")

ents = {
    "application-identifier": "PJ32UPL29J.com.vicente.losmusicians",
    "com.apple.developer.team-identifier": "PJ32UPL29J",
    "get-task-allow": False,
    "beta-reports-active": True,
    "keychain-access-groups": ["PJ32UPL29J.com.vicente.losmusicians"],
}

pathlib.Path(output_path).write_bytes(plistlib.dumps(ents))
print(f"Entitlements written to: {output_path}")
