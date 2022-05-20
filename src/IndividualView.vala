/*
* Copyright 2019 elementary, Inc. (https://elementary.io)
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

public class Friends.IndividualView : Gtk.Grid {
    public Folks.Individual? individual { get; set; }

    construct {
        var placeholder = new Gtk.Label (_("No Contact Selected")) {
            hexpand = true,
            vexpand = true
        };
        placeholder.add_css_class (Granite.STYLE_CLASS_H2_LABEL);
        placeholder.add_css_class (Granite.STYLE_CLASS_DIM_LABEL);

        var individual_name = new Gtk.Label (null) {
            ellipsize = Pango.EllipsizeMode.MIDDLE,
            hexpand = true,
            vexpand = true
        };
        individual_name.add_css_class (Granite.STYLE_CLASS_H3_LABEL);

        var details_grid = new Gtk.Grid ();
        details_grid.attach (individual_name, 0, 0);

        var stack = new Gtk.Stack ();
        stack.add_child (placeholder);
        stack.add_child (details_grid);

        attach (stack, 0, 0);

        notify["individual"].connect (() => {
            if (individual != null) {
                stack.visible_child = details_grid;

                individual_name.label = individual.display_name;
            } else {
                stack.visible_child = placeholder;
            }
        });
    }
}
