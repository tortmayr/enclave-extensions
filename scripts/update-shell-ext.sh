#!/usr/bin/env bash
# Copyright (C) 2026 EclipseSource GmbH and others.
#
# This program and the accompanying materials are made available under the
# terms of the MIT License, which is available in the project root.
#
# SPDX-License-Identifier: MIT

# Re-pin the shell-ext feature to a commit of the portable dotfiles
# (https://github.com/tortmayr/dotfiles).
#
# Usage: scripts/update-shell-ext.sh [ref]   (defaults to origin/main)
#
# The workstation tracks the same repository through a submodule in dev-xp,
# and the two pins move independently. This prints both so the gap is visible.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
feature_dir="$root/extensions/features/shell-ext"
version_file="$feature_dir/dotfiles.version"
repo_url="https://github.com/tortmayr/dotfiles.git"

ref="${1:-HEAD}"

sha="$(git ls-remote "$repo_url" "$ref" | cut -f1)"
if [ -z "$sha" ]; then
    # Not a ref name: accept a raw commit SHA, but only if it really resolves.
    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' EXIT
    git init -q "$tmp"
    git -C "$tmp" remote add origin "$repo_url"
    if ! git -C "$tmp" fetch -q --depth 1 origin "$ref" 2>/dev/null; then
        echo "error: '$ref' is neither a ref nor a reachable commit in $repo_url" >&2
        exit 1
    fi
    sha="$(git -C "$tmp" rev-parse FETCH_HEAD)"
fi

previous="$(tr -d '[:space:]' < "$version_file" 2>/dev/null || true)"
printf '%s\n' "$sha" > "$version_file"

echo "shell-ext image pin: ${previous:-<none>} -> $sha"

# Report the workstation's pin too, when the dev-xp checkout is present.
host_submodule="$HOME/Git/Personal/dev-xp/dotfiles"
if [ -d "$host_submodule/.git" ] || [ -f "$host_submodule/.git" ]; then
    host_sha="$(git -C "$host_submodule" rev-parse HEAD)"
    echo "workstation pin:    $host_sha"
    if [ "$host_sha" != "$sha" ]; then
        echo "note: the workstation and the image are on different commits."
    fi
fi

echo "Review the diff and rebuild with: enclave --rebuild"
