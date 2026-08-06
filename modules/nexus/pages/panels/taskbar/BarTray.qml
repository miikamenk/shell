pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.modules.nexus.common

PageBase {
    id: root

    readonly property list<var> iconSubFields: [
        {
            key: "id",
            label: Tr.tr("Tray item ID"),
            type: "text",
            hint: Tr.tr("The ID reported by the app, e.g. steam"),
            defaultValue: ""
        },
        {
            key: "icon",
            label: Tr.tr("Icon name"),
            type: "text",
            hint: Tr.tr("Icon theme name to use instead"),
            defaultValue: ""
        },
        {
            key: "image",
            label: Tr.tr("Image path"),
            type: "text",
            hint: Tr.tr("Takes priority over the icon name"),
            defaultValue: ""
        }
    ]

    title: Tr.tr("Tray")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // Appearance
        SectionHeader {
            first: true
            text: Tr.tr("Appearance")
        }

        ToggleRow {
            first: true
            text: Tr.trCtx("Background", "taskbar tray: draw a background behind the tray")
            checked: Config.bar.tray.background
            onToggled: GlobalConfig.bar.tray.background = checked
        }

        ToggleRow {
            // TRANSLATORS: tint system tray icons with the theme accent colour
            text: Tr.tr("Recolour icons")
            checked: Config.bar.tray.recolour
            onToggled: GlobalConfig.bar.tray.recolour = checked
        }

        ToggleRow {
            text: Tr.trCtx("Compact", "taskbar tray layout")
            checked: Config.bar.tray.compact
            onToggled: GlobalConfig.bar.tray.compact = checked
        }

        ToggleRow {
            last: true
            text: Tr.tr("Popout on hover")
            subtext: Tr.tr("Show the tray menu popout when hovering")
            checked: Config.bar.popouts.tray
            onToggled: GlobalConfig.bar.popouts.tray = checked
        }

        // Hidden icons
        SectionHeader {
            text: Tr.tr("Hidden icons")
        }

        StringListEditor {
            rootParent: root.flickable
            strings: GlobalConfig.bar.tray.hiddenIcons
            itemLabel: Tr.tr("Tray item ID")
            itemPlaceholder: "spotify"
            rowIcon: "visibility_off"
            addLabel: Tr.tr("Hide an icon")
            addHeader: Tr.tr("Hide tray icon")
            editHeader: Tr.tr("Edit hidden icon")
            emptyLabel: Tr.tr("All tray icons are shown")
            onStringsEdited: values => GlobalConfig.bar.tray.hiddenIcons = values
        }

        // Icon substitutions
        SectionHeader {
            text: Tr.tr("Icon substitutions")
        }

        ObjectListEditor {
            function labelFor(item: var): string {
                return item.id || Tr.tr("Unnamed substitution");
            }

            function subtextFor(item: var): string {
                return item.image || item.icon || "";
            }

            rootParent: root.flickable
            values: GlobalConfig.bar.tray.iconSubs
            fields: root.iconSubFields
            rowIcon: "swap_horiz"
            addLabel: Tr.tr("Add substitution")
            addHeader: Tr.tr("Add icon substitution")
            editHeader: Tr.tr("Edit icon substitution")
            emptyLabel: Tr.tr("Apps use the icons they report")
            onEdited: values => GlobalConfig.bar.tray.iconSubs = values
        }
    }
}
