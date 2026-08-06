pragma ComponentBehavior: Bound

import QtQuick.Layouts
import Caelestia.Config
import qs.modules.nexus.common

PageBase {
    id: root

    readonly property list<var> actionFields: [
        {
            key: "name",
            label: qsTr("Name"),
            type: "text",
            placeholder: qsTr("Calculator"),
            defaultValue: ""
        },
        {
            key: "icon",
            label: qsTr("Icon"),
            type: "text",
            placeholder: "calculate",
            hint: qsTr("Material symbol name"),
            defaultValue: ""
        },
        {
            key: "description",
            label: qsTr("Description"),
            type: "text",
            defaultValue: ""
        },
        {
            key: "command",
            label: qsTr("Command"),
            type: "command",
            hint: qsTr("Arguments separated by spaces"),
            defaultValue: []
        },
        {
            key: "dangerous",
            label: qsTr("Dangerous"),
            type: "bool",
            defaultValue: false
        }
    ]

    title: qsTr("Launcher actions")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: qsTr("Actions")
        }

        ObjectListEditor {
            function labelFor(item: var): string {
                return item.name || qsTr("Unnamed action");
            }

            function subtextFor(item: var): string {
                return (item.command ?? []).join(" ");
            }

            rootParent: root.flickable
            values: GlobalConfig.launcher.actions
            fields: root.actionFields
            rowIcon: "bolt"
            addLabel: qsTr("Add action")
            addHeader: qsTr("Add new action")
            editHeader: qsTr("Edit action")
            emptyLabel: qsTr("No actions")
            onEdited: values => GlobalConfig.launcher.actions = values
        }
    }
}
