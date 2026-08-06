pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.components.controls
import qs.services

// Form for a single config list entry. Fields write straight into `draft`,
// which the owner reads back when the dialog is accepted.
VerticalFadeFlickable {
    id: root

    // Each field is { key, label, type, ... }. See ObjectListEditor for the supported types.
    required property list<var> fields
    required property var draft

    function valueOf(field: var): var {
        const v = root.draft[field.key];
        return v === undefined ? field.defaultValue : v;
    }

    function setValue(field: var, value: var): void {
        root.draft[field.key] = value;
    }

    // Index of the option matching the current value, falling back to the custom option
    // whose kind matches the value's type (a command is a list, a dispatch is a string).
    function optionIndex(field: var, value: var): int {
        const options = field.options ?? [];
        const json = JSON.stringify(value ?? null);
        const exact = options.findIndex(o => !o.custom && JSON.stringify(o.value ?? null) === json);
        if (exact >= 0)
            return exact;

        const kind = Array.isArray(value) ? "command" : "text";
        const custom = options.findIndex(o => o.custom === kind);
        return custom >= 0 ? custom : 0;
    }

    function customText(value: var): string {
        if (Array.isArray(value))
            return value.join(" ");
        return value === undefined || value === null ? "" : String(value);
    }

    contentHeight: content.implicitHeight
    topMargin: Tokens.padding.medium
    bottomMargin: Tokens.padding.medium

    ColumnLayout {
        id: content

        anchors.left: parent.left
        anchors.right: parent.right
        spacing: Tokens.spacing.largeIncreased

        Repeater {
            model: root.fields

            ColumnLayout {
                id: fieldItem

                required property var modelData
                readonly property bool isNumber: modelData.type === "int" || modelData.type === "real"
                readonly property bool isSelect: modelData.type === "select"

                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                StyledText {
                    Layout.fillWidth: true
                    visible: fieldItem.modelData.type !== "bool"
                    text: fieldItem.modelData.label
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.label.medium
                    elide: Text.ElideRight
                }

                // Text, command (space separated argv) and icon name fields
                Loader {
                    Layout.fillWidth: true
                    active: !fieldItem.isNumber && !fieldItem.isSelect && fieldItem.modelData.type !== "bool"
                    visible: active

                    sourceComponent: StyledTextField {
                        type: StyledTextField.Filled
                        verticalPadding: Tokens.padding.medium
                        text: {
                            const v = root.valueOf(fieldItem.modelData);
                            return fieldItem.modelData.type === "command" ? root.customText(v) : (v ?? "");
                        }
                        placeholderText: fieldItem.modelData.placeholder ?? ""
                        supportingText: fieldItem.modelData.hint ?? ""

                        onTextEdited: {
                            if (fieldItem.modelData.type === "command")
                                root.setValue(fieldItem.modelData, text.trim() ? text.trim().split(/\s+/) : []);
                            else
                                root.setValue(fieldItem.modelData, text);
                        }
                    }
                }

                Loader {
                    active: fieldItem.isNumber
                    visible: active

                    sourceComponent: StyledSpinBox {
                        from: fieldItem.modelData.from ?? 0
                        to: fieldItem.modelData.to ?? 9999
                        stepSize: fieldItem.modelData.stepSize ?? 1
                        value: root.valueOf(fieldItem.modelData) ?? from
                        cLayer: 2
                        onValueModified: root.setValue(fieldItem.modelData, value)
                    }
                }

                Loader {
                    Layout.fillWidth: true
                    active: fieldItem.modelData.type === "bool"
                    visible: active

                    sourceComponent: StyledSwitch {
                        text: fieldItem.modelData.label
                        font: Tokens.font.body.small
                        checked: root.valueOf(fieldItem.modelData) ?? false
                        onToggled: root.setValue(fieldItem.modelData, checked)
                    }
                }

                Loader {
                    Layout.fillWidth: true
                    active: fieldItem.isSelect
                    visible: active

                    sourceComponent: ColumnLayout {
                        id: selectColumn

                        readonly property list<var> options: fieldItem.modelData.options ?? []
                        property int currentIndex: root.optionIndex(fieldItem.modelData, root.valueOf(fieldItem.modelData))
                        readonly property var currentOption: options[currentIndex] ?? null

                        function apply(): void {
                            const option = currentOption;
                            if (!option)
                                return;
                            if (!option.custom)
                                root.setValue(fieldItem.modelData, option.value);
                            else if (option.custom === "command")
                                root.setValue(fieldItem.modelData, customField.text.trim() ? customField.text.trim().split(/\s+/) : []);
                            else
                                root.setValue(fieldItem.modelData, customField.text);
                        }

                        spacing: Tokens.spacing.small

                        Variants {
                            id: optionVariants

                            model: selectColumn.options

                            MenuItem {
                                required property var modelData

                                text: modelData.label
                                icon: modelData.icon ?? ""
                            }
                        }

                        SplitButton {
                            Layout.alignment: Qt.AlignLeft
                            type: SplitButton.Tonal
                            menuItems: optionVariants.instances
                            active: menuItems[selectColumn.currentIndex] ?? null
                            fallbackText: selectColumn.currentOption?.label ?? ""
                            stateLayer.onClicked: expanded = !expanded
                            menu.onItemSelected: item => {
                                selectColumn.currentIndex = optionVariants.instances.indexOf(item);
                                selectColumn.apply();
                            }
                        }

                        StyledTextField {
                            id: customField

                            Layout.fillWidth: true
                            visible: !!selectColumn.currentOption?.custom
                            type: StyledTextField.Filled
                            verticalPadding: Tokens.padding.medium
                            text: root.customText(root.valueOf(fieldItem.modelData))
                            placeholderText: selectColumn.currentOption?.placeholder ?? ""
                            onTextEdited: selectColumn.apply()
                        }
                    }
                }
            }
        }
    }
}
