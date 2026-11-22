#!/usr/bin/env python3
"""Prepare a release: compute the next version, update pubspec.yaml and CHANGELOG.md.

Used by .github/workflows/release.yml. Run from the package root:

    python3 .github/scripts/prepare_release.py --bump patch [--notes "line 1\nline 2"]

The base version is the newest `vX.Y.Z` git tag. pubspec.yaml must already
carry that version, so the tag and the published package never drift apart.

CHANGELOG.md gets a `## X.Y.Z` section, taken from (first match wins):
  1. --notes, one entry per line;
  2. an existing `## Unreleased` section, which is renamed;
  3. the titles of the changes merged into main since the last tag (PR titles for
     merge commits); ci/test/style/build/chore changes and release commits are skipped.

It also updates this package's own `version:` line in example/pubspec.lock,
so the example still resolves with `flutter pub get --enforce-lockfile`.

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

    unreleased = UNRELEASED_RE.search(text)
    if unreleased:
        if notes.strip():
            fail(
                "CHANGELOG.md has a `## Unreleased` section. Leave the notes input "
                "empty to release it, or move its entries into the notes."
            )
        body = text[unreleased.end():]
        next_heading = re.search(r"^## ", body, re.MULTILINE)
        if not body[: next_heading.start() if next_heading else len(body)].strip():
            fail("The `## Unreleased` section in CHANGELOG.md is empty.")
        return text[: unreleased.start()] + f"## {version}" + text[unreleased.end():]

    if notes.strip():
        lines = [line.strip() for line in notes.replace("\\n", "\n").splitlines()]
        entries = [l if l.startswith("-") else f"- {l}" for l in lines if l]
    else:
        entries = entries_from_history(last_tag)
    if not entries:
        fail(
            "Nothing to release: no notes given, no `## Unreleased` section in "
            "CHANGELOG.md, and no user-facing changes merged since the last tag."
        )

    section = f"## {version}\n\n" + "\n".join(entries) + "\n\n"
    first = re.search(r"^## ", text, re.MULTILINE)
    if first:
        return text[: first.start()] + section + text[first.start():]
    return text.rstrip("\n") + ("\n\n" if text.strip() else "") + section


def entries_from_history(last_tag):
    # --first-parent: one entry per change that landed on main (a squash commit
    # or a "Merge pull request" commit), not every commit of every branch.
    log = git("log", "--first-parent", "--format=%s%x1f%b%x1e", f"{last_tag}..HEAD")
    merge = re.compile(r"^Merge pull request #(\d+) from ")
    kind = re.compile(r"^(\w+)(\([^)]*\))?!?:\s*")
    hidden = {"ci", "test", "tests", "style", "build", "chore"}
    release = re.compile(r"^(chore(\(.*\))?: )?release\b|^revert.*version", re.IGNORECASE)
    entries = []
    for record in filter(None, (r.strip("\n") for r in log.split("\x1e"))):
        subject, _, body = record.partition("\x1f")
        subject = subject.strip()
        pr = merge.match(subject)
        if pr:
            title = next((l.strip() for l in body.splitlines() if l.strip()), "")
            if not title:
                continue
            subject = f"{title} (#{pr.group(1)})"
        elif subject.startswith("Merge "):
            continue
        typed = kind.match(subject)
        if release.match(subject) or (typed and typed.group(1).lower() in hidden):
            continue
        subject = kind.sub("", subject)
        entries.append(f"- {subject[:1].upper()}{subject[1:]}")
    return entries


def update_example_lock(name, version):
    path = os.path.join("example", "pubspec.lock")
    if not os.path.exists(path):
        return
    text = open(path, encoding="utf-8").read()
    block = re.compile(
        rf'(^  {re.escape(name)}:\n(?:    .*\n)*?    version: )"[^"]*"', re.MULTILINE
    )
    new_text, count = block.subn(rf'\g<1>"{version}"', text, count=1)
    if count:
        open(path, "w", encoding="utf-8").write(new_text)


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
    name = re.search(r"^name:\s*(\S+)", pubspec, re.MULTILINE).group(1)
    update_example_lock(name, new)

    output = f"version={new}\ntag={new_tag}\nprevious={last_tag}\n"
    print(output, end="")
    if os.environ.get("GITHUB_OUTPUT"):
        with open(os.environ["GITHUB_OUTPUT"], "a", encoding="utf-8") as fh:
            fh.write(output)


if __name__ == "__main__":
    main()
