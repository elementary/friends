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
    private Gtk.SearchEntry search_entry;

    public MainWindow (Gtk.Application application) {
        Object (
            application: application,
            icon_name: "office-address-book",
            title: _("Friends")
        );
    }

    construct {
        search_entry = new Gtk.SearchEntry ();
        search_entry.hexpand = true;
        search_entry.placeholder_text = _("Search Friends");
        search_entry.valign = Gtk.Align.CENTER;

        var headerbar = new Gtk.HeaderBar ();
        headerbar.custom_title = search_entry;
        headerbar.show_close_button = true;

        listbox = new Gtk.ListBox ();
        listbox.activate_on_single_click = true;
        listbox.expand = true;
        listbox.selection_mode = Gtk.SelectionMode.SINGLE;
        listbox.set_filter_func (filter_function);
        listbox.set_header_func (header_function);
        listbox.set_sort_func (sort_function);

        var scrolledwindow = new Gtk.ScrolledWindow (null, null);
        scrolledwindow.add (listbox);

        var individual_view = new Friends.IndividualView ();

        var paned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
        paned.add1 (scrolledwindow);
        paned.add2 (individual_view);

        add (paned);
        set_titlebar (headerbar);

        individual_aggregator = Folks.IndividualAggregator.dup ();
        load_contacts.begin ();

        Friends.Application.settings.bind ("pane-position", paned, "position", GLib.SettingsBindFlags.DEFAULT);

        listbox.row_selected.connect (() => {
            individual_view.individual = ((Friends.ContactRow) listbox.get_selected_row ()).individual;
        });

        search_entry.search_changed.connect (() => {
            listbox.invalidate_filter ();
        });
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
    private bool filter_function (Gtk.ListBoxRow row) {
        var individual = ((Friends.ContactRow) row).individual;

        if (individual.structured_name == null && !individual.is_favourite) {
            return false;
        }

        var search_term = search_entry.text.down ();

        if (search_term in individual.display_name.down ()) {
            return true;
        }

        return false;
    }

    private void header_function (Gtk.ListBoxRow row1, Gtk.ListBoxRow? row2) {
        var name1 = ((Friends.ContactRow) row1).individual.structured_name;
        Folks.StructuredName name2 = null;
        if (row2 != null) {
            name2 = ((Friends.ContactRow) row2).individual.structured_name;
        }

        string header_string = null;
        if (name1 != null) {
            if (name1.family_name != "" && name1.family_name.@get (0).isalpha ()) {
                header_string = name1.family_name.substring (0, 1).up ();
            } else if (name1.given_name != "" && name1.given_name.@get (0).isalpha ()) {
                header_string = name1.given_name.substring (0, 1).up ();
            } else {
                header_string = _("#");
            }
        } else if (name2 != null) {
            header_string = _("#");
        }

        if (name2 != null) {
            if (name2.family_name != "") {
                if (name2.family_name.substring (0, 1).up () == header_string || !name2.family_name.@get (0).isalpha ()) {
                    return;
                }
            } else if (name2.given_name != "") {
                if (name2.given_name.substring (0, 1).up () == header_string || !name2.given_name.@get (0).isalpha ()) {
                    return;
                }
            }
        }

        if (header_string != null) {
            var header_label = new Granite.HeaderLabel (header_string);
            row1.set_header (header_label);
        }
    }

    [CCode (instance_pos = -1)]
    private int sort_function (Gtk.ListBoxRow row1, Gtk.ListBoxRow row2) {
        var name1 = ((Friends.ContactRow) row1).individual.structured_name;
        var name2 = ((Friends.ContactRow) row2).individual.structured_name;

        if (name1 != null) {
            if (name2 == null) {
                return -1;
            } else if (name1.family_name.@get (0).isalpha ()) {
                if (name2.family_name == "" || !name2.family_name.@get (0).isalpha ()) {
                    if (name2.given_name.@get (0).isalpha ()) {
                        return name1.family_name.collate (name2.given_name);
                    } else {
                        return -1;
                    }
                } else {
                    return name1.family_name.collate (name2.family_name);
                }
            } else if (name2.family_name.@get (0).isalpha ()) {
                if (name1.given_name.@get (0).isalpha ()) {
                    return name1.given_name.collate (name2.family_name);
                } else {
                    return 1;
                }
            }
        } else if (name2 != null) {
            return 1;
        }

        var displayname1 = ((Friends.ContactRow) row1).individual.display_name;
        var displayname2 = ((Friends.ContactRow) row2).individual.display_name;
        return displayname1.collate (displayname2);
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
