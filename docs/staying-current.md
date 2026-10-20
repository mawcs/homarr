# Staying current with upstream

Your fork carries one feature on top of official Homarr. This explains how that stays current
with almost no work, and what to do in the few cases that need you.

## How the fork is laid out

| Branch | What it holds | Who updates it |
|---|---|---|
| `fork` (default) | This documentation, the build workflow, the scripts, the dev container and `CLAUDE.md`. No Homarr code. | You, rarely |
| `feat/drop-url-to-add-app` | The feature: upstream `dev` + #6562's commits + your commit. This is the PR branch. | You, with `update-feature-branch.sh` |
| `dev` | Left over from forking. Not used; ignore it and **don't press "Sync fork"** on it, which triggers upstream's workflows. | Nobody |

The Docker image isn't built from a branch you maintain. Each build starts from an upstream
**release** (for example `v2.6.0`) and replays the feature branch's own commits on top
([`scripts/prepare-build-source.sh`](../scripts/prepare-build-source.sh)). Your NAS runs a real
release plus exactly one feature, never unreleased upstream code.

## What happens automatically

The **[Fork] Build image** workflow runs every day at 06:23 UTC:

1. It turns off any of upstream's workflows that have appeared in your fork. They need
   upstream's secrets and would only fail or publish things you don't want.
2. It checks for the latest upstream release and the current feature branch commit.
3. If that combination hasn't been built yet, it builds and publishes:
   - `ghcr.io/mawcs/homarr:v2.7.0-dnd`: the release with the feature (moves to newer feature commits)
   - `ghcr.io/mawcs/homarr:v2.7.0-dnd-<commit>`: that exact build, never changes
   - `ghcr.io/mawcs/homarr:latest`: the newest of the above
4. Otherwise it finishes in about a minute without building anything.

You can also run it by hand: **Actions** → **[Fork] Build image** → **Run workflow**. You can
give it an older release tag, or tick *force* to rebuild.

So a new upstream release gets you a new image within a day, without you doing anything.
Deploying it is up to you ([Updating on TrueNAS](truenas.md#updating)).

### Testing against a dependency that hasn't shipped yet

A feature this fork's feature branch depends on (like #6562) can merge into upstream `dev`
days or weeks before it's in a tagged release. Until then, the normal build fails: it tries to
replay the now-minimal feature branch onto the latest release, which doesn't have the
dependency yet. To get a testable image anyway, run the workflow by hand with **upstream-tag**
set to `dev`. That builds from the current tip of upstream `dev` instead of a release, tags the
image `dev-<sha>-dnd...` so it's never confused with a real release build, and never becomes
`:latest`. Use it to confirm things work on your NAS; switch back to a release tag once one
ships.

## First-time setup

Done once, in this order. Pushing the branches comes first, while Actions are still off, so
nothing runs by accident.

1. **Get `gh` into the dev container.** In VS Code: Command Palette → *Dev Containers:
   Rebuild Container*. Then, in the terminal, run `gh auth login`, choose GitHub.com,
   HTTPS, and log in with a browser.
2. **Push the branches** (already done for you if Claude set this up):
   `git push -u origin fork feat/drop-url-to-add-app`
3. **Make `fork` the default branch:** run
   `gh repo edit mawcs/homarr --default-branch fork`, or use *Settings → General → Default branch*.
   The daily schedule only runs from the default branch.
4. **Turn on Actions:** open https://github.com/mawcs/homarr/actions and click
   *I understand my workflows, go ahead and enable them*.
5. **Run the first build:** `gh workflow run fork-build-image.yml --repo mawcs/homarr`, then
   watch it with `gh run watch --repo mawcs/homarr`. The first build takes 20 to 40 minutes;
   later ones use a cache and are faster.
6. **Make the image public:** open https://github.com/users/mawcs/packages/container/package/homarr
   → *Package settings* → *Change visibility* → **Public**. You only need to do this once;
   later builds keep it public.

## When a build fails

GitHub emails you when a scheduled run fails. Open the run from the email; the error at the
bottom of the **Assemble source** step tells you which case it is:

- **"does not apply cleanly"**: upstream changed the same lines as the feature. Fix the branch
  as described in [Resolving a conflict](#resolving-a-conflict), then run the workflow again.
- **"already contains the feature"**: good news, see [When the feature ships upstream](#when-the-feature-ships-upstream).
- **Anything else**, for example a network or registry error: click *Re-run jobs*. If it keeps
  failing, paste the log into Claude.

Your running Homarr is unaffected by a failed build. You just don't get the new version until
it's fixed.

## Keeping the PR branch current

While the PR is open, refresh it against upstream every couple of weeks, or whenever GitHub shows
*This branch has conflicts*:

```sh
bash <(git show origin/fork:scripts/update-feature-branch.sh)
bun run typecheck && bun run lint       # quick check that it still builds
git push --force-with-lease origin feat/drop-url-to-add-app
```

The script moves your commit onto the latest upstream `dev`. It never pushes; you do, after
checking. `--force-with-lease` is the safe kind of force-push: it refuses if the branch changed
on GitHub in a way you haven't seen. Pushing updates the open PR and triggers a new image build
the next day.

## Resolving a conflict

If the script stops with `CONFLICT`, Git is waiting for you to choose how your change and
upstream's change fit together.

- `git status` lists the conflicting files. In VS Code they're marked **!**. Each shows
  *Accept Current / Incoming / Both* above every conflict, or you can edit the file by hand.
- When a file is fixed: `git add <file>`. When all are fixed: `git rebase --continue`.
- To give up and go back to exactly where you were: `git rebase --abort`.

Or ask Claude: *"update-feature-branch.sh stopped with a conflict, please resolve it"*.

## When #6562 merges

The feature builds on #6562, so its 15 commits ride along in your branch until upstream merges
it. Once it's merged, run the update script as usual. It notices the merge and drops the copies,
leaving only your commit. Then push, and mark your PR ready for review:
`gh pr ready --repo homarr-labs/homarr <your PR number>`.

If #6562 is closed **without** merging, your PR can't build on it. Ask Claude to fold the
fetcher you need into your own commit, then update the PR.

## When the feature ships upstream

When your PR is merged and an upstream release includes it, the daily build stops with
"already contains the feature". At that point:

1. On TrueNAS, switch to the official image with the same or a newer version:
   `ghcr.io/homarr-labs/homarr:<version>` ([details](truenas.md#switching-to-official-homarr-later)).
2. Turn off the fork's build: **Actions** → **[Fork] Build image** → **⋯** → *Disable workflow*.

## If the PR is rejected

Nothing changes. The fork keeps building every release with the feature for as long as you want.
You keep refreshing the feature branch only when a build fails with a conflict.

## Editing the fork branch

The `fork` branch has no Homarr code, so edit it in a separate folder rather than switching
your main checkout to it:

```sh
git worktree add ~/homarr-fork fork      # a second checkout, just for the fork branch
# edit files in ~/homarr-fork, then:
git -C ~/homarr-fork commit -am "docs: ..." && git -C ~/homarr-fork push
git worktree remove ~/homarr-fork
```

Or edit a file directly on github.com while viewing the `fork` branch.

The dev container files in your main checkout (`.devcontainer/`, `CLAUDE.md`) are untracked
copies there; Git ignores them through `.git/info/exclude`. If you change them, copy them into
the fork worktree and commit them there to keep the saved copy current.
