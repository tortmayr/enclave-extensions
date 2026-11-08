# enclave-extensions

Custom [enclave](https://github.com/eclipsesource/enclave) extensions.

## Repository layout

```text
.
├── extensions/
│   ├── commands/                # Host-only commands (kind: command)
│   │   └── runwith/             # Start an agent with a chosen model and effort level
│   └── features/
│       ├── dotfiles/            # zsh shell environment; dotfiles/ inside is generated
│       └── playwright-cli/      # Playwright CLI, Chrome, and agent skill
└── scripts/
    └── update-playwright-cli.sh # Update the CLI version and regenerate its skill
```

> [!NOTE]
> The `usage` command has moved to
> [eclipsesource/enclave-extensions](https://github.com/eclipsesource/enclave-extensions/tree/main/commands/usage).
> It is no longer part of this repository, so `enclave features update` removes
> `enclave usage`. Install it from the new location to keep using it.

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

See each feature's `README.md` for what it installs.

## Host commands

Each extension under `extensions/commands/` is a command extension
(`kind: command`) that only adds a host command, such as `enclave runwith`.
Install them with `enclave commands add` instead of `enclave features add`:

```bash
enclave commands add tortmayr/enclave-extensions --all
enclave commands update   # pull later changes
```

The command is available as soon as the extension is installed. There is
nothing to enable and no image rebuild.
