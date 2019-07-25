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

    private Gtk.Grid email_grid;
    private Gtk.MenuButton email_button;
    private Gtk.Popover email_popover;
    private ulong? email_button_handler = null;

    construct {
        var placeholder = new Gtk.Label (_("No Contact Selected"));
        placeholder.expand = true;

        var placeholder_context = placeholder.get_style_context ();
        placeholder_context.add_class (Granite.STYLE_CLASS_H2_LABEL);
        placeholder_context.add_class (Gtk.STYLE_CLASS_DIM_LABEL);

        var individual_name = new Gtk.Label (null);
        individual_name.ellipsize = Pango.EllipsizeMode.MIDDLE;
        individual_name.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);

        email_grid = new Gtk.Grid ();
        email_grid.orientation = Gtk.Orientation.VERTICAL;
        email_grid.margin_top = email_grid.margin_bottom = 3;
        update_emails ();

        email_popover = new Gtk.Popover (null);
        email_popover.add (email_grid);

        email_button = new Gtk.MenuButton ();
        email_button.halign = Gtk.Align.CENTER;
        email_button.image = new Gtk.Image.from_icon_name ("mail-send-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
        email_button.tooltip_text = _("Send Email");
        email_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        var details_grid = new Gtk.Grid ();
        details_grid.halign = details_grid.valign = Gtk.Align.CENTER;
        details_grid.orientation = Gtk.Orientation.VERTICAL;
        details_grid.row_spacing = 12;
        details_grid.add (individual_name);
        details_grid.add (email_button);

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
        if (email_button_handler != null) {
            email_button.disconnect (email_button_handler);
            email_button_handler = null;
        }

        foreach (unowned Gtk.Widget child in email_grid.get_children ()) {
            child.destroy ();
        }

        if (individual != null && individual.email_addresses != null) {
            if (individual.email_addresses.size == 0) {
                email_button.sensitive = false;
                return;
            } else if (individual.email_addresses.size == 1) {
                email_button.popover = null;
                email_button.sensitive = true;
                email_button_handler = email_button.toggled.connect (() => {
                    if (email_button.active) {
                        try  {
                            GLib.AppInfo.launch_default_for_uri ("mailto:%s".printf (individual.email_addresses.to_array ()[0].value), null);
                        } catch (Error e) {
                            critical (e.message);
                        }
                    }
                    email_button.active = false;
                });
                return;
            }

            foreach (var email in individual.email_addresses) {
                string description = _("email");
                var parameter_values = email.get_parameter_values (Folks.AbstractFieldDetails.PARAM_TYPE);
                if (parameter_values != null) {
                    description = parameter_values.to_array ()[0];
                }

                var description_label = new Gtk.Label (description);
                description_label.halign = Gtk.Align.START;

                var address_label = new Gtk.Label ("<small>%s</small>".printf (email.value));
                address_label.halign = Gtk.Align.START;
                address_label.use_markup = true;
                address_label.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

                var grid = new Gtk.Grid ();
                grid.attach (description_label, 0, 0);
                grid.attach (address_label, 0, 1);

                var email_row = new Gtk.ModelButton ();
                email_row.get_child ().destroy ();
                email_row.add (grid);

                email_grid.add (email_row);

                email_row.clicked.connect (() => {
                    try  {
                        GLib.AppInfo.launch_default_for_uri ("mailto:%s".printf (email.value), null);
                    } catch (Error e) {
                        critical (e.message);
                    }
                });
            }
            email_grid.show_all ();

            email_button.popover = email_popover;
        }
    }
}
