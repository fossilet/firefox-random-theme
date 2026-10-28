# Random built-in New Tab wallpaper for Firefox

Keeps Firefox's built-in New Tab page and randomizes the native wallpaper that
Firefox itself renders each time a new tab opens.

This is **not a WebExtension**. It cannot be installed from AMO or as an `.xpi`.
It loads privileged browser-context JavaScript through
[fx-autoconfig](https://github.com/MrOtherGuy/fx-autoconfig) and modifies both
the Firefox application bundle and your profile.

## Status

Proof of concept, validated against Firefox 155/156 on macOS. The `install.sh`
and `uninstall.sh` helpers are macOS-only; the module itself is not tied to a
platform but has not been tested elsewhere.

## Requirements

- macOS, Firefox 141 or newer with the built-in wallpaper feature (validated
  against Firefox 155/156)
- `curl` and `tar` (included with macOS)
- fx-autoconfig 0.10 or newer
- An unmodified Firefox installation is not required, but any other
  autoconfiguration setup must be removed first
- Network access during install to download fx-autoconfig

fx-autoconfig is MPL-2.0 and is downloaded at install time. It is not bundled
in this repository.

## How it works

Firefox's New Tab wallpaper is driven by these profile preferences:

```
browser.newtabpage.activity-stream.newtabWallpapers.enabled
browser.newtabpage.activity-stream.newtabWallpapers.user.enabled
browser.newtabpage.activity-stream.newtabWallpapers.wallpaper
```

The `wallpaper` preference stores a wallpaper record title such as `dark-panda`,
not an image URL. Firefox resolves that title against its `newtab-wallpapers-v2`
Remote Settings record list and paints the matching image.

The module:

1. Runs at startup, before any window exists, and enables the wallpaper feature
   so Firefox's New Tab `WallpaperFeed` fetches its record list.
2. Fetches the public record list and keeps the titles that have images. If the
   fetch fails, it uses a built-in fallback list.
3. Sets `wallpaper` to a random title at startup and whenever a tab opens.

Firefox's built-in New Tab page performs the actual rendering.

## Install

From this directory:

```sh
./install.sh
```

The script resolves the default profile from `profiles.ini`, downloads
fx-autoconfig, copies its loader into the Firefox app bundle, and installs the
module into `<profile>/chrome/JS/`. Both scripts source `lib.sh`, so keep the
files in this repository together.

Override the defaults with environment variables:

```sh
FIREFOX_APP="/Applications/Firefox Developer Edition.app" ./install.sh
PROFILE="$HOME/Library/Application Support/Firefox/Profiles/abc.default-release" ./install.sh
FX_AUTOCONFIG_REF="master" ./install.sh
```

If `profiles.ini` cannot be read (for example, from a sandboxed terminal), pass
the profile explicitly. Open `about:profiles` in Firefox, copy the **Root
Directory** of the profile marked as in use, and run:

```sh
PROFILE="/path/from/about:profiles" ./install.sh
```

For non-standard Firefox installations, set `FIREFOX_PROFILES_DIR` to the
directory containing that installation's `profiles.ini`.

The default `FX_AUTOCONFIG_REF` is pinned to a specific fx-autoconfig commit.
Set it to `master` to track the latest loader.

After installing:

1. Fully quit Firefox.
2. Relaunch Firefox.
3. If nothing changes, open `about:support` and click **Clear startup-cache**,
   then restart Firefox.

## Manual install

1. Copy the **contents** of fx-autoconfig's `program/` directory into
   `/Applications/Firefox.app/Contents/Resources/`. `config.js` must end up at
   `Contents/Resources/config.js`.
2. Copy `fx-autoconfig/profile/chrome/utils/` into `<profile>/chrome/utils/`.
3. Copy `chrome/JS/random-newtab-wallpaper.sys.mjs` from this repository into
   `<profile>/chrome/JS/`.
4. Fully quit Firefox, relaunch, and clear the startup cache from
   `about:support` if needed.

## Verify

- Open several new tabs. The built-in search bar, logo, and top sites remain,
  and the native wallpaper changes.
- Open `about:config` and enter the key
  `browser.newtabpage.activity-stream.newtabWallpapers.wallpaper`. The value
  should be a different wallpaper title after new tabs.
- Module logs use the `[random-newtab-wallpaper]` prefix and appear in the
  Browser Console, not the New Tab page console.

## Uninstall

```sh
./uninstall.sh
```

This removes the module and the fx-autoconfig loader files that belong to this
installation. It leaves other user scripts and resources in `chrome/` alone.

After uninstalling:

1. Fully quit Firefox.
2. Clear the startup cache from `about:support`.
3. Reset the three wallpaper preferences listed above in `about:config`.

## Caveats

- **The wallpaper preference is profile-global.** Each new tab applies a fresh
  random wallpaper, but all currently open New Tab pages repaint to that same
  wallpaper. Distinct simultaneous wallpapers per tab are not possible with
  Firefox's built-in wallpaper mechanism.
- **Firefox updates replace the application bundle** and remove the autoconfig
  files. Re-run `install.sh` after updating Firefox.
- **Undocumented internals.** The preference names and the Remote Settings
  collection are Firefox internals and can change without notice.
- **Offline startup** uses the fallback title list. Firefox still needs its own
  cached wallpaper record list to resolve those titles.
- **Retired titles.** If a fallback title no longer exists, the page paints
  nothing until a title from the refreshed live list is applied.
- **Manual wallpaper choices are overwritten** on the next tab. This is intended
  for this proof of concept.
- **No settings UI, category filtering, or repeat history** is provided.
- **Private windows do not show the wallpaper.** The profile-wide preferences
  are still set, but the private New Tab page does not paint the random
  wallpaper.
- **Enterprise-locked preferences** cannot be changed. The module logs a warning
  and leaves the page unchanged.

## License

MIT, see [LICENSE](LICENSE). fx-autoconfig is downloaded at install time and
remains under its own MPL-2.0 license; it is not included in this repository.
