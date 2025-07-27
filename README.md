# friends
[![l10n](https://l10n.elementary.io/widgets/friends/-/svg-badge.svg)](https://l10n.elementary.io/projects/friends)

![Screenshot](data/screenshot.png?raw=true)

See and contact your friends from elementary OS

## Building and Installation

You'll need the following dependencies:
* folks
* glib-2.0
* gobject-2.0
* granite-7
* adwaita-1
* gtk4
* meson (>= 0.57.0)
* valac

Run `meson build` to configure the build environment. Change to the build directory and run `ninja` to build

```bash
meson build --prefix=/usr
cd build
ninja
```

To install, use `ninja install`, then execute with `io.elementary.friends`

```bash
ninja install
io.elementary.friends
```
