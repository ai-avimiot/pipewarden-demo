# PipeWarden Demo

A minimal demo showing [PipeWarden](https://github.com/ai-avimiot/pipewarden) on a real Node.js project.

> These workflows always track the latest PipeWarden release — they reference the floating `ai-avimiot/pipewarden/native-proxy/action@latest` action tag and `ghcr.io/ai-avimiot/pipewarden*:latest` images.

## Table of contents

- [Layout](#layout)
- [Workflows](#workflows)
- [Native mode (recommended)](#native-mode-recommended)
- [Container mode](#container-mode)
- [Container build steps (current limitation)](#container-build-steps-current-limitation)
- [License](#license)

## Layout

```
nodejs/            — Node.js project (npm test + HTTPS fetch to httpbin.org)
                     includes its own network-policy.yml
container-bundling/ — bundle.sh: a CDK-style "build a Lambda inside Docker" step,
                     used to demonstrate the container-egress limitation
```

## Workflows

| Workflow | Purpose |
|----------|---------|
| `nodejs.yml` | Baseline CI — no monitoring |
| `test-nodejs-native.yml` | Native-proxy mode (transparent + DNS), runs directly on the runner |
| `nodejs-pipewarden.yml` | Container mode — wraps the baseline workflow in `act` under PipeWarden's monitored Docker network |
| `container-scenario-native.yml` | Shows the container-egress **blind spot**: host traffic is captured, traffic from inside a Docker build step is not |

## Native mode (recommended)

Adds a single step to the workflow. Teardown happens automatically when the job ends.

```yaml
- uses: ai-avimiot/pipewarden/native-proxy/action@latest
  with:
    policy-file: nodejs/network-policy.yml
    mode: monitor
```

See `test-nodejs-native.yml` for the full example.

## Container mode

Wraps any existing workflow file in a monitored Docker network using `act`. Useful when you need full TCP visibility, not just HTTP/HTTPS.

```yaml
env:
  PIPEWARDEN_IMAGE: ghcr.io/ai-avimiot/pipewarden:latest
  PIPEWARDEN_PROXY_IMAGE: ghcr.io/ai-avimiot/pipewarden-proxy:latest
  # PIPEWARDEN_RUNNER_IMAGE is optional; omitted here so it falls back to
  # catthehacker/ubuntu:act-22.04 (bundles Node.js, Python, etc.)
```

See `nodejs-pipewarden.yml` for the full example.

## Container build steps (current limitation)

Some build steps run **inside Docker containers that the step launches itself** — the
most common example is **AWS CDK**, which bundles Lambda functions in containers:

- `PythonFunction` runs `pip install` inside a container,
- `NodejsFunction` (when no local esbuild) runs esbuild/npm inside a container,
- `DockerImageAsset` runs `docker build`.

**Native-proxy mode does not see this traffic.** It redirects and logs the host's
own egress (the `OUTPUT` chain), but a container's packets leave over the Docker
*bridge* (`PREROUTING`/`FORWARD`), which the native proxy doesn't touch. The
container's DNS is also bypassed. So a compromised dependency pulled during in-container
bundling would not show up in the report.

### Try it

`container-scenario-native.yml` (run via **workflow_dispatch**) makes the gap concrete.
It runs two outbound calls under monitoring:

1. a **host** `curl https://httpbin.org/ip` — **appears** in the report, and
2. `container-bundling/bundle.sh`, which does `docker run … pip install requests` plus an
   HTTPS call **from inside the container** — **does not appear** in the report.

Compare the two in the uploaded `container-scenario-report` artifact / job summary: you'll
see the host request listed but not the container's PyPI install or its httpbin call.

> Note: image *pulls* performed by the Docker daemon (e.g. `docker pull`) happen on the
> host and may be captured; the demo pre-pulls the image before monitoring so the focus
> stays on the container's own egress.

### What to do today

- **Cheapest fix for CDK `NodejsFunction`:** bundle locally instead of in Docker
  (`bundling: { forceDockerBundling: false }`) so egress flows through the host and is
  captured.
- For forced-Docker bundling (`PythonFunction`, `DockerImageAsset`), container visibility
  is on the roadmap — see the
  [container-visibility design plan](https://github.com/ai-avimiot/pipewarden/blob/main/docs/container-visibility-plan.md)
  in the main repo (detect/warn → metadata+DNS capture → opt-in deep inspection → enforce).

## License

MIT
