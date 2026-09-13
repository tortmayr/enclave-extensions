# playwright-cli

Installs [`@playwright/cli`](https://playwright.dev/agent-cli/introduction)
with Google Chrome and the matching `playwright-cli` agent skill.

The built-in `playwright` feature provides the Playwright MCP server. This
feature installs the session-based `playwright-cli` command for shell use,
including `open`, `goto`, `click`, and `snapshot`.

## What it does

- Installs the `@playwright/cli` version from `playwright-cli.version` and
  links the command into `/usr/local/bin`. The npm global binary directory
  belongs to Enclave's private Node.js runtime. The `node-dev` feature removes
  that directory from `PATH` at container start, so the link keeps the command
  available. The installer rewrites the entry point's shebang to the private
  Node.js binary. The CLI does not depend on another feature, and a project
  `.nvmrc` cannot change its interpreter.
- Installs Google Chrome in `/opt/google/chrome`. The `playwright-cli open`
  command uses Chrome by default and needs no `--browser` flag. This feature
  does not install Chromium, Firefox, or WebKit. Add those browsers to
  `install.sh` before using their `--browser` values.
- Installs Playwright's ffmpeg in `/opt/playwright-browsers`.
  The `video-start` and `video-stop` commands use this binary. At container
  start, `feature-entrypoint.d/setup.sh` exports that directory as
  `PLAYWRIGHT_BROWSERS_PATH`. The built-in `playwright` feature uses the same
  directory. Playwright records each installing package in `.links/` and
  removes a browser only when no installed package claims it.
- Copies `~/.playwright/cli.config.json` into the image with
  `--no-sandbox`. Chrome's setuid and namespace sandbox cannot start in the
  container. A project-level `.playwright/cli.config.json` merges with this
  file by key, but arrays replace existing arrays. If the project sets
  `browser.launchOptions.args`, include `"--no-sandbox"` in that array.
  Without it, Chrome exits with `Zygote process exited prematurely`.
- Includes the `playwright-cli` agent skill under `skills/`. When you enable
  the feature, Enclave copies it into each tool that supports skills.

## Update the feature

Do not hand-edit `skills/`. The update script extracts the skill from the
`@playwright/cli` version recorded in `playwright-cli.version`. Run the
script to update the CLI version and skill together:

```bash
scripts/update-playwright-cli.sh           # latest release
scripts/update-playwright-cli.sh 0.1.19    # specific version
```

The `skills/` directory contains Microsoft content under the Apache License
2.0. See [`NOTICE.md`](NOTICE.md).

## Requirements

This feature only requires Enclave. During the image build, Enclave adds its
private Node.js runtime at `/opt/enclave/node` to `PATH` for the root install
phase. At runtime, the rewritten shebang calls the same Node.js binary. The CLI
does not depend on `node-dev` or a project-provided Node.js installation.

## Enable the feature

This feature is opt-in because it sets `defaultEnabled: false`. Enable it per
project in
`~/.config/enclave/projects/<hash>/config.json`:

```json
{ "features": ["+playwright-cli"] }
```

For one run:

```bash
enclave --features default,playwright-cli
```

### Image cost and avoiding rebuilds

Google Chrome adds roughly 435 MB to the image, and the built-in `playwright`
feature adds another 660 MB of Chromium when enabled. Each feature selection
has a different image hash and builds a separate image. To reuse one image
across projects, enable the feature globally in
`~/.config/enclave/config.json`:

```json
{ "features": ["default", "playwright-cli"] }
```

## Known limitations

- Sessions write output into the project directory. Traces go under
  `.playwright-cli/traces/`. Snapshots and videos go into the current working
  directory. The `playwright-cli install` command creates `.playwright/`.
  Add these paths to `.gitignore` to keep the files untracked.
- The upstream-generated skill documents commands that need more setup in a
  headless container. The `--headed` option has no display. The
  `npx playwright test` command needs a project-level Playwright installation
  and access to its browser directory.
