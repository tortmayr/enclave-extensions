# runwith

Command-only extension providing `enclave runwith`. It starts a Claude, Codex
or pi session with a model and effort level picked for that run, and translates
the effort level into each harness's own flag.

```bash
enclave runwith claude fable high
enclave runwith codex gpt-5.3-codex high
enclave runwith pi --list sonnet   # search the models pi offers
enclave runwith pi --refresh       # rebuild the pi model cache
enclave runwith --refresh          # rebuild the model cache for every tool
```

Run `enclave runwith --help` for all options.

## Model cache

Listing models means starting a container and asking the harness, so
`runwith` caches the list per tool under `$XDG_CACHE_HOME/enclave/models/`. The
cache refreshes on use once it is older than `ENCLAVE_MODEL_CACHE_TTL_DAYS`
days (default 7, `0` disables expiry). `runwith` checks the model and effort
level against the cache before launching. Without a cache it skips the check
rather than start an extra container, and `--no-verify` skips it explicitly.

## Install

Requires an Enclave version with command-extension support:

```bash
enclave commands add tortmayr/enclave-extensions --name runwith
```

The command is available immediately after installation. There is no feature to
enable, container installation, or image rebuild.

If you installed `runwith` as a feature before, remove that copy first:

```bash
enclave features remove runwith
```
