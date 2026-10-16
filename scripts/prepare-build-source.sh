#!/usr/bin/env bash
# Assembles the source for the fork's Docker image: an upstream Homarr release with the
# feature branch's own commits (everything on it that upstream dev does not have yet)
# replayed on top. Used by .github/workflows/fork-build-image.yml; also runs locally.
#
# Usage: scripts/prepare-build-source.sh <empty-target-dir> [upstream-release-tag]
#   Without a tag, the latest upstream release is used.
#
# Prints key=value lines for the workflow: tag, latest_release, feature_sha.
# Exit codes: 0 ok, 2 the feature no longer applies cleanly (conflict),
#             3 the release already contains the feature (switch to the official image).
set -euo pipefail

target_dir=${1:?usage: prepare-build-source.sh <empty-target-dir> [upstream-release-tag]}
tag=${2:-}
fork_repo=${FORK_REPO:-mawcs/homarr}
upstream_repo=${UPSTREAM_REPO:-homarr-labs/homarr}
fork_url=${FORK_URL:-https://github.com/${fork_repo}.git}
feature_branch=${FEATURE_BRANCH:-feat/drop-url-to-add-app}
# A file only the feature adds; when a release contains it, the feature has shipped upstream.
feature_marker=${FEATURE_MARKER:-apps/nextjs/src/components/board/board-app-url-drop.tsx}

latest_release=$(curl -fsSL "https://api.github.com/repos/${upstream_repo}/releases/latest" | jq -r .tag_name)
tag=${tag:-$latest_release}

git init -q "$target_dir"
cd "$target_dir"
git config user.name "fork-build"
git config user.email "fork-build@users.noreply.github.com"
git remote add upstream "https://github.com/${upstream_repo}.git"
git remote add origin "$fork_url"

# Blobs are fetched on demand, which keeps the clone of upstream's long history small.
git fetch -q --filter=blob:none --no-tags upstream dev "+refs/tags/${tag}:refs/tags/${tag}"
git fetch -q --filter=blob:none --no-tags origin "+refs/heads/${feature_branch}:refs/remotes/origin/${feature_branch}"
feature_sha=$(git rev-parse "origin/${feature_branch}")

if git cat-file -e "refs/tags/${tag}:${feature_marker}" 2>/dev/null; then
	echo "::warning::Upstream ${tag} already contains the feature. Switch to ghcr.io/${upstream_repo}:${tag} and disable this workflow." >&2
	exit 3
fi

git checkout -q -B "build/${tag}" "$feature_sha"
if ! git rebase -q --onto "refs/tags/${tag}" upstream/dev; then
	echo "::error::The feature branch does not apply cleanly to ${tag}. Conflicting files:" >&2
	git diff --name-only --diff-filter=U >&2
	git rebase --abort
	exit 2
fi

echo "tag=${tag}"
echo "latest_release=${latest_release}"
echo "feature_sha=${feature_sha}"
