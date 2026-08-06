pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.modules.nexus.common

PageBase {
    id: root

    // Sub-page index of FontStyle in the Appearance stack, opened once a style is picked
    readonly property int fontStylePage: 1

    readonly property list<var> fontStyles: [
        {
            key: "headline",
            label: qsTr("Headline"),
            icon: "title"
        },
        {
            key: "title",
            label: qsTr("Title"),
            icon: "format_h2"
        },
        {
            key: "body",
            label: qsTr("Body"),
            icon: "format_paragraph"
        },
        {
            key: "label",
            label: qsTr("Label"),
            icon: "label"
        },
        {
            key: "mono",
            label: qsTr("Monospace"),
            icon: "code"
        },
        {
            key: "icon",
            label: qsTr("Icons"),
            icon: "emoji_symbols"
        }
    ]

    function openFontStyle(key: string): void {
        nState.selectedFontStyle = key;
        nState.openSubPage(fontStylePage);
    }

    title: qsTr("Appearance")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // Scaling
        SectionHeader {
            first: true
            text: qsTr("Scaling")
        }

        StepperRow {
            first: true
            label: qsTr("Font scale")
            subtext: qsTr("Multiplier applied to every font size")
            value: Config.appearance.font.scale
            from: 0.5
            to: 3
            stepSize: 0.05
            onMoved: v => GlobalConfig.appearance.font.scale = v
        }

        StepperRow {
            label: qsTr("Rounding scale")
            subtext: qsTr("Multiplier applied to corner radii")
            value: Config.appearance.rounding.scale
            from: 0
            to: 3
            stepSize: 0.05
            onMoved: v => GlobalConfig.appearance.rounding.scale = v
        }

        StepperRow {
            label: qsTr("Spacing scale")
            subtext: qsTr("Multiplier applied to gaps between elements")
            value: Config.appearance.spacing.scale
            from: 0
            to: 3
            stepSize: 0.05
            onMoved: v => GlobalConfig.appearance.spacing.scale = v
        }

        StepperRow {
            label: qsTr("Padding scale")
            subtext: qsTr("Multiplier applied to padding inside elements")
            value: Config.appearance.padding.scale
            from: 0
            to: 3
            stepSize: 0.05
            onMoved: v => GlobalConfig.appearance.padding.scale = v
        }

        StepperRow {
            label: qsTr("Deform scale")
            subtext: qsTr("How much shapes squash when pressed")
            value: Config.appearance.deformScale
            from: 0
            to: 3
            stepSize: 0.05
            onMoved: v => GlobalConfig.appearance.deformScale = v
        }

        StepperRow {
            last: true
            label: qsTr("Animation duration scale")
            subtext: qsTr("Higher is slower, 0 disables animations")
            value: GlobalConfig.appearance.anim.durations.scale
            from: 0
            to: 5
            stepSize: 0.05
            onMoved: v => GlobalConfig.appearance.anim.durations.scale = v
        }

        // Transparency
        SectionHeader {
            text: qsTr("Transparency")
        }

        ToggleRow {
            first: true
            text: qsTr("Enabled")
            subtext: qsTr("Make shell surfaces translucent")
            checked: GlobalConfig.appearance.transparency.enabled
            onToggled: GlobalConfig.appearance.transparency.enabled = checked
        }

        StepperRow {
            label: qsTr("Base opacity")
            subtext: qsTr("Opacity of panel backgrounds")
            value: GlobalConfig.appearance.transparency.base
            from: 0
            to: 1
            stepSize: 0.05
            onMoved: v => GlobalConfig.appearance.transparency.base = v
        }

        StepperRow {
            last: true
            label: qsTr("Layer opacity")
            subtext: qsTr("Opacity of elements drawn on top of panels")
            value: GlobalConfig.appearance.transparency.layers
            from: 0
            to: 1
            stepSize: 0.05
            onMoved: v => GlobalConfig.appearance.transparency.layers = v
        }

        // Fonts
        SectionHeader {
            text: qsTr("Fonts")
        }

        Repeater {
            model: root.fontStyles

            NavRow {
                required property var modelData
                required property int index

                first: index === 0
                icon: modelData.icon
                text: modelData.label
                subtext: GlobalConfig.appearance.font[modelData.key]?.family ?? ""
                onClicked: root.openFontStyle(modelData.key)
            }
        }

        TextFieldRow {
            label: qsTr("Clock font")
            subtext: qsTr("Used by the taskbar and desktop clocks")
            value: Config.appearance.font.clock
            placeholderText: "Rubik"
            onEditingFinished: value => GlobalConfig.appearance.font.clock = value
        }

        TextFieldRow {
            last: true
            label: qsTr("Workspaces font")
            subtext: qsTr("Used by the workspace labels")
            value: Config.appearance.font.workspaces
            placeholderText: "Rubik"
            onEditingFinished: value => GlobalConfig.appearance.font.workspaces = value
        }
    }
}
