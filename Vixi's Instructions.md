Didn't feel right/safe to overwrite the default README.md so I'll put my instructions here!

# Building an image locally

```shell
git rev-parse --short HEAD   # note for the tag name
bin/build-docker-image ghcr.io/snowsune/danbooru

# Pin this build so :latest can move later without losing the baseline.
COMMIT=$(git rev-parse --short HEAD)
docker tag ghcr.io/snowsune/danbooru:latest \
  ghcr.io/snowsune/danbooru:production-pre-upgrade-${COMMIT}
```

Alternative

```shell
COMMIT_FULL=$(git rev-parse HEAD)
BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
git archive HEAD | docker buildx build - --platform linux/amd64 --network=host \
  --build-arg DOCKER_IMAGE_REVISION=$COMMIT_FULL \
  --build-arg DOCKER_IMAGE_BUILD_DATE=$BUILD_DATE \
  --target production --tag ghcr.io/snowsune/danbooru:latest --file Dockerfile --load
```

Push to GHCR when ready

```shell
COMMIT=$(git rev-parse --short HEAD)
docker push ghcr.io/snowsune/danbooru:latest
docker push ghcr.io/snowsune/danbooru:production-pre-upgrade-${COMMIT}
```

# Fetching commits from upstream

Do this on a branch, not directly on master, when you're ready to fast-forward.

```shell
git fetch upstream
git checkout -b merge-upstream-$(date +%Y-%m)
git merge upstream/master
```
