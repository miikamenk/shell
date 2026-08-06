import QtQuick

// Editor for config options holding a plain list of strings.
ObjectListEditor {
    id: root

    property var strings: []
    property string itemLabel: qsTr("Value")
    property string itemPlaceholder

    signal stringsEdited(values: var)

    function labelFor(item: var): string {
        return item.value ?? "";
    }

    values: (root.strings ?? []).map(s => ({
                value: s
            }))
    fields: [
        {
            key: "value",
            label: root.itemLabel,
            type: "text",
            placeholder: root.itemPlaceholder,
            defaultValue: ""
        }
    ]

    onEdited: values => root.stringsEdited(values.map(v => v.value ?? "").filter(v => v))
}
