#!/usr/bin/env bash
# Pushes the feature branch to your fork and opens the pull request on upstream Homarr.
# Opens a draft by default; pass --ready for a normal PR.
#
# Run from the homarr checkout:  bash <(git show origin/fork:scripts/open-upstream-pr.sh) [--ready]
# The PR description comes from docs/pr-body.md on the fork branch.
set -euo pipefail

branch=${FEATURE_BRANCH:-feat/drop-url-to-add-app}
upstream_repo=${UPSTREAM_REPO:-homarr-labs/homarr}
fork_owner=${FORK_OWNER:-mawcs}
draft_flag=--draft
[ "${1:-}" = "--ready" ] && draft_flag=

existing_pr=$(gh pr list --repo "$upstream_repo" --head "$branch" --author @me --state open --json url --jq '.[0].url // empty')
if [ -n "$existing_pr" ]; then
	echo "A PR for $branch is already open: $existing_pr"
	echo "To update it, push the branch: git push --force-with-lease origin $branch"
	exit 0
fi

git fetch origin fork
body_file=$(mktemp)
git show origin/fork:docs/pr-body.md > "$body_file"
# The feature commit names the PR. It is not the newest commit: fixes found while testing follow it.
title=${PR_TITLE:-$(git log -1 --format=%s --grep='^feat(board):' "$branch")}
[ -n "$title" ] || { echo "No feat(board) commit on $branch; set PR_TITLE."; exit 1; }

echo "Branch:  $fork_owner:$branch -> $upstream_repo:dev"
echo "Title:   $title"
echo "Type:    ${draft_flag:+draft }pull request"
echo "Commits: $(git rev-list --count "upstream/dev..$branch") (includes the copied #6562 commits until it is merged)"
read -rp "Push the branch and open the PR? [y/N] " answer
[ "$answer" = "y" ] || { echo "Cancelled."; exit 1; }

git push --force-with-lease -u origin "$branch"
gh pr create --repo "$upstream_repo" --base dev --head "$fork_owner:$branch" $draft_flag \
	--title "$title" --body-file "$body_file"
