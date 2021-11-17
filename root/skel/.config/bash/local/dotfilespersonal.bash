#!/usr/bin/env bash

dotfilespersonal() {
  local MIN="${PERSONAL_UPDATE_MIN:-no}"
  local UPDATE="${PERSONAL_UPDATE:-yes}"
  local TOKEN="${GITHUB_ACCESS_TOKEN:-MYPERSONAL_GIT_TOKEN}"
  local REPO="${MYPERSONAL_GIT_REPO:-}"
  [ -z "${TOKEN}" ] && { printf '\t\tYour auth TOKEN is not set - env:MYPERSONAL_GIT_TOKEN' && return 1; }
  [ -z "${REPO}" ] && { printf '\t\tYour personal repo is not set - env:MYPERSONAL_GIT_REPO' && return 1; }
  bash -c "$(curl -LSs -H 'Authorization: token '$TOKEN'' $MYPERSONAL_GIT_REPO/raw/main/install.sh)"
}
