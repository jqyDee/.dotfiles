"""Compare two `defaults export` snapshots and print macos.sh lines.

    python3 defaults_diff.py <before-dir> <after-dir> [macos.sh]

Each directory holds one <domain>.plist per domain. Single values become
`setting <domain> <key> <-type> <value>` lines; lists and dictionaries are
printed as "# manual" comments because `setting` can't write them. Dates,
binary data and window/panel state change constantly and are skipped.
"""

import os
import plistlib
import shlex
import sys

NOISE = (
    "NSWindow Frame",
    "NSNavPanel",
    "NSSplitView",
    "NSToolbar",
    "NSTableView",
    "NSOutlineView",
    "LastUsed",
    "lastUsed",
    "Timestamp",
    "timestamp",
    "LastUpdate",
    "lastUpdate",
)


def load(path):
    try:
        with open(path, "rb") as f:
            data = plistlib.load(f)
    except (OSError, plistlib.InvalidFileException, ValueError):
        return {}
    return data if isinstance(data, dict) else {}


def value_args(value):
    # bool before int: True is an int in Python
    if isinstance(value, bool):
        return "-bool " + ("true" if value else "false")
    if isinstance(value, int):
        return "-int %d" % value
    if isinstance(value, float):
        return "-float %r" % value
    return "-string " + shlex.quote(value)


def existing_settings(path):
    if not path or not os.path.exists(path):
        return set()
    with open(path) as f:
        return {line.split("#")[0].strip() for line in f}


def domain_lines(domain, before, after, known):
    lines = []
    for key in sorted(set(before) | set(after)):
        if key in before and key in after and before[key] == after[key]:
            continue
        if any(n in key for n in NOISE):
            continue
        if key not in after:
            lines.append("# removed: %s %s" % (domain, key))
            continue
        value = after[key]
        if isinstance(value, (bytes, bytearray)) or hasattr(value, "isoformat"):
            continue  # data and dates: noise
        if isinstance(value, (list, dict)):
            kind = "array" if isinstance(value, list) else "dict"
            lines.append("# manual (%s): %s %s" % (kind, domain, key))
            continue
        line = "setting %s %s %s" % (shlex.quote(domain), shlex.quote(key), value_args(value))
        if line in known:
            line += "  # already in macos.sh"
        lines.append(line)
    return lines


def main(argv):
    before_dir, after_dir = argv[1], argv[2]
    known = existing_settings(argv[3] if len(argv) > 3 else None)
    names = set(os.listdir(before_dir)) | set(os.listdir(after_dir))
    printed = False
    for name in sorted(n for n in names if n.endswith(".plist")):
        domain = name[: -len(".plist")]
        lines = domain_lines(
            domain,
            load(os.path.join(before_dir, name)),
            load(os.path.join(after_dir, name)),
            known,
        )
        if lines:
            print("# %s" % domain)
            print("\n".join(lines))
            printed = True
    if not printed:
        print("no changes", file=sys.stderr)


if __name__ == "__main__":
    main(sys.argv)
