/*
* Copyright 2018 elementary, Inc. (https://elementary.io)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 3 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
*/

public class Friends.Application : Gtk.Application {
    public static GLib.Settings settings;
    private MainWindow main_window;

    public Application () {
        Object (
            application_id: "io.elementary.friends",
            flags: ApplicationFlags.FLAGS_NONE
        );
    }

    static construct {
        settings = new Settings ("io.elementary.friends");
    }

    protected override void activate () {
        if (get_windows ().length () > 0) {
            get_windows ().data.present ();
            return;
        }

        int width, height;

        settings.get ("window-size", "(ii)", out width, out height);

        main_window = new MainWindow (this) {
            default_width = width,
            default_height = height
        };
        main_window.present ();

        if (settings.get_boolean ("window-maximized")) {
            main_window.maximize ();
        }
    }

    public static int main (string[] args) {
        var app = new Application ();
        return app.run (args);
    }
}
