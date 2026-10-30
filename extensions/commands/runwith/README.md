# runwith

Adds the `enclave runwith` host command. It starts a Claude, Codex or pi session
with a model and effort level picked for that run, and translates the effort
level into each harness's own flag.

```bash
enclave runwith claude fable high
enclave runwith codex gpt-5.3-codex high
enclave runwith pi --list sonnet   # search the models pi offers
enclave runwith --refresh          # rebuild the model cache for every tool
```

Run `enclave runwith --help` for all options.

## Model cache

Listing models means starting a container and asking the harness, so
`runwith` caches the list per tool under `$XDG_CACHE_HOME/enclave/models/`. The
cache refreshes on use once it is older than `ENCLAVE_MODEL_CACHE_TTL_DAYS`
days (default 7, `0` disables expiry). `runwith` checks the model and effort
level against the cache before launching. Pass `--no-verify` to skip the check.

## Enable the feature

You do not need to enable it. Enclave adds the command on every host where the
extension is installed, and the feature installs nothing into the image.
