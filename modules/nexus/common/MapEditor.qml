import QtQuick

// Editor for config options holding a map of names to numbers, such as font variable axes.
ObjectListEditor {
    id: root

    property var map: ({})
    property string keyLabel: qsTr("Name")
    property string valueLabel: qsTr("Value")
    property string keyPlaceholder

    signal mapEdited(map: var)

    function labelFor(item: var): string {
        return item.key ?? "";
    }

    function subtextFor(item: var): string {
        return String(item.value ?? "");
    }

    values: Object.keys(root.map ?? {}).map(k => ({
                key: k,
                value: root.map[k]
            }))
    fields: [
        {
            key: "key",
            label: root.keyLabel,
            type: "text",
            placeholder: root.keyPlaceholder,
            defaultValue: ""
        },
        {
            key: "value",
            label: root.valueLabel,
            type: "real",
            from: -1000,
            to: 1000,
            stepSize: 1,
            defaultValue: 0
        }
    ]

    onEdited: values => {
        const result = {};
        for (const entry of values)
            if (entry.key)
                result[entry.key] = entry.value;
        root.mapEdited(result);
    }
}
