#!/usr/bin/env bash
# Copyright (C) 2026 EclipseSource GmbH and others.
#
# This program and the accompanying materials are made available under the
# terms of the MIT License, which is available in the project root.
#
# SPDX-License-Identifier: MIT

# Regenerate the playwright-cli feature: pin the @playwright/cli version and
# extract the agent skill and license shipped with exactly that version.
#
# Usage: scripts/update-playwright-cli.sh [version]   (defaults to latest)
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
feature_dir="$root/extensions/features/playwright-cli"

version="${1:-$(npm view @playwright/cli version)}"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# Let the CLI emit its own skill so the layout tracks upstream. --global with
# an isolated HOME keeps the workspace-init side effects out of the repo.
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

# Take the license from the package itself rather than from a boilerplate
# copy, so the vendored terms and the copyright holder track upstream along
# with the skill. NOTICE.md points at this file.
tarball="$(cd "$tmp" && npm pack --silent "@playwright/cli@${version}")"
tar -xzf "$tmp/$tarball" -C "$tmp" package/LICENSE
mkdir -p "$feature_dir/LICENSES"
cp "$tmp/package/LICENSE" "$feature_dir/LICENSES/Apache-2.0.txt"

echo "playwright-cli feature pinned to @playwright/cli@${version}; review and commit."
echo "If the license changed, rename LICENSES/Apache-2.0.txt (and this script's"
echo "destination path) and update NOTICE.md to match."
