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

public class Friends.IndividualView : Gtk.Box {
    public Folks.Individual? individual { get; set; }

    private Gtk.Button edit_button;
    private Gtk.ActionBar edit_action_bar;
    private NameGroup name_group;
    private EmailGroup email_group;

    construct {
        edit_button = new Gtk.Button.from_icon_name ("document-edit") {
            visible = false
        };

        var header = new Gtk.HeaderBar () {
            show_title_buttons = false,
            title_widget = new Gtk.Grid ()
        };
        header.add_css_class (Granite.STYLE_CLASS_FLAT);
        header.pack_end (new Gtk.WindowControls (END));
        header.pack_end (edit_button);

        var placeholder = new Granite.Placeholder (_("No Contact Selected")) {
            hexpand = true,
            vexpand = true
        };

        name_group = new NameGroup () {
            hexpand = true
        };

        email_group = new EmailGroup ();

        var details_grid = new Gtk.Grid ();
        details_grid.attach (name_group, 0, 1);
        details_grid.attach (email_group, 0, 2);

        var cancel_button = new Gtk.Button.with_label (_("Cancel"));

        var save_button = new Gtk.Button.with_label (_("Apply"));

        edit_action_bar = new Gtk.ActionBar () {
            revealed = false
        };
        edit_action_bar.pack_end (save_button);
        edit_action_bar.pack_end (cancel_button);

        var stack = new Gtk.Stack ();
        stack.add_child (placeholder);
        stack.add_child (details_grid);

        orientation = VERTICAL;
        append (header);
        append (stack);
        append (edit_action_bar);
        add_css_class (Granite.STYLE_CLASS_VIEW);

        notify["individual"].connect (() => {
            if (individual != null) {
                stack.visible_child = details_grid;
                edit_button.visible = true;

                update_groups.begin ();
            } else {
                stack.visible_child = placeholder;
                edit_button.visible = false;
            }
        });

        edit_button.clicked.connect (() => {
            name_group.start_edit ();
            email_group.start_edit ();
            edit_button.visible = false;
            edit_action_bar.revealed = true;
        });

        cancel_button.clicked.connect (() => finish_edit (false));

        save_button.clicked.connect (() => finish_edit (true));
    }

    private async void update_groups () {
        try {
            name_group.name_details = (Folks.NameDetails) yield Folks.IndividualAggregator.dup ().ensure_individual_property_writeable (individual, "full-name");
        } catch (Error e) {
            warning ("Failed to get EmailDetails: %s", e.message);
        }

        try {
            email_group.email_details = (Folks.EmailDetails) yield Folks.IndividualAggregator.dup ().ensure_individual_property_writeable (individual, "email-addresses");
        } catch (Error e) {
            warning ("Failed to get EmailDetails: %s", e.message);
        }
    }

    private void finish_edit (bool save) {
        name_group.finish_edit.begin (save);
        email_group.finish_edit.begin (save);
        edit_button.visible = true;
        edit_action_bar.revealed = false;
    }
}
