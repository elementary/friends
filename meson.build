project('io.elementary.friends', 'vala', 'c')

gnome = import('gnome')
i18n = import('i18n')

add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format (meson.project_name()), language:'c')

gresource = gnome.compile_resources(
    'gresource',
    join_paths('data', 'gresource.xml'),
    source_dir: 'data'
)

executable(
    meson.project_name(),
    gresource,
    'src/Application.vala',
    'src/MainWindow.vala',
    'src/IndividualView.vala',
    'src/Widgets/ContactRow.vala',
    dependencies: [
        dependency('folks'),
        dependency('glib-2.0'),
        dependency('gobject-2.0'),
        dependency('granite', version: '>=0.5'),
        dependency('gtk+-3.0'),
    ],
    install : true
)

subdir('data')
subdir('po')

meson.add_install_script('meson/post_install.py')

