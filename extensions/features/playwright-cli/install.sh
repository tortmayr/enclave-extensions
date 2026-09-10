#!/bin/bash
# Copyright (C) 2026 EclipseSource GmbH and others.
#
# This program and the accompanying materials are made available under the
# terms of the MIT License, which is available in the project root.
#
# SPDX-License-Identifier: MIT

# Install the Playwright agent CLI (playwright-cli) and Google Chrome.
# The version is pinned in playwright-cli.version, which is kept in sync with
# the generated skills/ directory by scripts/update-playwright-cli.sh.
set -e

if ! command -v npm >/dev/null 2>&1; then
    echo "npm is not available; the root install phase is expected to put the agent node runtime on PATH" >&2
    exit 1
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
version="$(tr -d '[:space:]' < "$script_dir/playwright-cli.version")"

npm install -g --no-audit --no-fund --progress=false "@playwright/cli@${version}"

# Rewrite the entry point's `#!/usr/bin/env node` shebang to the absolute
# agent-runtime node: the private runtime is not on PATH at container start,
# and a project .nvmrc must not swap the interpreter under the CLI. Then
# symlink the CLI somewhere that stays on PATH for every feature selection.
#
# /opt/enclave/build-scripts/bin/enclave-agent-npm-install does the same
# rewrite generically, but it installs into ${npm_config_prefix:-$HOME/.local}
# instead of the global prefix used here and is not on PATH during root-phase
# installs, so reusing it would mean hard-coding a path into enclave internals.
node_bin="$(command -v node)"
npm_prefix="$(npm prefix -g)"
cli_entry="$(readlink -f "$npm_prefix/bin/playwright-cli")"
sed -i "1s|^#!/usr/bin/env node$|#!${node_bin}|" "$cli_entry"
ln -sfn "$npm_prefix/bin/playwright-cli" /usr/local/bin/playwright-cli

# That sed matches one exact string, so it no-ops without failing if upstream
# ever ships a different shebang or renames the entry point. Assert it landed.
shebang="$(head -n 1 "$cli_entry")"
if [ "$shebang" != "#!${node_bin}" ]; then
    echo "error: shebang rewrite did not apply to $cli_entry (first line: $shebang)" >&2
    exit 1
fi

# Install Google Chrome system-wide (/opt/google/chrome). Chrome is the
# channel playwright-cli launches by default, so plain `playwright-cli open`
# works without a --browser flag. Use the playwright bundled with
# @playwright/cli so the installer matches the CLI version.
#
# Chrome itself ignores PLAYWRIGHT_BROWSERS_PATH, but the ffmpeg binary that
# video recording needs does not: without the export it lands in root's
# per-user cache, unreachable for the agent. Use the same shared path as the
# built-in playwright feature. Playwright reference-counts that path in
# .links/ (one entry per installing package) and only garbage-collects
# browsers no link claims, so both features coexist there as long as both
# packages stay installed.
export PLAYWRIGHT_BROWSERS_PATH=/opt/playwright-browsers
mkdir -p "$PLAYWRIGHT_BROWSERS_PATH"
cli_pw="$(npm root -g)/@playwright/cli/node_modules/playwright"
node "$cli_pw/cli.js" install --with-deps chrome

# ffmpeg gets its own invocation on purpose. `install chrome` queues ffmpeg
# behind chrome, but chrome is a non-hermetic installation: if it is already
# present, the installer prints a warning and returns early with exit code 0,
# skipping everything queued behind it. Naming ffmpeg keeps re-runs of this
# script (and future channels that sort before it) from dropping it silently.
node "$cli_pw/cli.js" install ffmpeg

# Ask the installer where that revision belongs instead of globbing ffmpeg-*:
# the built-in playwright feature may pin a different revision into the same
# shared path, and neither the assertion nor the chmod below should reach into
# its directory.
ffmpeg_dir="$(node "$cli_pw/cli.js" install ffmpeg --dry-run | awk '/Install location:/ { print $3; exit }')"
case "$ffmpeg_dir" in
    "$PLAYWRIGHT_BROWSERS_PATH"/ffmpeg-*) ;;
    *)
        echo "error: could not determine the ffmpeg install location (got: ${ffmpeg_dir:-<empty>})" >&2
        exit 1
        ;;
esac
if [ ! -d "$ffmpeg_dir" ]; then
    echo "error: the ffmpeg revision this CLI needs is missing at $ffmpeg_dir; video recording would fail" >&2
    exit 1
fi

# Make what this feature needs writable by non-root users; playwright needs to
# write to .links/ when updating browsers. Deliberately not recursive over the
# whole path: at equal priority the built-in playwright feature installs first,
# and its ~660 MB Chromium tree is neither ours to relax nor cheap to re-walk.
chmod a+rwX "$PLAYWRIGHT_BROWSERS_PATH"
chmod -R a+rwX "$PLAYWRIGHT_BROWSERS_PATH/.links" "$ffmpeg_dir"

# The point of the shebang rewrite is a CLI that runs with no node on PATH.
# Check exactly that, rather than just the executable bit. NO_UPDATE_NOTIFIER
# keeps the assertion hermetic: `--version` otherwise runs the update check
# first, which hits registry.npmjs.org and writes to stderr.
if ! env PATH=/usr/local/bin:/usr/bin:/bin NO_UPDATE_NOTIFIER=1 playwright-cli --version >/dev/null; then
    echo "error: playwright-cli is not runnable without node on PATH" >&2
    exit 1
fi

echo "playwright-cli@${version} and Google Chrome installed"
