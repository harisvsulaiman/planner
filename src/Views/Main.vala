public class Views.Main : Gtk.Paned {
    public weak MainWindow parent_window { get; construct; }

    public Widgets.ProjectsList projects_list;
    public Gtk.Stack stack;

    private Views.Inbox inbox_view;
    private Views.Today today_view;
    private Views.Upcoming upcoming_view;

    public Main (MainWindow parent) {
        Object (
            parent_window: parent,
            orientation: Gtk.Orientation.HORIZONTAL,
            position: Application.settings.get_int ("project-sidebar-width")
        );
    }

    construct {
        get_style_context ().add_class ("view");

        projects_list = new Widgets.ProjectsList ();

        inbox_view = new Views.Inbox ();
        today_view = new Views.Today ();
        upcoming_view = new Views.Upcoming ();


        stack = new Gtk.Stack ();
        stack.expand = true;
        stack.transition_type = Gtk.StackTransitionType.SLIDE_UP_DOWN;

        stack.add_named (inbox_view, "inbox_view");
        stack.add_named (today_view, "today_view");
        stack.add_named (upcoming_view, "upcoming_view");

        update_views ();

        var start_page = Application.settings.get_enum ("start-page");
        var start_page_name = "";

        if (start_page == 0) {
            start_page_name = "inbox_view";
        } else if (start_page == 1) {
            start_page_name = "today_view";
        } else {
            start_page_name = "upcoming_view";
        }

        Timeout.add (200, () => {
            stack.visible_child_name = start_page_name;
            return false;
        });

        pack1 (projects_list, false, false);
        pack2 (stack, true, true);

        projects_list.on_selected_item.connect ((type, index) => {
            if (type == "item") {
                if (index == 0) {
                    stack.visible_child_name = "inbox_view";

                    //inbox_view.apply_remove ();
                } else if (index == 1) {
                    stack.visible_child_name = "today_view";

                    //today_view.apply_remove ();
                } else {
                    stack.visible_child_name = "upcoming_view";
                }
            } else {
                stack.visible_child_name = "project_view-" + index.to_string ();
                var project_view = stack.get_child_by_name ("project_view-" + index.to_string ()) as Views.Project;
                //project_view.apply_remove ();
            }
        });

        Application.database.on_add_project_signal.connect (() => {
            var project = Application.database.get_last_project ();

            var project_view = new Views.Project (project, parent_window);
            stack.add_named (project_view, "project_view-%i".printf (project.id));

            stack.show_all ();
        });

        Application.notification.on_signal_highlight_task.connect ((task) => {
            stack.visible_child_name = "inbox_view";
            destroy ();
        });

        Application.signals.go_action_page.connect ((index) => {
            if (index == 0) {
                stack.visible_child_name = "inbox_view";
            } else if (index == 1) {
                stack.visible_child_name = "today_view";
            } else if (index == 2) {
                stack.visible_child_name = "upcoming_view";
            }
        });

        Application.signals.go_project_page.connect ((project_id) => {
            stack.visible_child_name = "project_view-%i".printf (project_id);
        });

        Application.signals.go_task_page.connect ((task_id, project_id) => {
            stack.visible_child_name = "project_view-%i".printf (project_id);
        });
    }

    public void update_views () {
        var all_projects = new Gee.ArrayList<Objects.Project?> ();
        all_projects = Application.database.get_all_projects ();

        foreach (var project in all_projects) {
            var project_view = new Views.Project (project, parent_window);
            stack.add_named (project_view, "project_view-%i".printf (project.id));
        }
    }
}
