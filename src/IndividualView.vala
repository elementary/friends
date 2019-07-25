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

    private Gtk.ListBox individual_emails;

    construct {
        var placeholder = new Gtk.Label (_("No Contact Selected"));
        placeholder.expand = true;

        var placeholder_context = placeholder.get_style_context ();
        placeholder_context.add_class (Granite.STYLE_CLASS_H2_LABEL);
        placeholder_context.add_class (Gtk.STYLE_CLASS_DIM_LABEL);

        var individual_name = new Gtk.Label (null);
        individual_name.ellipsize = Pango.EllipsizeMode.MIDDLE;
        individual_name.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);

        individual_emails = new Gtk.ListBox ();
        update_emails ();

        var details_grid = new Gtk.Grid ();
        details_grid.halign = details_grid.valign = Gtk.Align.CENTER;
        details_grid.orientation = Gtk.Orientation.VERTICAL;
        details_grid.add (individual_name);
        details_grid.add (individual_emails);

        var stack = new Gtk.Stack ();
        stack.add (placeholder);
        stack.add (details_grid);

        add (stack);

        notify["individual"].connect (() => {
            if (individual != null) {
                stack.visible_child = details_grid;

                individual_name.label = individual.display_name;

                update_emails ();
            } else {
                stack.visible_child = placeholder;
            }
        });
    }

    private void update_emails () {
        foreach (unowned Gtk.Widget child in individual_emails.get_children ()) {
            child.destroy ();
        }

        if (individual != null && individual.email_addresses != null) {
            foreach (var email in individual.email_addresses) {
                var email_row = new Gtk.Label (email.value);
                email_row.halign = Gtk.Align.START;

                individual_emails.add (email_row);
            }
            individual_emails.show_all ();
        }
    }
}
