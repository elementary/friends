public class NameGroup : Gtk.Grid {
    public Folks.NameDetails name_details { get; set; }

    private Gtk.Label full_name_label;
    private Gtk.Entry full_name_entry;

    construct {
        var header_label = new Granite.HeaderLabel (_("Name"));

        var description_label = new Gtk.Label (_("Full Name: ")) {
            xalign = 1
        };

        full_name_label = new Gtk.Label ("") {
            ellipsize = Pango.EllipsizeMode.MIDDLE
        };

        full_name_entry = new Gtk.Entry ();

        hexpand = true;
        halign = CENTER;
        attach (header_label, 0, 0, 2, 1);
        attach (description_label, 0, 1);
        attach (full_name_label, 1, 1);

        full_name_label.bind_property ("label", full_name_entry, "text", BIDIRECTIONAL);

        notify["name-details"].connect (() => {
            full_name_label.label = name_details.full_name;
        });
    }

    public void start_edit () {
        remove (full_name_label);
        attach (full_name_entry, 1, 1);
    }

    public async void finish_edit (bool save) {
        if (save) {
            try {
                yield name_details.change_full_name (full_name_entry.text);
            } catch (Error e) {
                warning ("Failed to update full name: %s", e.message);
            }
        }

        full_name_label.label = name_details.full_name;
        remove (full_name_entry);
        attach (full_name_label, 1, 1);
    }
}
