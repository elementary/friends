project('io.elementary.friends', 'vala', 'c')

gnome = import('gnome')
i18n = import('i18n')

add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format (meson.project_name()), language:'c')

executable(
    meson.project_name(),
    'src/Application.vala',
    'src/MainWindow.vala',
    'src/IndividualView.vala',
    'src/Widgets/ContactRow.vala',
    'src/Widgets/NameGroup.vala',
    'src/Widgets/EmailGroup/EmailGroup.vala',
    'src/Widgets/EmailGroup/EmailGroupRow.vala',
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

meson.add_install_script('meson/post_install.py')

