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
  echo "[container] installing dependencies from PyPI into /asset-output..."
  pip install --quiet --disable-pip-version-check --root-user-action=ignore --target /asset-output requests
  echo "[container] dependency install complete — this PyPI egress happened from inside the container"
'
echo "==> Bundling done."
echo "    The PyPI install above (pypi.org / files.pythonhosted.org) ran INSIDE the"
echo "    container, over the Docker bridge — so it is invisible to native-proxy mode."
echo "    Compare the report: the host-side curl to httpbin.org is listed; this"
echo "    container traffic is not."
