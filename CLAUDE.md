# CLAUDE.md

This is Michael's fork of Homarr. It exists for one focused feature, described below. For Homarr's own repository conventions (structure, commands, code style, where documentation goes), follow `AGENTS.md` in this repo; this file does not repeat it. This file is the intent and the working agreement for the fork.

## What I intend to do

Add one thing to Homarr: the ability to drag a URL out of the browser's address bar and drop it into a dashboard's edit zone to automatically create a new app tile. The new tile takes its name from the page's title and its icon from the site's favicon.

Homarr already supports some dragging (arranging existing items). The gap is adding an app by URL. Right now adding an app is too much friction, which is the reason I do not actually use Homarr. This feature fixes that.

## Done means

This fork's job is done when both are true:

1. In this fork, dragging a URL from the browser address bar onto a dashboard in edit mode creates a new app tile, with the name taken from the page title and the icon from the favicon.
2. A pull request carrying that feature has been submitted to upstream Homarr.

Done is the PR submitted, not merged. Whether the maintainers accept it is out of my hands.

## Out of scope

- Any other Homarr UX issues. There are several, but this fork is only the drag-a-URL-to-add-an-app feature. Do not fold in a broader UX overhaul.
- A long-lived maintained fork. The point is the upstream PR.
- Rewriting unrelated parts of the app.

## How to work on it

Use the dev container in `.devcontainer/`. It pins Node 24.18.0 and Bun 1.4.2 (matching `mise.toml`), runs Redis inside the container, and sets up a seeded SQLite development database on first build. After it comes up, start the app with `bun run dev` and open http://localhost:3000.

This is an upstream contribution, so match Homarr's existing conventions, not my personal ones:

- Format and lint with the repo's own tools: `bun run format` (oxfmt) and `bun run lint` (oxlint). Do not reformat to a personal style. My usual tabs-not-spaces preference does not apply to code going upstream; the files under `.devcontainer/` are the one exception, since they are my local infrastructure rather than app code.
- The UI is Mantine, not Tailwind. A Mantine MCP server is wired up in `.mcp.json`; use it when working with Mantine components.
- Typecheck and test before opening the PR: `bun run typecheck` and `bun run test`.
- Keep the change scoped and the diff small, so the PR is easy for maintainers to review.

## Where the feature likely lives (starting points, verify before trusting)

From the repository map in `AGENTS.md`, the first places to look:

- Board edit mode and any existing drag-and-drop handling: `packages/boards/`.
- The "new app" form and app-item creation: `packages/forms-collection/` (the new-app form) and `packages/modals-collection/` (the apps modal), plus wherever a board item is persisted through the tRPC API in `packages/api/`.
- Resolving the title and favicon from a dropped URL should happen server-side, not in the browser, to avoid CORS. Reuse Homarr's own helpers where they exist before writing a new fetcher: `packages/image-proxy/` (image and favicon proxying) and `packages/icons/` (icon resolution) are the first to check.

Treat the structure as a map, not a guarantee. Confirm the actual code paths before building on them.

## Command Center

This is Slot 3 in my Command Center system. The project record lives in the `command_center` repo at `projects/homarr-drag-and-drop.md`, and that repo, not this file, is the source of truth for the project's status. Keep this file about the code; status belongs there.
