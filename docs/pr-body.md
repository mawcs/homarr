> [!NOTE]
> **Depends on #6562.** This branch contains #6562's commits so it builds; only the last two
> commits, `feat(board): add apps by dropping a URL onto the board in edit mode` and
> `fix(boards): keep unsaved edit mode changes when the tab regains focus`, belong to this PR.
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
- **Edit mode fix:** the board query refetched on window focus once its 30 second stale time had
  passed, which replaced unsaved edit mode changes with the saved board. Adding apps by drag
  means switching to another tab and back, so newly dropped tiles kept vanishing. While edit
  mode is on, the board no longer refetches on focus or reconnect; Save and Cancel still
  invalidate it as before. `EditModeProvider` now wraps `BoardProvider` so the query can read it.
  This affects the existing edit mode as well, so it is a separate commit.
- **Size:** 7 files, about 230 lines including the new component.

## Known limitations

These come from how app icons and certificates already work, but dropping URLs makes them easy
to hit, so I'm listing them rather than working around them here:

- **`http` icons on an `https` Homarr:** the detected icon URL is stored as found, and app tiles
  load it directly in the browser. When Homarr is served over HTTPS (for example behind a reverse
  proxy) and the dropped site is plain `http`, the browser blocks the icon as mixed content and
  the tile shows a broken image. Icons picked by hand have the same problem. Loading app icons
  through the existing image proxy would fix both; happy to do that as a follow-up if you'd like.
- **Self-signed certificates:** the fetch uses Homarr's trusted certificates, so an `https` site
  with a self-signed certificate yields no title or icon (hostname and default icon) until its
  certificate is added under *Management → Tools → Certificates*.
- **Titles set by JavaScript:** some single-page apps (the TrueNAS UI, for example) ship an empty
  `<title>`, so the hostname is used.

## Testing

- Dropped URLs from the address bar of <!-- BROWSERS YOU TESTED, e.g. Chrome and Firefox -->
  onto a board in edit mode; saved, reloaded and restarted the server, and the apps persisted
  with the expected names and icons.
- Real sites (GitHub, Home Assistant, Sonarr), and pages with entities in the title, thousands
  of unclosed `<title` tags, a 250 KB unterminated entity, only a `mask-icon`, and a loopback
  address. The hostile pages resolve in under 20 ms.
- Ran it from a production image behind a reverse proxy for a while: in edit mode, switched
  tabs for over 30 seconds between drops, and the unsaved tiles stayed.
- `bun run typecheck` and `bun run lint` pass. In `bun run test`, the e2e and integration suites
  need Docker, which my dev container lacks; the remaining failures (custom widgets, grid
  geometry, UniFi, backup import and a few others) fail identically on `dev` at `e4d7dddf5`.
  The icons, app router, MCP and board provider suites pass.

I used Claude Code while writing this. I reviewed the changes and tested them as described above.

---

- [x] Relevant checks pass without warnings or errors
- [x] Pull request targets the intended base branch (`dev` by default; `release/v2` for v2 release work)
- [x] Commits follow the [conventional commits guideline](https://www.conventionalcommits.org/en/v1.0.0/)
- [x] No shorthand variable names are used (for example, `x`, `y`, `i`, or abbreviations)
- [x] Documentation under `apps/docs` is updated only when users need new or corrected information to use the app
- [x] When using AI, no temporary files are checked in and the code style follows the rest of the project

🤖 Generated with [Claude Code](https://claude.com/claude-code)
