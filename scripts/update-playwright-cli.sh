#!/usr/bin/env bash
# Copyright (C) 2026 EclipseSource GmbH and others.
#
# This program and the accompanying materials are made available under the
# terms of the MIT License, which is available in the project root.
#
# SPDX-License-Identifier: MIT

# Regenerate the playwright-cli feature. Pin the @playwright/cli version and
# extract its agent skill and license.
#
# Usage: scripts/update-playwright-cli.sh [version]
# The script uses the latest release when no version is given.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
feature_dir="$root/extensions/features/playwright-cli"

version="${1:-$(npm view @playwright/cli version)}"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# Let the CLI generate its skill so the directory matches the package. An
# isolated HOME keeps workspace initialization from changing the repository.
mkdir -p "$tmp/home" "$tmp/ws"
(cd "$tmp/ws" && HOME="$tmp/home" npx -y "@playwright/cli@${version}" install --skills claude --global)

skill_src="$tmp/home/.claude/skills/playwright-cli"
if [ ! -f "$skill_src/SKILL.md" ]; then
    echo "error: @playwright/cli@${version} did not produce a skill at $skill_src" >&2
    exit 1
fi

rm -rf "$feature_dir/skills"
mkdir -p "$feature_dir/skills"
cp -r "$skill_src" "$feature_dir/skills/playwright-cli"
printf '%s\n' "$version" > "$feature_dir/playwright-cli.version"

# Copy the license from the package. This keeps the vendored terms and copyright
# holder tied to the installed version. NOTICE.md points to this file.
tarball="$(cd "$tmp" && npm pack --silent "@playwright/cli@${version}")"
tar -xzf "$tmp/$tarball" -C "$tmp" package/LICENSE
mkdir -p "$feature_dir/LICENSES"
cp "$tmp/package/LICENSE" "$feature_dir/LICENSES/Apache-2.0.txt"

echo "Pinned the playwright-cli feature to @playwright/cli@${version}."
echo "Review and commit the changes."
echo "If the license changed, rename LICENSES/Apache-2.0.txt and update"
echo "the destination in this script and NOTICE.md."
