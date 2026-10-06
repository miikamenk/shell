import QtQuick
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services

// Pill next to the cursor saying what releasing will do. The description
// collapses to just the icon shortly after the action changes, like ii.
StyledRect {
    id: root

    required property string action
    required property bool circle

    property bool showDescription: true

    readonly property string icon: {
        if (action === "search")
            return "image_search";
        if (action === "ocr")
            return "document_scanner";
        if (action === "record" || action === "recordSound")
            return action === "recordSound" ? "mic" : "videocam";
        if (action === "edit")
            return "edit";
        return circle ? "gesture" : "content_cut";
    }

    readonly property string description: {
        if (action === "search")
            return Tr.tr("Search with Google Lens");
        if (action === "ocr")
            return Tr.tr("Recognise text");
        if (action === "record")
            return Tr.tr("Record region");
        if (action === "recordSound")
            return Tr.tr("Record region with sound");
        if (action === "edit")
            return Tr.tr("Annotate region");
        return Tr.tr("Copy (LMB) or annotate (RMB)");
    }

    onActionChanged: {
        showDescription = true;
        descTimer.restart();
    }

    implicitHeight: iconItem.implicitHeight + Tokens.padding.small * 2
    implicitWidth: showDescription ? row.implicitWidth + Tokens.padding.small + Tokens.padding.large : implicitHeight
    clip: true

    topLeftRadius: Tokens.rounding.extraSmall
    topRightRadius: implicitHeight / 2
    bottomLeftRadius: implicitHeight / 2
    bottomRightRadius: implicitHeight / 2
    color: Colours.palette.m3primary

    Timer {
        id: descTimer

        running: true
        interval: 1000
        onTriggered: root.showDescription = false
    }

    Row {
        id: row

        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: (root.implicitHeight - iconItem.implicitWidth) / 2
        spacing: Tokens.spacing.small

        MaterialIcon {
            id: iconItem

            anchors.verticalCenter: parent.verticalCenter
            text: root.icon
            color: Colours.palette.m3onPrimary
            fontStyle: Tokens.font.icon.medium
            fill: 1
            animate: true
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: root.description
            color: Colours.palette.m3onPrimary
            font: Tokens.font.label.large
            opacity: root.showDescription ? 1 : 0

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }
    }

    Behavior on implicitWidth {
        Anim {
            type: Anim.DefaultSpatial
        }
    }
}
