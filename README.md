# enclave-extensions

Custom [enclave](https://github.com/eclipsesource/enclave) extensions.

## Repository layout

```text
.
├── extensions/
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
