pragma ComponentBehavior: Bound

import QtQuick.Layouts
import Caelestia.Config
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Screen border")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        StepperRow {
            first: true
            label: qsTr("Thickness")
            subtext: qsTr("Width of the border drawn around the screen (px, min %1)").arg(Config.border.minThickness)
            value: Config.border.thickness
            from: 0
            to: 100
            stepSize: 1
            onMoved: v => GlobalConfig.border.thickness = Math.round(v)
        }

        StepperRow {
            label: qsTr("Rounding")
            subtext: qsTr("Corner radius of the screen border (px)")
            value: Config.border.rounding
            from: 0
            to: 100
            stepSize: 1
            onMoved: v => GlobalConfig.border.rounding = Math.round(v)
        }

        StepperRow {
            last: true
            label: qsTr("Smoothing")
            subtext: qsTr("How gradually panels blend into the border")
            value: Config.border.smoothing
            from: 0
            to: 100
            stepSize: 1
            onMoved: v => GlobalConfig.border.smoothing = Math.round(v)
        }
    }
}
