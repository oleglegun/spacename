# SpaceName

Shows which VS Code projects are on each Space, right under the Space thumbnails in Mission Control.

I keep a lot of VS Code windows in full screen and Split View across three monitors. Mission Control
labels a Split View Space just "Code", so finding the right project meant flipping through every Space.
Now each thumbnail gets a yellow label listing its projects, one per line.

Only VS Code windows are shown. Everything else is ignored.

## Install

Needs macOS 15 and Xcode 16+.

```bash
git clone https://github.com/oleglegun/spacename.git
cd spacename
make install
```

This builds `SpaceName.app`, copies it to `~/Applications` and starts it. On first launch macOS asks
for Accessibility access, the only permission it needs. It also adds itself to login items; untick
«Запускать при входе» in its menu bar menu if you don't want that.

Set the VS Code window title to the folder name, otherwise the labels will include file names:

```json
"window.title": "${rootName}"
```

## How it works

When Mission Control opens, the Dock sends an accessibility notification. SpaceName reads where the
Space buttons are, finds VS Code's windows and their Spaces through SkyLight, and puts a click-through
label under each button. Titles come from the Accessibility API, so no Screen Recording permission.
Nothing runs while Mission Control is closed.

## Caveats

- It relies on private and undocumented APIs (SkyLight, the Dock's accessibility tree). Tested on
  macOS 15.8; a new macOS version may break it.
- "Displays have separate Spaces" has to be on.
- The collapsed Spaces bar isn't handled; labels assume the thumbnails are showing.
- The app is ad-hoc signed with a requirement on its bundle id, so the Accessibility grant survives
  rebuilds. The downside: anything signed with the same id gets the grant too.

## Development

```bash
make test
make run      # build and launch from build/
```
