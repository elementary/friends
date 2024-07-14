project('io.elementary.friends',
    'vala', 'c',
    meson_version: '>= 0.57.0'
)

gnome = import('gnome')
i18n = import('i18n')

add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format (meson.project_name()), language:'c')

executable(
    meson.project_name(),
    'src/Application.vala',
    'src/MainWindow.vala',
    'src/IndividualView.vala',
    'src/Widgets/ContactRow.vala',
    dependencies: [
        dependency('folks'),
        dependency('glib-2.0'),
        dependency('gobject-2.0'),
        dependency('granite-7'),
        dependency('gtk4'),
        dependency('libadwaita-1')
    ],
    install : true
)

subdir('data')
subdir('po')

gnome.post_install(
    glib_compile_schemas: true,
    gtk_update_icon_cache: true
)
