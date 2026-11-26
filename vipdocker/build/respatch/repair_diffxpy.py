#!/usr/bin/env python3
import sys
import os
import re

if len(sys.argv) != 2:
    print("Usage: python patch.py /path/to/diffxpy")
    sys.exit(1)

target = sys.argv[1]

if not os.path.isdir(target):
    print(f"Error: directory not found: {target}")
    sys.exit(1)

replacements = {
    "np.float": "float",
    "np.int": "int",
    "np.bool": "bool",
    "np.object": "object",
    "np.complex": "complex",
}

print(f"Repairing diffxpy for outdated numpy in: {target}")

for root, dirs, files in os.walk(target):
    for fname in files:
        if not fname.endswith(".py"):
            continue
        path = os.path.join(root, fname)
        print(f"\tchecking {path}")
        with open(path, "r", encoding="utf-8") as f:
            text = f.read()
        repaired = False
        for old, new in replacements.items():
            text, count = re.subn(rf"(?<![\w.]){re.escape(old)}\b", new, text)
            repaired = repaired or bool(count)
        if repaired:
            with open(path, "w", encoding="utf-8") as f:
                f.write(text)
            print("\t\toutdated scripts detected, repaired.")
        else:
            print("\t\tall good here.")

print("Done.")
