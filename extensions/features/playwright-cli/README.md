# playwright-cli

Installs the [Playwright agent CLI](https://playwright.dev/agent-cli/introduction)
(`@playwright/cli`) with Google Chrome and the matching `playwright-cli` agent
skill.

The built-in `playwright` feature gives agents the Playwright MCP server. This
one gives them the session-based `playwright-cli` command instead, driven
straight from the shell (`open`, `goto`, `click`, `snapshot`, ...).

## What it does

- Installs `@playwright/cli` globally at image build time, pinned to the version
  in `playwright-cli.version`, and symlinks it into `/usr/local/bin`. The npm
  global bin lives in the private agent Node runtime, which `node-dev` drops
  from `PATH` at container start, so the symlink is what keeps the command
  reachable. The entry point's shebang is rewritten to the absolute
  agent-runtime `node`, so the CLI runs standalone: no other feature has to
  supply an interpreter, and a project `.nvmrc` cannot swap the Node version
  under it.
- Installs Google Chrome system-wide (`/opt/google/chrome`). Chrome is the
  channel `playwright-cli` launches by default, so `playwright-cli open` works
  without a `--browser` flag. No other browser is installed, so
  `--browser=chromium|firefox|webkit` needs an extended `install.sh`.
- Installs Playwright's ffmpeg (needed for `video-start`/`video-stop`) into the
  shared `/opt/playwright-browsers` path and exports
  `PLAYWRIGHT_BROWSERS_PATH` at container start
  (`feature-entrypoint.d/setup.sh`). This is the same path the built-in
  `playwright` feature uses. Playwright reference-counts that path in
  `.links/`, one entry per installing package, and its garbage collection only
  removes browsers no link claims, so enabling both features is safe as long
  as both packages stay installed.
- Bakes `~/.playwright/cli.config.json` into the image (`files/home/`) with
  `--no-sandbox`. Chrome's setuid/namespace sandbox cannot start inside the
  container, and the enclave container is already the isolation boundary.
  A project-local `.playwright/cli.config.json` merges into it per key, **but
  arrays replace**. If your project sets `browser.launchOptions.args`,
  it replaces the global array: include `"--no-sandbox"` yourself, or Chrome
  fails to launch with a cryptic `Zygote process exited prematurely` stack
  trace.
- Ships the `playwright-cli` agent skill (`skills/`). Enclave composes it into
  every skill-capable tool's skills directory once the feature is on.

## Updating

Do not hand-edit `skills/`. The script below extracts it from the exact
`@playwright/cli` version recorded in `playwright-cli.version`, which is what
keeps the skill and the installed CLI from drifting apart. Regenerate both
together and commit the result:

```bash
scripts/update-playwright-cli.sh           # latest release
scripts/update-playwright-cli.sh 0.1.19    # specific version
```

`skills/` is third-party content (Apache-2.0, Microsoft); see
[`NOTICE.md`](NOTICE.md).

## Requirements

None beyond enclave itself. Node.js and npm are needed at build time, but the
agent node runtime (`/opt/enclave/node`) is automatically added to `PATH`
during the root-phase feature install, so `install.sh` works with any feature
selection. At runtime the CLI uses that same runtime via its rewritten
shebang, so it does not depend on `node-dev` or a project-provided Node.

## Enabling

Opt-in (`defaultEnabled: false`). Enable it per project in
`~/.config/enclave/projects/<hash>/config.json`:

```json
{ "features": ["+playwright-cli"] }
```

Or per run with `enclave --features default,playwright-cli`.

### Image cost and avoiding rebuilds

Google Chrome adds roughly 435 MB to the image, and the built-in `playwright`
feature (if also enabled) another ~660 MB of Chromium. Enabling the feature per
project also changes the image hash, so each distinct feature selection builds
its own image. If you toggle it across projects often, enable it globally in
`~/.config/enclave/config.json` instead so every project shares one image:

```json
{ "features": ["default", "playwright-cli"] }
```

## Known limitations

- Sessions write into the project directory: tracing puts traces under
  `.playwright-cli/traces/`, snapshots and videos land in the cwd itself, and
  `playwright-cli install` creates a `.playwright/` directory there. Add them
  to `.gitignore` if that bothers you.
- The shipped skill is generated upstream and mentions a few things that do
  not work in the headless container as-is: `--headed` has no display to
  attach to, and `npx playwright test` needs a project-side Playwright
  install plus a browsers path the project can reach.
