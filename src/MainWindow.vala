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
        var sidebar_header = new Gtk.WindowHandle () {
            child = new Gtk.WindowControls (Gtk.PackType.START)
        };
        sidebar_header.add_css_class (Granite.STYLE_CLASS_DEFAULT_DECORATION);
        sidebar_header.add_css_class ("titlebar");
        sidebar_header.add_css_class (Granite.STYLE_CLASS_FLAT);

        var individualview_header = new Gtk.WindowHandle () {
            child = new Gtk.WindowControls (Gtk.PackType.END) {
                halign = Gtk.Align.END
            }
        };
        individualview_header.add_css_class (Granite.STYLE_CLASS_DEFAULT_DECORATION);
        individualview_header.add_css_class ("titlebar");
        individualview_header.add_css_class (Granite.STYLE_CLASS_FLAT);

        search_entry = new Gtk.SearchEntry () {
            margin_start = 9,
            margin_end = 9,
            margin_top = 3,
            margin_bottom = 6,
            hexpand = true,
            placeholder_text = _("Search Friends"),
            valign = Gtk.Align.CENTER
        };

        listbox = new Gtk.ListBox () {
            activate_on_single_click = true,
            hexpand = true,
            vexpand = true,
            selection_mode = Gtk.SelectionMode.SINGLE,
        };
        listbox.add_css_class ("rich-list");
        listbox.add_css_class ("background");
        listbox.set_filter_func (filter_function);
        listbox.set_header_func (header_function);
        listbox.set_sort_func (sort_function);

        var scrolledwindow = new Gtk.ScrolledWindow () {
            child = listbox
        };

        var sidebar_grid = new Gtk.Grid ();
        sidebar_grid.attach (sidebar_header, 0, 0);
        sidebar_grid.attach (search_entry, 0, 1);
        sidebar_grid.attach (scrolledwindow, 0, 2);

        var individual_view = new Friends.IndividualView ();
        individual_view.add_css_class (Granite.STYLE_CLASS_VIEW);

        var individual_grid = new Gtk.Grid ();
        individual_grid.attach (individualview_header, 0, 0);
        individual_grid.attach (individual_view, 0, 1);

        var paned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL) {
            start_child = sidebar_grid,
            resize_start_child = false,
            shrink_start_child = false,
            end_child = individual_grid,
            resize_end_child = true,
            shrink_end_child = false
        };

        child = paned;
        titlebar = new Gtk.Label ("") { visible = false };

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
                listbox.append (new Friends.ContactRow (individual));
            }
        });

        foreach (var individual in individual_aggregator.individuals.values) {
            listbox.append (new Friends.ContactRow (individual));
        }

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
            header_label.margin_start = 3;
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
}
