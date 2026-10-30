# enclave-extensions

Custom [enclave](https://github.com/eclipsesource/enclave) extensions.

## Repository layout

```text
.
├── extensions/
│   ├── commands/                # Features that only add `enclave <verb>` host commands
│   │   ├── runwith/             # Start an agent with a chosen model and effort level
│   │   └── usage/               # Run ccusage over enclave sessions
│   └── features/
│       ├── playwright-cli/      # Playwright CLI, Chrome, and agent skill
│       └── theia-dev/           # Native dependencies for Theia development
└── scripts/
    └── update-playwright-cli.sh # Update the CLI version and regenerate its skill
```

## Install extensions

```bash
enclave features add tortmayr/enclave-extensions --all
enclave features update   # pull later changes
```

## Enable features

Installing a feature does not switch it on. Every feature in this repository
sets `defaultEnabled: false`, so enable each feature per project in
`~/.config/enclave/projects/<hash>/config.json`:

```json
{ "features": ["+playwright-cli"] }
```

For a Theia project, enable the `theia-dev` feature:

```json
{ "features": ["+theia-dev"] }
```

See each feature's `README.md` for what it installs.

## Host commands

Each extension under `extensions/commands/` is a feature that only adds a host
command, such as `enclave usage`. `enclave features add` installs them like any
other feature. The command is available as soon as the extension is installed,
so you do not need to enable these features.
