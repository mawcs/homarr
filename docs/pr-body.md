> [!NOTE]
> **Depends on #6562.** This branch contains #6562's commits so it builds; only the last commit,
> `feat(board): add apps by dropping a URL onto the board in edit mode`, belongs to this PR.
> I'll rebase onto `dev` once #6562 is merged, and keep this as a draft until then.

## What this adds

In edit mode, dropping a link onto the board, for example straight from the browser's address
bar, creates an app and places it on the board. The app is named after the page title and uses
the site's icon. Adding an app currently takes several steps; this makes it one drag.

<!-- demo GIF here -->

## How it works

- **Server:** `app.detectMetadata` (requires `app-create`) returns `{ name, iconUrl }` for a URL.
  It uses `fetchWebsiteMetadataAsync`, a small extension of #6562's `fetchFaviconUrlAsync` that
  also reads `<title>` from the head that request already fetched. No extra request is made, and
  the title inherits the same guards: blocked loopback and metadata addresses, every redirect hop
  re-checked, the 256 KiB head limit and the overall timeout. The title is parsed with
  linear-time patterns, like the link tags. `fetchFaviconUrlAsync` keeps its behaviour.
- **Fallbacks:** without a title the hostname is used; without an icon, the existing
  name-based icon lookup and then the default icon (the same as `createMany`).
  `NO_EXTERNAL_CONNECTION` skips the request.
- **Request type:** it is a mutation, so the URL travels in the request body and stays out of
  access logs.
- **Client:** `BoardAppUrlDrop` listens for native `dragover`/`drop` only while edit mode is on
  and the user can create apps. It accepts `text/uri-list` drags and ignores files and drags that
  start inside Homarr, so it does not interfere with the grid's own drag and drop. It then calls
  the existing `app.create` and `createItem`, like the "Add app" menu. Drops anywhere on the page
  are handled, so a near miss no longer makes the browser navigate away and drop unsaved edits.
- **Size:** 5 files, about 215 lines including the new component.

## Testing

- Dropped URLs from the address bar of <!-- BROWSERS YOU TESTED, e.g. Chrome and Firefox -->
  onto a board in edit mode; saved, reloaded and restarted the server, and the apps persisted
  with the expected names and icons.
- Real sites (GitHub, Home Assistant, Sonarr), and pages with entities in the title, thousands
  of unclosed `<title` tags, a 250 KB unterminated entity, only a `mask-icon`, and a loopback
  address. The hostile pages resolve in under 20 ms.
- `bun run typecheck`, `bun run lint` and `bun run test`.

I used Claude Code while writing this. I reviewed the changes and tested them as described above.

---

- [x] Relevant checks pass without warnings or errors
- [x] Pull request targets the intended base branch (`dev` by default; `release/v2` for v2 release work)
- [x] Commits follow the [conventional commits guideline](https://www.conventionalcommits.org/en/v1.0.0/)
- [x] No shorthand variable names are used (for example, `x`, `y`, `i`, or abbreviations)
- [x] Documentation under `apps/docs` is updated only when users need new or corrected information to use the app
- [x] When using AI, no temporary files are checked in and the code style follows the rest of the project

🤖 Generated with [Claude Code](https://claude.com/claude-code)
