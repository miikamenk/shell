pragma ComponentBehavior: Bound

import QtQuick.Layouts
import Caelestia.Config
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("On-screen display")
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
            subtext: qsTr("Show volume and brightness popups")
            checked: Config.osd.enabled
            onToggled: GlobalConfig.osd.enabled = checked
        }

        StepperRow {
            last: true
            label: qsTr("Hide delay")
            subtext: qsTr("Time the OSD stays on screen (ms)")
            value: Config.osd.hideDelay
            from: 250
            to: 10000
            stepSize: 250
            onMoved: v => GlobalConfig.osd.hideDelay = Math.round(v)
        }

        // Sliders
        SectionHeader {
            text: qsTr("Sliders")
        }

        ToggleRow {
            first: true
            text: qsTr("Brightness")
            subtext: qsTr("Show a brightness slider alongside volume")
            checked: Config.osd.enableBrightness
            onToggled: GlobalConfig.osd.enableBrightness = checked
        }

        ToggleRow {
            last: true
            text: qsTr("Microphone")
            subtext: qsTr("Show an input volume slider")
            checked: Config.osd.enableMicrophone
            onToggled: GlobalConfig.osd.enableMicrophone = checked
        }
    }
}
