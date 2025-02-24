#!/bin/bash -eu

usage_exit() {
  cat <<_eof_
USAGE: $(basename "$0") CUT_CL

CUT_CL - # of the Piper CL where a release was cut

This command must be run in a git repository for closure-compiler
with the master branch checked out and a recent commit pulled.
_eof_
  printf '====\n'
  err_exit "$@"
}

# Used to check whether we are in a closure-compiler git repo.
readonly GITHUB_URL=git@github.com:google/closure-compiler.git

main() {
  local -r cut_cl=$1

  if [[ "$(git remote get-url origin)" != "$GITHUB_URL" ]]; then
    err_exit 'This is not a closure-compiler git repository.\n'
  fi

#  TODO: are these steps useful still when running from GitHub actions, isntead of
# locally?
#  git checkout master >&2 || err_exit 'cannot checkout master branch'
#  git pull >&2 || err_exit 'cannot pull most recent updates from GitHub'

  # 1. Get git commit IDs and their corresponding CLs from the git log.
  # 2. select and print the commit ID associated with the highest CL# that is
  # still lower than the cut CL
  git_commit_cl_log | last_commit_before_cl "$cut_cl"
}

# Read the git log and produce lines of the form
#
# `COMMIT_ID CL_NUMBER`
git_commit_cl_log() {
  # PiperOrigin-RevId: indicates the CL number
  git log master \
    --format='format:%h %(trailers:key=PiperOrigin-RevId,separator=,valueonly=true)'
}

# Expect a single argument specifying the release cut CL number
#
# Expect input lines in the form:
# `COMMIT_ID [CL_NUMBER]`
#
# Further expect that the CL numbers are in decscending order.
#
# Print the first CL number we encounter that is lower than
# the argument CL number.
#
# Report an error and return a non-zero value if we are unable
# to print a result CL number for any reason.
last_commit_before_cl() {
  awk -v cut_cl="$1" '
  # In some cases there is no CL associated with a commit.
  # We skip all of those by ignoring lines with only one field.
  NF > 1 {
    # force the CL to be interpreted as an integer
    cl = + $2
    if (cl <= cut_cl) {
      found_commit = 1
      print $1
      # skip reading any more records
      exit
    }
  }

  END {
    # This section always gets executed
    if (!found_commit) {
      printf "no commit found: Earliest CL seen is %d which is > %d\n",
        cl, cut_cl > "/dev/stderr"
      exit 1
    }
  }
  '
}

err_exit() {
  printf "$@" >&2
  exit 1
}

(( $# > 0 )) || usage_exit 'missing CUT_CL argument\n' "$@"
(( $# < 2 )) || usage_exit 'too many arguments\n'

readonly CUT_CL=$1
[[ $CUT_CL =~ ^[1-9][0-9]+$ ]] || usage_exit 'not a CL number: %q\n' "$CUT_CL"

main "$CUT_CL"
