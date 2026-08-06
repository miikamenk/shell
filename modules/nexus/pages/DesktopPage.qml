pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components.controls
import qs.modules.nexus.common

PageBase {
    id: root

    // Desktop clock anchors, matching the states in modules/background/Background.qml
    readonly property list<MenuItem> positionItems: [
        MenuItem {
            text: qsTr("Top left")
        },
        MenuItem {
            text: qsTr("Top centre")
        },
        MenuItem {
            text: qsTr("Top right")
        },
        MenuItem {
            text: qsTr("Middle left")
        },
        MenuItem {
            text: qsTr("Middle centre")
        },
        MenuItem {
            text: qsTr("Middle right")
        },
        MenuItem {
            text: qsTr("Bottom left")
        },
        MenuItem {
            text: qsTr("Bottom centre")
        },
        MenuItem {
            text: qsTr("Bottom right")
        }
    ]
    readonly property list<string> positionValues: ["top-left", "top-center", "top-right", "middle-left", "middle-center", "middle-right", "bottom-left", "bottom-center", "bottom-right"]

    title: qsTr("Desktop")

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
            subtext: qsTr("Draw the desktop background layer on this screen")
            checked: Config.background.enabled
            onToggled: GlobalConfig.background.enabled = checked
        }

        ToggleRow {
            last: true
            text: qsTr("Display wallpaper")
            subtext: qsTr("Show the current wallpaper on the background")
            checked: Config.background.wallpaperEnabled
            onToggled: GlobalConfig.background.wallpaperEnabled = checked
        }

        // Desktop clock
        SectionHeader {
            text: qsTr("Desktop clock")
        }

        ToggleRow {
            first: true
            text: qsTr("Enabled")
            checked: Config.background.desktopClock.enabled
            onToggled: GlobalConfig.background.desktopClock.enabled = checked
        }

        SelectRow {
            label: qsTr("Position")
            subtext: qsTr("Corner of the screen the clock is anchored to")
            menuItems: root.positionItems
            active: root.positionItems[Math.max(0, root.positionValues.indexOf(Config.background.desktopClock.position))]
            onSelected: item => GlobalConfig.background.desktopClock.position = root.positionValues[root.positionItems.indexOf(item)]
        }

        StepperRow {
            label: qsTr("Scale")
            subtext: qsTr("Size of the clock relative to its default")
            value: Config.background.desktopClock.scale
            from: 0.2
            to: 5
            stepSize: 0.1
            onMoved: v => GlobalConfig.background.desktopClock.scale = v
        }

        ToggleRow {
            last: true
            text: qsTr("Invert colours")
            subtext: qsTr("Use the inverse palette, for light wallpapers")
            checked: Config.background.desktopClock.invertColors
            onToggled: GlobalConfig.background.desktopClock.invertColors = checked
        }

        // Clock background
        SectionHeader {
            text: qsTr("Clock background")
        }

        ToggleRow {
            first: true
            text: qsTr("Enabled")
            subtext: qsTr("Draw a panel behind the clock")
            checked: Config.background.desktopClock.background.enabled
            onToggled: GlobalConfig.background.desktopClock.background.enabled = checked
        }

        ToggleRow {
            text: qsTr("Blur")
            subtext: qsTr("Blur the wallpaper behind the panel")
            checked: Config.background.desktopClock.background.blur
            onToggled: GlobalConfig.background.desktopClock.background.blur = checked
        }

        StepperRow {
            last: true
            label: qsTr("Opacity")
            value: Config.background.desktopClock.background.opacity
            from: 0
            to: 1
            stepSize: 0.05
            onMoved: v => GlobalConfig.background.desktopClock.background.opacity = v
        }

        // Clock shadow
        SectionHeader {
            text: qsTr("Clock shadow")
        }

        ToggleRow {
            first: true
            text: qsTr("Enabled")
            subtext: qsTr("Drop a shadow behind the clock text")
            checked: Config.background.desktopClock.shadow.enabled
            onToggled: GlobalConfig.background.desktopClock.shadow.enabled = checked
        }

        StepperRow {
            label: qsTr("Opacity")
            value: Config.background.desktopClock.shadow.opacity
            from: 0
            to: 1
            stepSize: 0.05
            onMoved: v => GlobalConfig.background.desktopClock.shadow.opacity = v
        }

        StepperRow {
            last: true
            label: qsTr("Blur")
            subtext: qsTr("How soft the shadow is")
            value: Config.background.desktopClock.shadow.blur
            from: 0
            to: 1
            stepSize: 0.05
            onMoved: v => GlobalConfig.background.desktopClock.shadow.blur = v
        }

        // Visualiser
        SectionHeader {
            text: qsTr("Audio visualiser")
        }

        ToggleRow {
            first: true
            text: qsTr("Enabled")
            subtext: qsTr("Show an audio visualiser on the desktop")
            checked: Config.background.visualiser.enabled
            onToggled: GlobalConfig.background.visualiser.enabled = checked
        }

        ToggleRow {
            text: qsTr("Auto hide")
            subtext: qsTr("Hide while a tiled window is open")
            checked: Config.background.visualiser.autoHide
            onToggled: GlobalConfig.background.visualiser.autoHide = checked
        }

        ToggleRow {
            text: qsTr("Blur")
            subtext: qsTr("Blur the wallpaper behind the bars")
            checked: Config.background.visualiser.blur
            onToggled: GlobalConfig.background.visualiser.blur = checked
        }

        StepperRow {
            label: qsTr("Rounding")
            subtext: qsTr("Corner radius of the bars, relative to the default")
            value: Config.background.visualiser.rounding
            from: 0
            to: 5
            stepSize: 0.1
            onMoved: v => GlobalConfig.background.visualiser.rounding = v
        }

        StepperRow {
            last: true
            label: qsTr("Spacing")
            subtext: qsTr("Gap between the bars, relative to the default")
            value: Config.background.visualiser.spacing
            from: 0
            to: 5
            stepSize: 0.1
            onMoved: v => GlobalConfig.background.visualiser.spacing = v
        }
    }
}
