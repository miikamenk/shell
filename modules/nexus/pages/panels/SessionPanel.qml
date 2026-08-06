pragma ComponentBehavior: Bound

import QtQuick.Layouts
import Caelestia.Config
import qs.modules.nexus.common

PageBase {
    id: root

    function toCommand(value: string): var {
        const trimmed = value.trim();
        return trimmed ? trimmed.split(/\s+/) : [];
    }

    title: qsTr("Session menu")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // General
        SectionHeader {
            first: true
            text: qsTr("General")
        }

        ToggleRow {
            first: true
            text: qsTr("Enabled")
            subtext: qsTr("Show the session menu")
            checked: Config.session.enabled
            onToggled: GlobalConfig.session.enabled = checked
        }

        ToggleRow {
            text: qsTr("Vim keybinds")
            subtext: qsTr("Navigate the session menu with hjkl")
            checked: Config.session.vimKeybinds
            onToggled: GlobalConfig.session.vimKeybinds = checked
        }

        StepperRow {
            last: true
            label: qsTr("Drag threshold")
            subtext: qsTr("Pixels dragged before the session menu opens")
            value: Config.session.dragThreshold
            from: 0
            to: 200
            stepSize: 5
            onMoved: v => GlobalConfig.session.dragThreshold = Math.round(v)
        }

        // Icons
        SectionHeader {
            text: qsTr("Icons")
        }

        TextFieldRow {
            first: true
            label: qsTr("Log out")
            subtext: qsTr("Material symbol name")
            value: Config.session.icons.logout
            placeholderText: "logout"
            onEditingFinished: value => GlobalConfig.session.icons.logout = value
        }

        TextFieldRow {
            label: qsTr("Shut down")
            subtext: qsTr("Material symbol name")
            value: Config.session.icons.shutdown
            placeholderText: "power_settings_new"
            onEditingFinished: value => GlobalConfig.session.icons.shutdown = value
        }

        TextFieldRow {
            label: qsTr("Hibernate")
            subtext: qsTr("Material symbol name")
            value: Config.session.icons.hibernate
            placeholderText: "downloading"
            onEditingFinished: value => GlobalConfig.session.icons.hibernate = value
        }

        TextFieldRow {
            last: true
            label: qsTr("Reboot")
            subtext: qsTr("Material symbol name")
            value: Config.session.icons.reboot
            placeholderText: "cached"
            onEditingFinished: value => GlobalConfig.session.icons.reboot = value
        }

        // Commands
        SectionHeader {
            text: qsTr("Commands")
        }

        TextFieldRow {
            first: true
            label: qsTr("Log out")
            subtext: qsTr("Command run by the log out button")
            value: Config.session.commands.logout.join(" ")
            placeholderText: "logout"
            onEditingFinished: value => GlobalConfig.session.commands.logout = root.toCommand(value)
        }

        TextFieldRow {
            label: qsTr("Shut down")
            subtext: qsTr("Command run by the shut down button")
            value: Config.session.commands.shutdown.join(" ")
            placeholderText: "poweroff"
            onEditingFinished: value => GlobalConfig.session.commands.shutdown = root.toCommand(value)
        }

        TextFieldRow {
            label: qsTr("Hibernate")
            subtext: qsTr("Command run by the hibernate button")
            value: Config.session.commands.hibernate.join(" ")
            placeholderText: "hibernate"
            onEditingFinished: value => GlobalConfig.session.commands.hibernate = root.toCommand(value)
        }

        TextFieldRow {
            last: true
            label: qsTr("Reboot")
            subtext: qsTr("Command run by the reboot button")
            value: Config.session.commands.reboot.join(" ")
            placeholderText: "reboot"
            onEditingFinished: value => GlobalConfig.session.commands.reboot = root.toCommand(value)
        }
    }
}
