#!/usr/bin/env bash

if [ $# -ne 2 ]; then
  echo "Usage: ${0} <your_bitbucket_username> <team_you_want_to_clone>"
  echo "create app password from https://bitbucket.org/account/settings/app-passwords/"
  echo "and specify when prompted for password."
  exit 1
fi

BB_USER="${1}"
BB_TEAM="${2}"
REPOS_JSON_INFO=$(mktemp "/tmp/${BB_TEAM}_repo.json.XXXXX")
REPOS_LIST=$(mktemp "/tmp/${BB_TEAM}_repos.txt.XXXXX")

cleanup() {
  rm -rf "${REPOS_JSON_INFO}" "${REPOS_LIST}"
}

trap cleanup EXIT

NEXT_URL="https://api.bitbucket.org/2.0/repositories/${BB_TEAM}?pagelen=100"

while [ ! -z $NEXT_URL ] && [ $NEXT_URL != "null" ]; do
    curl -u $BB_USER $NEXT_URL > "${REPOS_JSON_INFO}"
    jq -r '.values[] | .links.clone[1].href' "${REPOS_JSON_INFO}" >> "${REPOS_LIST}"
    NEXT_URL=$(jq -r '.next' "${REPOS_JSON_INFO}")
done

rm -rf "$BB_TEAM" && mkdir "$BB_TEAM" && cd $BB_TEAM

while read repo; do
  echo "Cloning ${repo}"
  git clone "${repo}"
done < "${REPOS_LIST}"
