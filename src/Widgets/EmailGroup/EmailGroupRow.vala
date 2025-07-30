public class EmailGroupRow : Gtk.ListBoxRow {
    public Folks.EmailFieldDetails email_field_details { get; set construct; }

    private Gtk.Grid grid;
    private Gtk.Label email_address_label;
    private Gtk.Entry email_address_entry;

    public EmailGroupRow (Folks.EmailFieldDetails email_field_details) {
        Object (
            email_field_details: email_field_details
        );
    }

    construct {
        var label = new Gtk.Label ("unnamed");

        email_address_label = new Gtk.Label (email_field_details.value);

        grid = new Gtk.Grid ();
        grid.attach (label, 0, 0);
        grid.attach (email_address_label, 1, 0);
        child = grid;

        email_address_entry = new Gtk.Entry ();

        email_address_label.bind_property ("label", email_address_entry, "text", BIDIRECTIONAL | SYNC_CREATE);
    }

    public void start_edit () {
        grid.remove (email_address_label);
        grid.attach (email_address_entry, 1, 0);
    }

    public void finish_edit (bool save) {
        if (save) {
            email_field_details = new Folks.EmailFieldDetails (email_address_entry.text);
        }

        grid.remove (email_address_entry);
        grid.attach (email_address_label, 1, 0);
    }
}
