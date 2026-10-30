# usage

Adds the `enclave usage` host command. It runs
[ccusage](https://github.com/ryoppippi/ccusage) over the Claude, Codex, Gemini
and pi sessions that enclave persists per project, so you get token and cost
reports for sandboxed work.

```bash
enclave usage                      # daily report, enclave sessions only
enclave usage monthly --by-agent   # any ccusage arguments pass through
enclave usage --include-host       # also count ordinary host sessions
enclave usage --show-paths         # print the discovered session roots
```

Run `enclave usage --help` for all wrapper options.

## Requirements

The command runs on the host and needs `npx`. It runs a pinned `ccusage`
version through `npx` and caches it in `~/.npm`.

## Enable the feature

You do not need to enable it. Enclave adds the command on every host where the
extension is installed, and the feature installs nothing into the image.
