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

public class Friends.MainWindow : Gtk.ApplicationWindow {
    private uint configure_id;
    private Folks.IndividualAggregator individual_aggregator;
    private Gtk.ListBox listbox;

    public MainWindow (Gtk.Application application) {
        Object (
            application: application,
            icon_name: "office-address-book",
            title: _("Friends")
        );
    }

    construct {
        listbox = new Gtk.ListBox ();
        listbox.activate_on_single_click = true;
        listbox.selection_mode = Gtk.SelectionMode.SINGLE;
        listbox.set_sort_func (sort_function);

        var scrolledwindow = new Gtk.ScrolledWindow (null, null);
        scrolledwindow.add (listbox);

        add (scrolledwindow);

        individual_aggregator = Folks.IndividualAggregator.dup ();
        load_contacts.begin ();
    }

    private async void load_contacts () {
        individual_aggregator.individuals_changed_detailed.connect ((changes) => {
            foreach (var individual in changes.get (null)) {
                listbox.add (new Friends.ContactRow (individual));
            }
            listbox.show_all ();
        });

        foreach (var individual in individual_aggregator.individuals.values) {
            listbox.add (new Friends.ContactRow (individual));
        }
        listbox.show_all ();

        try {
            yield individual_aggregator.prepare ();
        } catch (Error e) {
            critical (e.message);
        }
    }

    [CCode (instance_pos = -1)]
    private int sort_function (Gtk.ListBoxRow row1, Gtk.ListBoxRow row2) {
        var name1 = ((Friends.ContactRow) row1).individual.display_name;
        var name2 = ((Friends.ContactRow) row2).individual.display_name;
        return name1.collate (name2);
    }

    public override bool configure_event (Gdk.EventConfigure event) {
        if (configure_id != 0) {
            GLib.Source.remove (configure_id);
        }

        configure_id = Timeout.add (100, () => {
            configure_id = 0;

            if (is_maximized) {
                Friends.Application.settings.set_boolean ("window-maximized", true);
            } else {
                Friends.Application.settings.set_boolean ("window-maximized", false);

                Gdk.Rectangle rect;
                get_allocation (out rect);
                Friends.Application.settings.set ("window-size", "(ii)", rect.width, rect.height);

                int root_x, root_y;
                get_position (out root_x, out root_y);
                Friends.Application.settings.set ("window-position", "(ii)", root_x, root_y);
            }

            return false;
        });

        return base.configure_event (event);
    }
}
