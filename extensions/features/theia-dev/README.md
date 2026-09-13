# theia-dev

Installs the native Linux libraries needed to build Eclipse Theia applications
and extensions on Debian-based enclave images.

## What it installs

- `libx11-dev` and `libxkbfile-dev` for Theia's `native-keymap` dependency
- `libsecret-1-dev` for Theia's `keytar` dependency and secrets API

The package list matches Theia's
[`scripts/deps/debian.sh`](https://github.com/eclipse-theia/theia/blob/master/scripts/deps/debian.sh)
script. Theia's
[Linux prerequisites](https://github.com/eclipse-theia/theia/blob/master/doc/Developing.md#prerequisites)
explain which native modules use these packages.

Enclave already includes Git, Python 3, `build-essential`, GCC/G++, `make`, and
`pkg-config`. Its default `node-dev` feature provides Node.js. If a project has
an `.nvmrc`, `node-dev` selects and installs that version. `theia-dev` does not
pin Node.js because the required version differs between Theia releases.

## Enable the feature

`defaultEnabled: false` makes this feature opt-in. Enable it per project in
`~/.config/enclave/projects/<hash>/config.json`:

```json
{ "features": ["+theia-dev"] }
```

Or enable it for one run with:

```bash
enclave --features default,theia-dev
```

Enclave disables features by default in devcontainer mode. Pass
`--features theia-dev` when using an enclave devcontainer.

## Scope

This feature installs the dependencies for browser and Electron application
builds. It does not install Xvfb or Playwright browsers. Add those dependencies
when running Electron or browser end-to-end tests in the container.
