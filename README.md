# PipeWarden Demo

A minimal demo showing [PipeWarden](https://github.com/ai-avimiot/pipewarden) on a real Node.js project.

> Pre-release notice: these workflows reference `ai-avimiot/pipewarden@v1` and `ghcr.io/ai-avimiot/pipewarden/*:v1`. They become runnable when PipeWarden v1 is published.

## Table of contents

- [Layout](#layout)
- [Workflows](#workflows)
- [Native mode (recommended)](#native-mode-recommended)
- [Container mode](#container-mode)
- [License](#license)

## Layout

```
nodejs/          — Node.js project (npm test + HTTPS fetch to httpbin.org)
                   includes its own network-policy.yml
```

## Workflows

| Workflow | Purpose |
|----------|---------|
| `nodejs.yml` | Baseline CI — no monitoring |
| `test-nodejs-native.yml` | Native-proxy mode (transparent + DNS), runs directly on the runner |
| `nodejs-nfw.yml` | Container mode — wraps the baseline workflow in `act` under PipeWarden's monitored Docker network |

## Native mode (recommended)

Adds a single step to the workflow. Teardown happens automatically when the job ends.

```yaml
- uses: ai-avimiot/pipewarden/native-proxy/action@v1
  with:
    policy-file: nodejs/network-policy.yml
    mode: monitor
```

See `test-nodejs-native.yml` for the full example.

## Container mode

Wraps any existing workflow file in a monitored Docker network using `act`. Useful when you need full TCP visibility, not just HTTP/HTTPS.

```yaml
env:
  NFW_IMAGE: ghcr.io/ai-avimiot/pipewarden/nfw:v1
  NFW_PROXY_IMAGE: ghcr.io/ai-avimiot/pipewarden/nfw-proxy:v1
  NFW_RUNNER_IMAGE: ghcr.io/ai-avimiot/pipewarden/nfw-runner:v1
```

See `nodejs-nfw.yml` for the full example.

## License

MIT
