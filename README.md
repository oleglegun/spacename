# SpaceName

Shows which VS Code projects and Terminal tabs are on each Space, right under the Space thumbnails in
Mission Control.

I keep a lot of VS Code windows in full screen and Split View across three monitors. Mission Control
labels a Split View Space just "Code", so finding the right project meant flipping through every Space.
Now each thumbnail gets a yellow label listing its projects, one per line, then its Terminal tabs. A
window opened on a git worktree gets a `⎇` in front of its name. Tab titles are shown as the tab bar shows
them, status glyphs included.

Only VS Code and Terminal are shown. Everything else is ignored.

## Install

Needs macOS 27 and Xcode 16+.

```bash
git clone https://github.com/oleglegun/spacename.git
cd spacename
make install
```

This builds `SpaceName.app`, copies it to `~/Applications` and starts it. On first launch macOS asks
for Accessibility access (on macOS 27 it sits in System Settings → Privacy & Security → Device Control and
Data Access), then for permission to control Terminal, which is how it reads the tab titles. Say no to the
second and the labels list VS Code only. It also adds itself to login items; untick
«Запускать при входе» in its menu bar menu if you don't want that.

Set the VS Code window title to the folder name, otherwise the labels will include file names:

```json
"window.title": "${rootName}"
```

## How it works

When Mission Control opens, WindowServer posts an event. SpaceName reads where the Space buttons are
from WindowManager's accessibility tree, finds VS Code's windows and their Spaces through SkyLight, and
puts a click-through label under each button. Titles come from the Accessibility API, so no Screen Recording permission.
Terminal's tab titles come from AppleScript. Terminal draws each tab as a window of its own, and the tabs
behind the front one belong to no Space, so they go wherever the front tab with the same frame is.
Nothing runs while Mission Control is closed.

## Caveats

- It relies on private and undocumented APIs (SkyLight, WindowManager's accessibility tree). Tested on
  macOS 27.2; a new macOS version may break it. On macOS 15 Mission Control lived in the Dock, and this
  version doesn't read it there.
- "Displays have separate Spaces" has to be on.
- The collapsed Spaces bar isn't handled; labels assume the thumbnails are showing.
- Terminal tabs are listed in the order they were opened, which is not the tab bar's if you dragged tabs
  around: the tab bar's order can't be read.
- With two full-screen Terminals with tabs on one display, their hidden tabs can't be told apart and are
  left out.
- The app is ad-hoc signed with a requirement on its bundle id, so the Accessibility grant survives
  rebuilds. The downside: anything signed with the same id gets the grant too.

## Development

```bash
make test
make run      # build and launch from build/
```
