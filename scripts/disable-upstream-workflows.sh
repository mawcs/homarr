#!/usr/bin/env bash
# Disables every GitHub Actions workflow in the fork except the fork's own (fork-*.yml).
# Upstream's workflows need upstream's secrets and would only fail or publish things here.
# They appear in the fork once a push triggers them, so the build workflow runs this each time.
#
# Usage: scripts/disable-upstream-workflows.sh   (needs gh, authenticated; GH_TOKEN works)
set -euo pipefail

repo=${FORK_REPO:-mawcs/homarr}

gh workflow list --repo "$repo" --all --json id,path,state \
	--jq '.[] | select(.state == "active" and (.path | test("/fork-[^/]*$") | not)) | "\(.id) \(.path)"' |
	while read -r id path; do
		echo "Disabling ${path}"
		gh workflow disable "$id" --repo "$repo"
	done
