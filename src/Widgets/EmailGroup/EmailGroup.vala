public class EmailGroup : Gtk.Box {
    public Folks.EmailDetails email_details { get; set; }

    private ListStore list_store;

    construct {
        list_store = new ListStore (typeof (EmailGroupRow));

        var header_label = new Granite.HeaderLabel (_("E-Mail Adresses"));

        var list_box = new Gtk.ListBox ();
        list_box.bind_model (list_store, (item) => {
            return (Gtk.ListBoxRow)item;
        });

        hexpand = true;
        halign = CENTER;
        orientation = VERTICAL;
        append (header_label);
        append (list_box);

        notify["email-details"].connect (() => {
            list_store.remove_all ();
            foreach (var email_address in email_details.email_addresses) {
                list_store.append (new EmailGroupRow (email_address));
            }
        });
    }

    public void start_edit () {
        for (int i = 0; i < list_store.get_n_items (); i++) {
            var email_group_row = (EmailGroupRow)list_store.get_item (i);
            email_group_row.start_edit ();
        }
    }

    public async void finish_edit (bool save) {
        var new_set = new Gee.TreeSet<Folks.EmailFieldDetails> ();

        for (int i = 0; i < list_store.get_n_items (); i++) {
            var email_group_row = (EmailGroupRow)list_store.get_item (i);
            email_group_row.finish_edit (save);

            if (save) {
                new_set.add (email_group_row.email_field_details);
            }
        }

        if (save) {
            try {
                yield email_details.change_email_addresses (new_set);
            } catch (Error e) {
                warning ("Failed to update email addresses: %s", e.message);
            }
        }
    }
}
