#!/bin/bash
# Copyright (C) 2026 EclipseSource GmbH and others.
#
# This program and the accompanying materials are made available under the
# terms of the MIT License, which is available in the project root.
#
# SPDX-License-Identifier: MIT

# Install playwright-cli and Google Chrome.
# playwright-cli.version pins the version. scripts/update-playwright-cli.sh
# updates that file and the generated skills/ directory together.
set -e

if ! command -v npm >/dev/null 2>&1; then
    echo "npm is not available. The root install phase must put the agent Node.js runtime on PATH." >&2
    exit 1
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
version="$(tr -d '[:space:]' < "$script_dir/playwright-cli.version")"

npm install -g --no-audit --no-fund --progress=false "@playwright/cli@${version}"

# Rewrite the entry point's `#!/usr/bin/env node` shebang to use the private
# agent Node.js runtime. The container removes that runtime from PATH at startup,
# and a project .nvmrc must not change the CLI's interpreter. Link the CLI into
# a directory that remains on PATH.
#
# /opt/enclave/build-scripts/bin/enclave-agent-npm-install also rewrites
# shebangs. It is not on PATH during root installs and uses
# ${npm_config_prefix:-$HOME/.local} instead of the global prefix needed here.
node_bin="$(command -v node)"
npm_prefix="$(npm prefix -g)"
cli_entry="$(readlink -f "$npm_prefix/bin/playwright-cli")"
sed -i "1s|^#!/usr/bin/env node$|#!${node_bin}|" "$cli_entry"
ln -sfn "$npm_prefix/bin/playwright-cli" /usr/local/bin/playwright-cli

# The replacement matches one exact shebang and exits successfully without a
# change if upstream changes it. Verify the resulting shebang.
shebang="$(head -n 1 "$cli_entry")"
if [ "$shebang" != "#!${node_bin}" ]; then
    echo "error: shebang rewrite did not apply to $cli_entry. First line: $shebang" >&2
    exit 1
fi

# Install Google Chrome in /opt/google/chrome. The playwright-cli open command
# uses Chrome by default and needs no --browser flag. Run the Playwright copy
# bundled with @playwright/cli so the installer matches the CLI version.
#
# Chrome ignores PLAYWRIGHT_BROWSERS_PATH, but the ffmpeg installer uses it.
# Without this variable, ffmpeg goes into root's cache and the agent cannot
# access it. The built-in playwright feature uses the same shared path.
# Playwright records each installing package in .links/ and removes only
# browser builds that no installed package claims.
export PLAYWRIGHT_BROWSERS_PATH=/opt/playwright-browsers
mkdir -p "$PLAYWRIGHT_BROWSERS_PATH"
cli_pw="$(npm root -g)/@playwright/cli/node_modules/playwright"
node "$cli_pw/cli.js" install --with-deps chrome

# The install chrome command queues ffmpeg after Chrome. If Chrome already
# exists, the installer returns before it installs ffmpeg. Install ffmpeg with
# a separate command so repeated builds still provide it.
node "$cli_pw/cli.js" install ffmpeg

# Ask the installer for this revision's directory. The built-in playwright
# feature may put a different ffmpeg revision in the shared path. A glob could
# make the checks and permission change below affect that revision.
ffmpeg_dir="$(node "$cli_pw/cli.js" install ffmpeg --dry-run | awk '/Install location:/ { print $3; exit }')"
case "$ffmpeg_dir" in
    "$PLAYWRIGHT_BROWSERS_PATH"/ffmpeg-*) ;;
    *)
        echo "error: could not determine the ffmpeg install location. Got ${ffmpeg_dir:-<empty>}." >&2
        exit 1
        ;;
esac
if [ ! -d "$ffmpeg_dir" ]; then
    echo "error: the ffmpeg revision is missing at $ffmpeg_dir. Video recording would fail." >&2
    exit 1
fi

# Allow non-root users to write the directories this feature uses. Playwright
# updates .links/ when browsers change. Do not change permissions across the
# whole shared directory. At the same priority, the built-in playwright feature
# installs first and may have added a 660 MB Chromium directory.
chmod a+rwX "$PLAYWRIGHT_BROWSERS_PATH"
chmod -R a+rwX "$PLAYWRIGHT_BROWSERS_PATH/.links" "$ffmpeg_dir"

# Run the CLI with a PATH that contains no Node.js binary. Checking only the
# executable bit would not verify the rewritten shebang. NO_UPDATE_NOTIFIER
# disables the version check so this command makes no registry request and
# writes nothing to stderr.
if ! env PATH=/usr/local/bin:/usr/bin:/bin NO_UPDATE_NOTIFIER=1 playwright-cli --version >/dev/null; then
    echo "error: playwright-cli is not runnable without node on PATH" >&2
    exit 1
fi

echo "playwright-cli@${version} and Google Chrome installed"
