#!/bin/sh
# Every widget's metadata version must match the newest heading in its
# changelog. A bundle labelled with a version nobody wrote notes for is a
# release nobody can read, and Plasma's "Get New Widgets" compares exactly
# that metadata version when it offers an update.
set -eu

status=0

for meta in widgets/*/package/metadata.json; do
    widget=$(basename "$(dirname "$(dirname "$meta")")")
    changelog="widgets/$widget/CHANGELOG.md"

    version=$(sed -n 's/.*"Version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$meta" | head -1)
    if [ -z "$version" ]; then
        echo "$widget: metadata.json has no Version"
        status=1
        continue
    fi

    if [ ! -f "$changelog" ]; then
        echo "$widget: $changelog is missing"
        status=1
        continue
    fi

    heading=$(sed -n 's/^## \{1,\}\(.*\)$/\1/p' "$changelog" | head -1)
    if [ "$heading" != "$version" ]; then
        echo "$widget: metadata.json says $version, $changelog starts with '$heading'"
        status=1
        continue
    fi

    echo "$widget: $version"
done

exit $status
