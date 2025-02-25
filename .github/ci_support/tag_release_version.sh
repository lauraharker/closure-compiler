#!/bin/bash
set -e


err_exit() {
  printf "$@\n" >&2
  exit 1
}

usage_exit() {
  cat <<_eof_
USAGE: $(basename "$0") PIPER_CUT_CL VERSION_ID

PIPER_CUT_CL - # of the CL where a release was cut
VERSION_ID - the id of the release, in the format vYYYYMMDD

_eof_
  printf '====\n'
  err_exit "$@"
}

main() {
    local -r piper_cut_cl=$1
    local -r version_id=$2

    existing=$(git tag -l "$version_id")
    # Check if the version ID is already tagged.
    if [ -n "$existing" ]; then
      echo "Tag already exists for version '$version_id'"
      exit 0
    fi

    # Find the commit that was submmited at or most immediately before the cut CL.
    # TODO: at this point we've fetched all tags but only the most recent 2 commits -
    # what's the cheapest way to get more data?
    COMMIT=$(.github/ci_support/find_cut_piper_cl.sh $piper_cut_cl)
    # check that the commit variable is not empty
    if [[ -z "$COMMIT" ]]; then
      echo "No commit found prior to CL $piper_cut_cl"
      exit 1
    fi

    echo "Tagging commit $COMMIT with version $version_id"
    git tag -a "$version_id" -m "Release $version_id" "$COMMIT"
    # Make $RELEASE_TAG available for future workflow steps
    echo "RELEASE_TAG=$RELEASE_TAG" >> $GITHUB_ENV
}

(( $# == 2 )) || usage_exit 'incorrect argument count\n' "$@"

readonly PIPER_CUT_CL=$1
readonly VERSION_ID=$2

if [[ ! "$PIPER_CUT_CL" =~ ^[0-9]+$ ]]; then
    usage_exit "Invalid Piper cut CL number: '$PIPER_CUT_CL'"
fi

if [[ ! "$VERSION_ID" =~ ^v[0-9]+$ ]]; then
    usage_exit "Invalid version ID: '$VERSION_ID'. Expected format is vYYYYMMDD."
fi

main "$PIPER_CUT_CL" "$VERSION_ID"
