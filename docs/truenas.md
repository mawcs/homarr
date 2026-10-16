# Running the fork on TrueNAS

This runs Homarr from your fork's image (`ghcr.io/mawcs/homarr`), which is official Homarr
plus drag-a-URL-to-add-an-app. It needs **TrueNAS SCALE 24.10 (Electric Eel) or later**,
which runs apps with Docker and can install them from Compose YAML.

## Before you start

- The image must exist and be public. Check that https://github.com/mawcs/homarr/pkgs/container/homarr
  opens without signing in and lists `v2.6.0-dnd` (see [Staying current](staying-current.md#first-time-setup)).
- Port 7575 must be free on the NAS.

## 1. Create a dataset for Homarr's data

1. **Datasets** → select the pool (or its `apps` dataset if you have one) → **Add Dataset**.
2. Name it `homarr` and set **Dataset Preset** to **Apps**. That gives TrueNAS's `apps` user
   (UID 568), which Homarr will run as, access to it.
3. Save, and note the full path, for example `/mnt/tank/apps/homarr`.

Everything Homarr keeps (database, settings, uploaded icons) lives here. Include it in your
snapshots and backups.

## 2. Generate the encryption key

In **System → Shell** (or any terminal):

```sh
openssl rand -hex 32
```

Copy the 64-character result into your password manager. Homarr encrypts saved integration
credentials with it. If the key is lost, those credentials can't be read, and if it changes,
they stop working.

## 3. Install the app

1. **Apps** → **Discover Apps** → the **⋮** menu at the top right → **Install via YAML**.
2. Name: `homarr`.
3. Paste [`deploy/truenas/compose.yaml`](../deploy/truenas/compose.yaml) and change the two
   `CHANGE ME` lines: the dataset path from step 1 and the key from step 2.
4. **Save**. TrueNAS pulls the image and starts it. The first start takes a minute.
5. Open `http://<your-nas-ip>:7575` and go through onboarding to create your admin account.

Try it: open a board, switch it to edit mode, then drag a URL from another tab's
address bar onto the page. Save the board when you're done.

> Dropped URLs are fetched **by the NAS**, so it must be able to reach them. Apps on your LAN
> work (for example `http://192.168.1.20:8989`). `localhost` and `127.0.0.1` are blocked on
> purpose: those apps get the hostname as their name and a default icon, which you can edit.

## Updating

The YAML pins a version (`v2.6.0-dnd`) so nothing changes unless you choose to update.

1. Look up the newest tag at https://github.com/mawcs/homarr/pkgs/container/homarr. Tags look
   like `v2.7.0-dnd`; the version matches the upstream Homarr release it's built from.
2. Take a snapshot of the `homarr` dataset (**Datasets** → the dataset → **Take Snapshot**).
3. **Apps** → `homarr` → **Edit**, change the `image:` tag, and **Save**. TrueNAS pulls the new
   image and recreates the container. Homarr upgrades its database automatically on start.

To roll back, stop the app, restore the snapshot, and set the previous tag again. Restoring the
snapshot matters: a database that a newer version has upgraded may not work with an older one.

If you'd rather always run the newest build, use `ghcr.io/mawcs/homarr:latest` instead. You'll
still need to redeploy to pick up a new image.

## Switching to official Homarr later

The feature changes no database tables, so your data works with the official image. Replace
the image line with `ghcr.io/homarr-labs/homarr:<version>`, using the **same or a newer**
version than the one you're running, never an older one. Do this when the feature ships in an
official release ([how you'll know](staying-current.md#when-the-feature-ships-upstream)), or any
time you want to stop using the fork. Without the fork, dragging URLs won't create apps; nothing
else changes.
