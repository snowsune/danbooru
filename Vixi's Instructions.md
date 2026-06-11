Didn't feel right/safe to overwrite the default README.md so I'll put my instructions here!

# Building an image locally

Only **committed** code is included (`git archive HEAD`). Commit first.

`snapshot.ubuntu.com` is unreliable — pass an **empty** `UBUNTU_SNAPSHOT` to use normal Ubuntu mirrors.

```shell
COMMIT=$(git rev-parse --short HEAD)
COMMIT_FULL=$(git rev-parse HEAD)
BUILD_DATE=$(TZ=UTC git show --no-patch --date=format-local:"%Y-%m-%dT%H:%M:%SZ" --format="%cd" HEAD)
SOURCE_DATE_EPOCH=$(git show --no-patch --format=%ct HEAD)

git archive HEAD | docker buildx build - \
  --platform linux/amd64 \
  --network=host \
  --build-arg UBUNTU_SNAPSHOT= \
  --build-arg DOCKER_IMAGE_REVISION=$COMMIT_FULL \
  --build-arg DOCKER_IMAGE_BUILD_DATE=$BUILD_DATE \
  --build-arg SOURCE_DATE_EPOCH=$SOURCE_DATE_EPOCH \
  --build-arg JOBS=1 \
  --target production \
  --tag ghcr.io/snowsune/danbooru:latest \
  --tag ghcr.io/snowsune/danbooru:production-${COMMIT} \
  --file Dockerfile \
  --load
```

Push to GHCR when ready:

```shell
docker push ghcr.io/snowsune/danbooru:latest
docker push ghcr.io/snowsune/danbooru:production-${COMMIT}
```

# Prod upgrade (after backup)

```shell
git pull origin master
docker compose pull   # or build on-host with the command above

# Pre-migration data fix (if upload_media_assets has null user_id rows)
docker compose run --rm -T danbooru bash -c \
  'echo "UPDATE upload_media_assets SET user_id = uploads.uploader_id FROM uploads WHERE uploads.id = upload_media_assets.upload_id AND upload_media_assets.user_id IS NULL;" | bin/rails dbconsole -p'

docker compose up -d
docker compose logs -f danbooru
```

Rollback:

```shell
DANBOORU_IMAGE=ghcr.io/snowsune/danbooru:production-pre-upgrade-30fba4d6c docker compose up -d
```

# Fetching commits from upstream

```shell
git fetch upstream
git checkout -b merge-upstream-$(date +%Y-%m)
git merge upstream/master
```
