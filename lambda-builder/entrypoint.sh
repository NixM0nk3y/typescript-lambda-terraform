#!/bin/sh
set -e

echo Running entrypoint

# capture our UID + GID from the original entrypoint
# /bin/sh -c 'npm install && chown -R 1000:1000 .'
chown_command=$(echo "$@" | cut -d '&' -f 3)

# build the lambda
cd $(mktemp -d codebuild-XXXXXXXX) && cp -Rp /code/. . && ARTIFACTS_DIR=/var/task make bundle-lambda

# correct permissions
cd /var/task && $chown_command

echo finished running entrypoint