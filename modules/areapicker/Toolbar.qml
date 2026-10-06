pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.effects
import qs.services

// M3 floating toolbar with a paired close FAB, the Caelestia take on ii's
// region selector controls. Picks the selection shape and the action.
Item {
    id: root

    required property LazyLoader loader
    property bool shown

    readonly property string action: loader.action // qmllint disable missing-property
    readonly property bool isRecord: action === "record" || action === "recordSound"
    readonly property bool hovered: hover.hovered

    signal closeRequested

    implicitWidth: bar.implicitWidth + Tokens.spacing.small + fab.implicitWidth
    implicitHeight: bar.implicitHeight

    opacity: shown ? 1 : 0
    scale: shown ? 1 : 0.8

    HoverHandler {
        id: hover
    }

    // Swallow clicks (incl. right click) so they don't start a selection
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        cursorShape: Qt.ArrowCursor
    }

    StyledRect {
        id: bar

        implicitWidth: row.implicitWidth + Tokens.padding.small * 2
        implicitHeight: row.implicitHeight + Tokens.padding.small * 2
        radius: Tokens.rounding.full
        color: Colours.palette.m3surfaceContainer

        Elevation {
            anchors.fill: parent
            radius: parent.radius
            z: -1
            level: 3
        }

        Row {
            id: row

            anchors.centerIn: parent
            spacing: Tokens.spacing.extraSmall

            ToolButton {
                icon: "crop_free"
                label: Tr.tr("Rect")
                checked: !root.loader.circle // qmllint disable missing-property
                onClicked: root.loader.circle = false // qmllint disable missing-property
            }

            ToolButton {
                icon: "gesture"
                label: Tr.tr("Lasso")
                checked: root.loader.circle // qmllint disable missing-property
                onClicked: root.loader.circle = true // qmllint disable missing-property
            }

            StyledRect {
                anchors.verticalCenter: parent.verticalCenter
                implicitWidth: 1
                implicitHeight: parent.height * 0.6
                color: Colours.palette.m3outlineVariant
            }

            ToolButton {
                icon: root.action === "edit" ? "edit" : "content_cut"
                label: root.action === "edit" ? Tr.tr("Annotate") : Tr.tr("Copy")
                checked: root.action === "copy" || root.action === "edit"
                onClicked: {
                    if (!checked)
                        root.loader.action = "copy"; // qmllint disable missing-property
                }
            }

            ToolButton {
                icon: "image_search"
                label: Tr.tr("Lens")
                checked: root.action === "search"
                onClicked: root.loader.action = "search" // qmllint disable missing-property
            }

            ToolButton {
                icon: "document_scanner"
                label: Tr.tr("Text")
                checked: root.action === "ocr"
                onClicked: root.loader.action = "ocr" // qmllint disable missing-property
            }

            ToolButton {
                icon: "videocam"
                label: Tr.tr("Record")
                checked: root.isRecord
                onClicked: {
                    if (!checked)
                        root.loader.action = "record"; // qmllint disable missing-property
                }
            }

            // Sound toggle, only while recording is selected
            Item {
                anchors.verticalCenter: parent.verticalCenter
                implicitWidth: root.isRecord ? mic.implicitWidth : 0
                implicitHeight: mic.implicitHeight
                clip: true
                opacity: root.isRecord ? 1 : 0

                ToolButton {
                    id: mic

                    icon: root.action === "recordSound" ? "mic" : "mic_off"
                    tonal: true
                    checked: root.action === "recordSound"
                    onClicked: root.loader.action = checked ? "record" : "recordSound" // qmllint disable missing-property
                }

                Behavior on implicitWidth {
                    Anim {
                        type: Anim.FastSpatial
                    }
                }

                Behavior on opacity {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }
            }
        }
    }

    StyledRect {
        id: fab

        anchors.left: bar.right
        anchors.leftMargin: Tokens.spacing.small
        anchors.verticalCenter: bar.verticalCenter

        implicitWidth: bar.implicitHeight
        implicitHeight: bar.implicitHeight
        radius: closeState.pressed ? Tokens.rounding.medium : Tokens.rounding.large
        color: Colours.palette.m3primaryContainer

        Elevation {
            anchors.fill: parent
            radius: parent.radius
            z: -1
            level: 3
        }

        StateLayer {
            id: closeState

            color: Colours.palette.m3onPrimaryContainer
            onClicked: root.closeRequested()
        }

        MaterialIcon {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: 1
            text: "close"
            color: Colours.palette.m3onPrimaryContainer
            fontStyle: Tokens.font.icon.large
        }

        Behavior on radius {
            Anim {
                type: Anim.FastSpatial
            }
        }
    }

    Behavior on opacity {
        Anim {
            type: Anim.DefaultEffects
        }
    }

    Behavior on scale {
        Anim {
            type: Anim.DefaultSpatial
        }
    }

    Behavior on anchors.bottomMargin {
        Anim {
            type: Anim.DefaultSpatial
        }
    }

    // Selected items fill and grow a label, M3 expressive toolbar style
    component ToolButton: StyledRect {
        id: btn

        property string icon
        property string label
        property bool checked
        property bool tonal
        readonly property bool expanded: checked && label !== ""
        readonly property color onColour: {
            if (!checked)
                return Colours.palette.m3onSurfaceVariant;
            return tonal ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onPrimary;
        }

        signal clicked

        anchors.verticalCenter: parent?.verticalCenter

        implicitHeight: iconItem.implicitHeight + Tokens.padding.small * 2 + 4
        implicitWidth: expanded ? content.implicitWidth + content.anchors.leftMargin + Tokens.padding.large : implicitHeight
        clip: true

        radius: btnState.pressed ? Tokens.rounding.small : Tokens.rounding.full
        color: checked ? (tonal ? Colours.palette.m3secondaryContainer : Colours.palette.m3primary) : "transparent"

        StateLayer {
            id: btnState

            color: btn.onColour
            onClicked: btn.clicked()
        }

        Row {
            id: content

            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: (btn.implicitHeight - iconItem.implicitWidth) / 2
            spacing: Tokens.spacing.small

            MaterialIcon {
                id: iconItem

                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: 1
                text: btn.icon
                color: btn.onColour
                fontStyle: Tokens.font.icon.medium
                fill: btn.checked ? 1 : 0
                animate: true

                Behavior on fill {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: btn.label
                color: btn.onColour
                font: Tokens.font.label.large
                opacity: btn.expanded ? 1 : 0

                Behavior on opacity {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }
            }
        }

        Behavior on implicitWidth {
            Anim {
                type: Anim.FastSpatial
            }
        }

        Behavior on radius {
            Anim {
                type: Anim.FastSpatial
            }
        }
    }
}
