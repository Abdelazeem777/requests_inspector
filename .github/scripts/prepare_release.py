#!/usr/bin/env python3
"""Prepare a release: compute the next version, update pubspec.yaml and CHANGELOG.md.

Used by .github/workflows/release.yml. Run from the package root:

    python3 .github/scripts/prepare_release.py --bump patch [--notes "line 1\nline 2"]

The base version is the newest `vX.Y.Z` git tag. pubspec.yaml must already
carry that version, so the tag and the published package never drift apart.

CHANGELOG.md gets a `## X.Y.Z` section, taken from (first match wins):
  1. --notes, one entry per line;
  2. an existing `## Unreleased` section, which is renamed;
  3. the commit subjects since the last tag (merges and release commits skipped).

Prints `version=X.Y.Z` and `tag=vX.Y.Z` (also appended to $GITHUB_OUTPUT when set).
"""

import argparse
import os
import re
import subprocess
import sys

TAG_RE = re.compile(r"^v(\d+)\.(\d+)\.(\d+)$")


def fail(message):
    print(f"::error::{message}", file=sys.stderr)
    sys.exit(1)


def git(*args):
    return subprocess.run(
        ["git", *args], check=True, capture_output=True, text=True
    ).stdout


def latest_tag():
    tags = [t for t in git("tag", "--list", "v*").split() if TAG_RE.match(t)]
    if not tags:
        fail(
            "No vX.Y.Z tag found. Tag the commit of the current pub.dev release "
            "first, e.g. `git tag v1.2.3 <commit> && git push origin v1.2.3`."
        )
    return max(tags, key=lambda t: tuple(int(p) for p in TAG_RE.match(t).groups()))


def bump(version, part):
    major, minor, patch = version
    if part == "major":
        return major + 1, 0, 0
    if part == "minor":
        return major, minor + 1, 0
    return major, minor, patch + 1


UNRELEASED_RE = re.compile(r"^## \[?unreleased\]?[^\n]*$", re.IGNORECASE | re.MULTILINE)


def new_changelog(text, version, notes, last_tag):
    if re.search(rf"^## {re.escape(version)}\s*$", text, re.MULTILINE):
        fail(f"CHANGELOG.md already has a `## {version}` section.")

    if notes.strip():
        lines = [line.strip() for line in notes.replace("\\n", "\n").splitlines()]
        entries = [l if l.startswith("-") else f"- {l}" for l in lines if l]
    elif UNRELEASED_RE.search(text):
        return UNRELEASED_RE.sub(f"## {version}", text, count=1)
    else:
        subjects = git("log", "--no-merges", "--format=%s", f"{last_tag}..HEAD").splitlines()
        skip = re.compile(r"^(chore(\(.*\))?: )?release\b", re.IGNORECASE)
        prefix = re.compile(r"^\w+(\([^)]*\))?!?:\s*")  # conventional-commit "fix(x): "
        entries = []
        for subject in subjects:
            subject = subject.strip()
            if subject and not skip.match(subject):
                subject = prefix.sub("", subject)
                entries.append(f"- {subject[:1].upper()}{subject[1:]}")
    if not entries:
        fail(
            "Nothing to release: no notes given, no `## Unreleased` section in "
            "CHANGELOG.md, and no commits since the last tag."
        )

    section = f"## {version}\n\n" + "\n".join(entries) + "\n\n"
    first = re.search(r"^## ", text, re.MULTILINE)
    if first:
        return text[: first.start()] + section + text[first.start():]
    return text.rstrip("\n") + ("\n\n" if text.strip() else "") + section


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--bump", choices=["patch", "minor", "major"], required=True)
    parser.add_argument("--notes", default="")
    args = parser.parse_args()

    last_tag = latest_tag()
    current = tuple(int(p) for p in TAG_RE.match(last_tag).groups())
    current_str = ".".join(map(str, current))

    pubspec = open("pubspec.yaml", encoding="utf-8").read()
    match = re.search(r"^version:\s*([^\s#]+)", pubspec, re.MULTILINE)
    if not match:
        fail("pubspec.yaml has no `version:` line.")
    if match.group(1).split("+")[0] != current_str:
        fail(
            f"pubspec.yaml says {match.group(1)} but the newest tag is {last_tag}. "
            "Make them match before releasing."
        )

    new = ".".join(map(str, bump(current, args.bump)))
    new_tag = f"v{new}"
    if new_tag in git("tag", "--list", new_tag).split():
        fail(f"Tag {new_tag} already exists.")

    path = "CHANGELOG.md"
    text = open(path, encoding="utf-8").read() if os.path.exists(path) else ""
    changelog = new_changelog(text, new, args.notes, last_tag)

    pubspec = pubspec[: match.start(1)] + new + pubspec[match.end(1):]
    open("pubspec.yaml", "w", encoding="utf-8").write(pubspec)
    open("CHANGELOG.md", "w", encoding="utf-8").write(changelog)

    output = f"version={new}\ntag={new_tag}\nprevious={last_tag}\n"
    print(output, end="")
    if os.environ.get("GITHUB_OUTPUT"):
        with open(os.environ["GITHUB_OUTPUT"], "a", encoding="utf-8") as fh:
            fh.write(output)


if __name__ == "__main__":
    main()
