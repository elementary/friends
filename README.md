# friends

See and contact your friends from elementary OS

## Building and Installation

You'll need the following dependencies:
* folks
* glib-2.0
* gobject-2.0
* granite-7
* adwaita-1
* gtk4
* meson
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
