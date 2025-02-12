#!/bin/bash
set -e
export BUILDKIT_PROGRESS=plain

ARCHES="linux/amd64,linux/arm,linux/arm64"
IMAGE="mednafen-server"
VERSION="0.5.2"

docker buildx build --platform "${ARCHES}" -t yhaenggi/${IMAGE}:${VERSION} --push .
docker buildx build --platform "${ARCHES}" -t registry.traefik.k8s.darkgamex.ch/${IMAGE}:${VERSION} --push .
