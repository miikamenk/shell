pragma ComponentBehavior: Bound

import QtQuick.Layouts
import Caelestia.Config
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Lock screen")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // Appearance
        SectionHeader {
            first: true
            text: qsTr("Appearance")
        }

        ToggleRow {
            first: true
            text: qsTr("Show lock UI")
            subtext: qsTr("Screens with this off only show the blurred background")
            checked: Config.lock.enabled
            onToggled: GlobalConfig.lock.enabled = checked
        }

        ToggleRow {
            text: qsTr("Use wallpaper")
            subtext: qsTr("Blur the wallpaper instead of the screen contents")
            checked: Config.lock.useWallpaper
            onToggled: GlobalConfig.lock.useWallpaper = checked
        }

        ToggleRow {
            last: true
            text: qsTr("Recolour logo")
            subtext: qsTr("Tint the distro logo with the current scheme")
            checked: Config.lock.recolourLogo
            onToggled: GlobalConfig.lock.recolourLogo = checked
        }

        // Notifications
        SectionHeader {
            text: qsTr("Notifications")
        }

        ToggleRow {
            first: true
            last: true
            text: qsTr("Hide notifications")
            subtext: qsTr("Keep notification contents private while locked")
            checked: Config.lock.hideNotifs
            onToggled: GlobalConfig.lock.hideNotifs = checked
        }

        // Fingerprint
        SectionHeader {
            text: qsTr("Fingerprint")
        }

        ToggleRow {
            first: true
            text: qsTr("Enabled")
            subtext: qsTr("Unlock with a fingerprint reader via PAM")
            checked: GlobalConfig.lock.enableFprint
            onToggled: GlobalConfig.lock.enableFprint = checked
        }

        StepperRow {
            last: true
            label: qsTr("Max attempts")
            subtext: qsTr("Fingerprint tries before falling back to a password")
            value: GlobalConfig.lock.maxFprintTries
            from: 1
            to: 10
            stepSize: 1
            onMoved: v => GlobalConfig.lock.maxFprintTries = Math.round(v)
        }

        // Face unlock
        SectionHeader {
            text: qsTr("Face unlock")
        }

        ToggleRow {
            first: true
            text: qsTr("Enabled")
            subtext: qsTr("Unlock with Howdy face recognition")
            checked: GlobalConfig.lock.enableHowdy
            onToggled: GlobalConfig.lock.enableHowdy = checked
        }

        ToggleRow {
            text: qsTr("Try on wake")
            subtext: qsTr("Attempt face unlock as soon as the screen wakes")
            checked: GlobalConfig.lock.triggerHowdyOnWake
            onToggled: GlobalConfig.lock.triggerHowdyOnWake = checked
        }

        StepperRow {
            last: true
            label: qsTr("Max attempts")
            subtext: qsTr("Face unlock tries before falling back to a password")
            value: GlobalConfig.lock.maxHowdyTries
            from: 1
            to: 10
            stepSize: 1
            onMoved: v => GlobalConfig.lock.maxHowdyTries = Math.round(v)
        }
    }
}
