# enclave-extensions

Custom [enclave](https://github.com/eclipsesource/enclave) extensions.

## Layout

```text
extensions/
└── features/
    ├── playwright-cli/          # Playwright agent CLI + Google Chrome + agent skill
    └── shell-ext/               # portable dotfiles: zsh, powerlevel10k, plugins
scripts/
├── update-playwright-cli.sh     # re-pin the CLI version, regenerate its skill
└── update-shell-ext.sh          # re-pin the dotfiles commit
```

## Installing

```bash
enclave features add tortmayr/enclave-extensions --all
enclave features update   # pull later changes
```

## Enabling

Installing a feature does not switch it on. Everything here sets
`defaultEnabled: false`, so enable what you want per project in
`~/.config/enclave/projects/<hash>/config.json`:

```json
{ "features": ["+playwright-cli", "+shell-ext"] }
```

See each feature's `README.md` for what it installs.

`shell-ext` replaces the built-in `shell-extras`; enable one or the other,
not both.
