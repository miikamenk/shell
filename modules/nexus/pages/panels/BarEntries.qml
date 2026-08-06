pragma ComponentBehavior: Bound

import QtQuick.Layouts
import Caelestia.Config
import qs.modules.nexus.common

PageBase {
    id: root

    readonly property var builtinEntries: ({
            logo: qsTr("OS logo"),
            workspaces: qsTr("Workspaces"),
            activeWindow: qsTr("Active window"),
            tray: qsTr("System tray"),
            clock: qsTr("Clock"),
            statusIcons: qsTr("Status icons"),
            power: qsTr("Power button"),
            spacer: qsTr("Spacer")
        })

    title: qsTr("Bar layout")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // Entries
        SectionHeader {
            first: true
            text: qsTr("Entries")
        }

        ListEditor {
            function labelFor(item: var): string {
                const prettyName = root.builtinEntries[item.id];
                if (prettyName)
                    return prettyName;
                const label = item.id.replace(/([A-Z])/g, " $1");
                return label.charAt(0).toUpperCase() + label.slice(1).toLowerCase();
            }

            function toggledFor(item: var): bool {
                return item.enabled;
            }

            z: 1
            first: true
            values: Config.bar.entries.values
            onItemMoved: (from, to) => GlobalConfig.bar.entries.move(from, to)
            onItemRemoved: index => GlobalConfig.bar.entries.remove(index)
            onItemToggled: (index, checked) => GlobalConfig.bar.entries.at(index).enabled = checked
        }

        DialogSelectButton {
            rootParent: root.flickable
            icon: "add"
            label: qsTr("Add entry")
            header: qsTr("Add new entry")
            acceptLabel: qsTr("Add")

            model: Object.keys(root.builtinEntries).map(k => ({
                        id: k,
                        label: root.builtinEntries[k]
                    }))

            onAccepted: {
                if (!selectedItem) // Should never happen but just in case
                    return;

                GlobalConfig.bar.entries.insert({
                    id: selectedItem,
                    enabled: true
                });
            }
        }

        // Screens
        SectionHeader {
            text: qsTr("Screens")
        }

        StringListEditor {
            rootParent: root.flickable
            strings: Config.bar.excludedScreens
            itemLabel: qsTr("Screen name")
            itemPlaceholder: "DP-1"
            rowIcon: "monitor"
            addLabel: qsTr("Exclude a screen")
            addHeader: qsTr("Exclude screen")
            editHeader: qsTr("Edit excluded screen")
            emptyLabel: qsTr("The bar is shown on every screen")
            onStringsEdited: values => GlobalConfig.bar.excludedScreens = values
        }
    }
}
