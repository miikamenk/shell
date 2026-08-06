pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components.controls
import qs.modules.nexus.common

PageBase {
    id: root

    readonly property string style: nState.selectedFontStyle || "body"
    readonly property var styleConfig: GlobalConfig.appearance.font[style] ?? null
    // Icons get an extra size on top of the three every other style has
    readonly property list<string> sizes: style === "icon" ? ["extraLarge", "large", "medium", "small"] : ["large", "medium", "small"]

    readonly property var sizeLabels: ({
            extraLarge: qsTr("Extra large"),
            large: qsTr("Large"),
            medium: qsTr("Medium"),
            small: qsTr("Small")
        })
    readonly property var styleLabels: ({
            headline: qsTr("Headline"),
            title: qsTr("Title"),
            body: qsTr("Body"),
            label: qsTr("Label"),
            mono: qsTr("Monospace"),
            icon: qsTr("Icons")
        })

    readonly property list<MenuItem> weightItems: [
        MenuItem {
            text: qsTr("Thin")
        },
        MenuItem {
            text: qsTr("Extra light")
        },
        MenuItem {
            text: qsTr("Light")
        },
        MenuItem {
            text: qsTr("Normal")
        },
        MenuItem {
            text: qsTr("Medium")
        },
        MenuItem {
            text: qsTr("Demi bold")
        },
        MenuItem {
            text: qsTr("Bold")
        },
        MenuItem {
            text: qsTr("Extra bold")
        },
        MenuItem {
            text: qsTr("Black")
        }
    ]
    readonly property list<int> weightValues: [100, 200, 300, 400, 500, 600, 700, 800, 900]

    function weightIndex(weight: int): int {
        const idx = weightValues.indexOf(weight);
        return idx < 0 ? 3 : idx;
    }

    function configForSize(size: string): var {
        return styleConfig ? styleConfig[size] : null;
    }

    title: styleLabels[style] ?? qsTr("Font")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // Family
        SectionHeader {
            first: true
            text: qsTr("Family")
        }

        TextFieldRow {
            first: true
            last: true
            label: qsTr("Font family")
            subtext: qsTr("Used by every size unless overridden below")
            value: root.styleConfig?.family ?? ""
            placeholderText: "GoogleSansFlex"
            onEditingFinished: value => {
                if (root.styleConfig)
                    root.styleConfig.family = value;
            }
        }

        Repeater {
            model: root.sizes

            SizeSection {}
        }
    }

    component SizeSection: ColumnLayout {
        id: section

        required property string modelData
        readonly property var sizeConfig: root.configForSize(modelData)

        Layout.fillWidth: true
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            text: root.sizeLabels[section.modelData] ?? section.modelData
        }

        TextFieldRow {
            first: true
            label: qsTr("Family override")
            subtext: qsTr("Empty inherits the style's family")
            value: section.sizeConfig?.family ?? ""
            onEditingFinished: value => {
                if (section.sizeConfig)
                    section.sizeConfig.family = value;
            }
        }

        StepperRow {
            label: qsTr("Size")
            subtext: qsTr("Point size before the font scale is applied")
            value: section.sizeConfig?.size ?? 0
            from: 1
            to: 96
            stepSize: 1
            onMoved: v => {
                if (section.sizeConfig)
                    section.sizeConfig.size = Math.round(v);
            }
        }

        SelectRow {
            label: qsTr("Weight")
            menuItems: root.weightItems
            active: root.weightItems[root.weightIndex(section.sizeConfig?.weight ?? 400)]
            onSelected: item => {
                if (section.sizeConfig)
                    section.sizeConfig.weight = root.weightValues[root.weightItems.indexOf(item)];
            }
        }

        ToggleRow {
            last: true
            text: qsTr("Italic")
            checked: section.sizeConfig?.italic ?? false
            onToggled: {
                if (section.sizeConfig)
                    section.sizeConfig.italic = checked;
            }
        }

        SectionHeader {
            text: qsTr("%1 variable axes").arg(root.sizeLabels[section.modelData] ?? section.modelData)
        }

        MapEditor {
            rootParent: root.flickable
            map: section.sizeConfig?.vaxes ?? ({})
            keyLabel: qsTr("Axis")
            keyPlaceholder: "ROND"
            valueLabel: qsTr("Value")
            rowIcon: "tune"
            addLabel: qsTr("Add axis")
            addHeader: qsTr("Add variable axis")
            editHeader: qsTr("Edit variable axis")
            emptyLabel: qsTr("No variable axes set")
            onMapEdited: map => {
                if (section.sizeConfig)
                    section.sizeConfig.vaxes = map;
            }
        }
    }
}
