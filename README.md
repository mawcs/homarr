# mawcs/homarr: Homarr with drag-a-URL-to-add-an-app

This is a fork of [Homarr](https://github.com/homarr-labs/homarr) with one addition: in edit mode,
drop a URL (for example straight from the browser's address bar) onto a board, and Homarr creates
an app tile for it, named after the page title and using the site's icon.

The feature has been proposed upstream. Until it's part of an official release, this fork
publishes an image of each upstream release with the feature added:

```
ghcr.io/mawcs/homarr:v2.6.0-dnd     # a specific upstream release + the feature
ghcr.io/mawcs/homarr:latest         # the newest of those
```

This branch (`fork`) holds no Homarr code: just the fork's tooling and docs. The feature itself is
on [`feat/drop-url-to-add-app`](../../tree/feat/drop-url-to-add-app).

| Guide | For |
|---|---|
| [Running on TrueNAS](docs/truenas.md) | Installing and updating the image on TrueNAS SCALE |
| [Opening the upstream PR](docs/pr-guide.md) | Submitting the feature to Homarr, step by step |
| [Staying current](docs/staying-current.md) | How builds follow upstream automatically, and what to do when they can't |

| Path | What it is |
|---|---|
| `.github/workflows/fork-build-image.yml` | Daily build: latest upstream release + feature → GHCR |
| `scripts/` | The build, PR, and update scripts the guides use |
| `deploy/truenas/compose.yaml` | Compose file for TrueNAS's "Install via YAML" |
| `.devcontainer/`, `CLAUDE.md` | Saved copy of the development environment and working agreement |

Homarr is licensed under the Apache License 2.0; see the upstream repository.
