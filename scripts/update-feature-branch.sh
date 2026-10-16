#!/usr/bin/env bash
# Moves the feature branch onto the current upstream dev so the PR stays mergeable.
# Once PR #6562 (the favicon fetcher this feature builds on) is merged upstream, it also
# drops the copied #6562 commits and keeps only your own.
#
# Run from the homarr checkout:  bash <(git show origin/fork:scripts/update-feature-branch.sh)
# Nothing is pushed. If a conflict stops the rebase, see docs/staying-current.md.
set -euo pipefail

branch=${FEATURE_BRANCH:-feat/drop-url-to-add-app}
upstream_repo=${UPSTREAM_REPO:-homarr-labs/homarr}
dependency_pr=${DEPENDENCY_PR:-6562}

if [ -n "$(git status --porcelain --untracked-files=no)" ]; then
	echo "You have uncommitted changes. Commit or stash them first." >&2
	exit 1
fi

git fetch upstream dev
git switch "$branch"

# Your own commits are the ones you authored; everything before them came from #6562.
first_own_commit=$(git rev-list --reverse --author="$(git config user.email)" upstream/dev..HEAD | head -1)
if [ -z "$first_own_commit" ]; then
	echo "No commits authored by $(git config user.email) on $branch. Nothing to do." >&2
	exit 1
fi

dependency_state=$(gh pr view "$dependency_pr" --repo "$upstream_repo" --json state --jq .state 2>/dev/null || echo UNKNOWN)
if [ "$dependency_state" = "MERGED" ]; then
	echo "#$dependency_pr is merged upstream; keeping only your own commits."
	git rebase --onto upstream/dev "${first_own_commit}^"
else
	git rebase upstream/dev
fi

echo
echo "Done: $branch is now based on the latest upstream dev."
echo "Check that it still works, then publish it with:"
echo "  git push --force-with-lease origin $branch"
