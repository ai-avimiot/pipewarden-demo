#!/usr/bin/env bash
# bundle.sh — a tiny stand-in for what AWS CDK does when it builds a Lambda
# inside Docker.
#
# CDK runs build steps in containers, e.g.:
#   - aws-lambda-python's PythonFunction  -> `pip install` inside a container
#   - NodejsFunction (no local esbuild)   -> esbuild / npm inside a container
#   - DockerImageAsset                    -> `docker build`
#
# The container's egress goes out over the Docker *bridge*, which the host's
# iptables OUTPUT chain never sees. PipeWarden's native-proxy mode therefore
# does NOT capture any of the requests this script makes from inside the
# container (PyPI + the httpbin call below). See the repo README for details.
set -euo pipefail

echo "==> CDK-style: bundling a Lambda artifact inside a Docker container"
docker run --rm python:3.12-alpine sh -c '
  set -e
  echo "[container] installing dependencies from PyPI..."
  pip install --quiet --disable-pip-version-check --target /asset-output requests
  echo "[container] making an outbound request from inside the build..."
  python -c "import requests; print(\"[container] GET httpbin ->\", requests.get(\"https://httpbin.org/ip\", timeout=10).json())"
'
echo "==> Bundling done."
echo "    The PyPI install and the httpbin request above came from INSIDE the"
echo "    container and are invisible to native-proxy mode. Compare the report:"
echo "    the host-side curl is listed; this container traffic is not."
