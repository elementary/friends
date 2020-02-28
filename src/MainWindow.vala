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
        var header_provider = new Gtk.CssProvider ();
        header_provider.load_from_resource ("io/elementary/friends/HeaderBar.css");

        var sidebar_header = new Gtk.HeaderBar ();
        sidebar_header.decoration_layout = "close:";
        sidebar_header.has_subtitle = false;
        sidebar_header.show_close_button = true;

        unowned Gtk.StyleContext sidebar_header_context = sidebar_header.get_style_context ();
        sidebar_header_context.add_class ("sidebar-header");
        sidebar_header_context.add_class ("titlebar");
        sidebar_header_context.add_class ("default-decoration");
        sidebar_header_context.add_class (Gtk.STYLE_CLASS_FLAT);
        sidebar_header_context.add_provider (header_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        var individualview_header = new Gtk.HeaderBar ();
        individualview_header.has_subtitle = false;
        individualview_header.decoration_layout = ":maximize";
        individualview_header.show_close_button = true;

        unowned Gtk.StyleContext individualview_header_context = individualview_header.get_style_context ();
        individualview_header_context.add_class ("individualview-header");
        individualview_header_context.add_class ("titlebar");
        individualview_header_context.add_class ("default-decoration");
        individualview_header_context.add_class (Gtk.STYLE_CLASS_FLAT);
        individualview_header_context.add_provider (header_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        var header_paned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
        header_paned.pack1 (sidebar_header, false, false);
        header_paned.pack2 (individualview_header, true, false);

        search_entry = new Gtk.SearchEntry ();
        search_entry.margin_start = search_entry.margin_end = 9;
        search_entry.margin_top = 3;
        search_entry.margin_bottom = 6;
        search_entry.hexpand = true;
        search_entry.placeholder_text = _("Search Friends");
        search_entry.valign = Gtk.Align.CENTER;

        listbox = new Gtk.ListBox ();
        listbox.activate_on_single_click = true;
        listbox.expand = true;
        listbox.selection_mode = Gtk.SelectionMode.SINGLE;
        listbox.set_filter_func (filter_function);
        listbox.set_header_func (header_function);
        listbox.set_sort_func (sort_function);

        unowned Gtk.StyleContext listbox_context = listbox.get_style_context ();
        listbox_context.add_class ("sidebar-header");
        listbox_context.add_provider (header_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        var scrolledwindow = new Gtk.ScrolledWindow (null, null);
        scrolledwindow.add (listbox);

        var pane_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        pane_box.pack_start (search_entry, false, false, 0);
        pane_box.pack_start (scrolledwindow, false, true, 0);

        unowned Gtk.StyleContext pane_box_context = pane_box.get_style_context ();
        pane_box_context.add_class ("sidebar-header");
        pane_box_context.add_provider (header_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        var individual_view = new Friends.IndividualView ();

        var paned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
        paned.pack1 (pane_box, false, false);
        paned.pack2 (individual_view, true, false);

        set_titlebar (header_paned);
        add (paned);

        unowned Gtk.StyleContext paned_context = paned.get_style_context ();
        paned_context.add_provider (header_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        // This must come after setting header_paned as the titlebar
        unowned Gtk.StyleContext header_paned_context = header_paned.get_style_context ();
        header_paned_context.remove_class ("titlebar");
        header_paned_context.add_provider (header_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        individual_aggregator = Folks.IndividualAggregator.dup ();
        load_contacts.begin ();

        Friends.Application.settings.bind ("pane-position", header_paned, "position", GLib.SettingsBindFlags.DEFAULT);
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
            header_label.margin_start = 6;
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
