pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

// Editor for config options holding a list of objects (QVariantList of maps).
// Each entry opens a dialog built from `fields`; the whole list is written back on save.
//
// A field is { key, label, type, ... } where type is one of:
//   "text"    plain string
//   "command" argv, shown space separated
//   "int"     integer, honours from/to/stepSize
//   "real"    same, with decimals
//   "bool"    switch
//   "select"  one of `options`: [{ label, value, icon }], where an option may instead
//             carry custom: "text" | "command" to let the value be typed in
ColumnLayout {
    id: root

    required property Item rootParent
    required property var values
    required property list<var> fields

    property bool first: true
    property string rowIcon: "chevron_right"
    property string addLabel: qsTr("Add entry")
    property string addHeader: qsTr("Add new entry")
    property string editHeader: qsTr("Edit entry")
    property string emptyLabel: qsTr("No entries")

    signal edited(values: var)

    function labelFor(item: var): string {
        return String(item[root.fields[0].key] ?? "");
    }

    function subtextFor(item: var): string {
        return "";
    }

    // Entry used when adding, so new entries start from sane values
    function blankEntry(): var {
        const entry = {};
        for (const field of root.fields)
            if (field.defaultValue !== undefined)
                entry[field.key] = field.defaultValue;
        return entry;
    }

    function copyValues(): var {
        return (root.values ?? []).map(v => Object.assign({}, v));
    }

    // Unset optional keys are dropped so they don't clutter the config file
    function prune(entry: var): var {
        const result = {};
        for (const key of Object.keys(entry)) {
            const value = entry[key];
            if (value === "" || value === undefined || value === null)
                continue;
            if (Array.isArray(value) && value.length === 0)
                continue;
            result[key] = value;
        }
        return result;
    }

    function replaceAt(index: int, entry: var): void {
        const list = copyValues();
        if (index < 0)
            list.push(prune(entry));
        else
            list[index] = prune(entry);
        root.edited(list);
    }

    function removeAt(index: int): void {
        const list = copyValues();
        list.splice(index, 1);
        root.edited(list);
    }

    Layout.fillWidth: true
    spacing: Tokens.spacing.extraSmall / 2

    ConnectedRect {
        Layout.fillWidth: true
        visible: (root.values?.length ?? 0) === 0
        first: root.first
        implicitHeight: emptyText.implicitHeight + Tokens.padding.largeIncreased * 2

        StyledText {
            id: emptyText

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: Tokens.padding.largeIncreased
            anchors.rightMargin: Tokens.padding.largeIncreased

            text: root.emptyLabel
            color: Colours.palette.m3outline
            font: Tokens.font.body.small
            elide: Text.ElideRight
        }
    }

    Repeater {
        model: root.values ?? []

        DialogRowButton {
            id: entryRow

            required property var modelData
            required property int index

            // Edits land here so they survive the dialog content being unloaded
            property var draft: ({})

            Layout.fillWidth: true
            z: open ? 2 : 0

            rootParent: root.rootParent
            first: root.first && index === 0
            last: false
            icon: root.rowIcon
            label: root.labelFor(modelData)
            subtext: root.subtextFor(modelData)
            trailingIcon: "edit"
            header: root.editHeader
            acceptLabel: qsTr("Save")
            destructiveLabel: qsTr("Delete")
            separateContent: true

            onOpenChanged: {
                if (open)
                    draft = Object.assign({}, modelData);
            }
            onAccepted: root.replaceAt(index, draft)
            onDestructed: root.removeAt(index)

            content: Component {
                ObjectFieldForm {
                    fields: root.fields
                    draft: entryRow.draft
                }
            }
        }
    }

    DialogRowButton {
        id: addRow

        property var draft: ({})

        Layout.fillWidth: true
        z: open ? 2 : 0

        rootParent: root.rootParent
        icon: "add"
        label: root.addLabel
        header: root.addHeader
        acceptLabel: qsTr("Add")
        separateContent: true

        onOpenChanged: {
            if (open)
                draft = root.blankEntry();
        }
        onAccepted: root.replaceAt(-1, draft)

        content: Component {
            ObjectFieldForm {
                fields: root.fields
                draft: addRow.draft
            }
        }
    }
}
