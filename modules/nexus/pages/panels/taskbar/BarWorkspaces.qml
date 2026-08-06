pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components.controls
import qs.modules.nexus.common

PageBase {
    id: root

    // How workspace labels are cased, mapped to GlobalConfig.bar.workspaces.capitalisation
    readonly property list<MenuItem> capitalisationItems: [
        MenuItem {
            text: Tr.tr("Preserve")
        },
        MenuItem {
            text: Tr.tr("UPPER")
        },
        MenuItem {
            text: Tr.tr("lower")
        }
    ]
    readonly property list<string> capitalisationValues: ["preserve", "upper", "lower"]

    // Icon rules match either an exact workspace name or a regex, and both list types share the shape
    readonly property list<var> iconFields: [
        {
            key: "name",
            label: Tr.tr("Name"),
            type: "text",
            hint: Tr.tr("Exact match, ignored when a pattern is set"),
            defaultValue: ""
        },
        {
            key: "regex",
            label: Tr.tr("Pattern"),
            type: "text",
            hint: Tr.tr("Regular expression, takes priority over the name"),
            defaultValue: ""
        },
        {
            key: "flags",
            label: Tr.tr("Pattern flags"),
            type: "text",
            placeholder: "i",
            defaultValue: ""
        },
        {
            key: "icon",
            label: Tr.tr("Icon"),
            type: "text",
            hint: Tr.tr("Material symbol name"),
            defaultValue: ""
        }
    ]

    function ruleLabel(item: var): string {
        return item.regex || item.name || Tr.tr("Unnamed rule");
    }

    title: Tr.tr("Workspaces")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // Display
        SectionHeader {
            first: true
            text: Tr.tr("Display")
        }

        StepperRow {
            first: true
            // TRANSLATORS: the number of workspaces shown on the bar
            label: Tr.trCtx("Shown", "bar workspaces")
            subtext: Tr.tr("Number of workspaces displayed")
            value: Config.bar.workspaces.shown
            from: 1
            to: 20
            stepSize: 1
            onMoved: v => GlobalConfig.bar.workspaces.shown = v
        }

        ToggleRow {
            text: Tr.trCtx("Active indicator", "bar workspaces")
            checked: Config.bar.workspaces.activeIndicator
            onToggled: GlobalConfig.bar.workspaces.activeIndicator = checked
        }

        ToggleRow {
            text: Tr.trCtx("Active trail", "bar workspaces")
            checked: Config.bar.workspaces.activeTrail
            onToggled: GlobalConfig.bar.workspaces.activeTrail = checked
        }

        ToggleRow {
            text: Tr.trCtx("Occupied background", "bar workspaces")
            checked: Config.bar.workspaces.occupiedBg
            onToggled: GlobalConfig.bar.workspaces.occupiedBg = checked
        }

        ToggleRow {
            text: Tr.trCtx("Show unoccupied", "bar workspaces")
            subtext: Tr.tr("Show workspaces that are inactive and empty")
            checked: Config.bar.workspaces.showUnoccupied
            onToggled: GlobalConfig.bar.workspaces.showUnoccupied = checked
        }

        ToggleRow {
            text: Tr.trCtx("Per monitor", "bar workspaces")
            subtext: Tr.tr("Hide workspaces not on the current monitor")
            checked: Config.bar.workspaces.perMonitor
            onToggled: GlobalConfig.bar.workspaces.perMonitor = checked
        }

        ToggleRow {
            text: Tr.trCtx("Show windows", "bar workspaces")
            subtext: Tr.tr("Show icons of open windows on each workspace")
            checked: Config.bar.workspaces.showWindows
            onToggled: GlobalConfig.bar.workspaces.showWindows = checked
        }

        ToggleRow {
            text: Tr.trCtx("Windows on special workspaces", "bar workspaces")
            checked: Config.bar.workspaces.showWindowsOnSpecialWorkspaces
            onToggled: GlobalConfig.bar.workspaces.showWindowsOnSpecialWorkspaces = checked
        }

        StepperRow {
            last: true
            // TRANSLATORS: maximum number of window icons shown per workspace
            label: Tr.trCtx("Max window icons", "bar workspaces")
            value: Config.bar.workspaces.maxWindowIcons
            from: 0
            to: 20
            stepSize: 1
            onMoved: v => GlobalConfig.bar.workspaces.maxWindowIcons = v
        }

        // Labels
        SectionHeader {
            text: Tr.tr("Labels")
        }

        TextFieldRow {
            first: true
            label: Tr.tr("Default label")
            subtext: Tr.tr("Shown on every workspace, empty uses the workspace name")
            value: Config.bar.workspaces.label
            onEditingFinished: value => GlobalConfig.bar.workspaces.label = value
        }

        TextFieldRow {
            label: Tr.tr("Occupied label")
            subtext: Tr.tr("Overrides the default label on workspaces with windows")
            value: Config.bar.workspaces.occupiedLabel
            onEditingFinished: value => GlobalConfig.bar.workspaces.occupiedLabel = value
        }

        TextFieldRow {
            label: Tr.tr("Active label")
            subtext: Tr.tr("Overrides the label on the focused workspace")
            value: Config.bar.workspaces.activeLabel
            onEditingFinished: value => GlobalConfig.bar.workspaces.activeLabel = value
        }

        SelectRow {
            last: true
            label: Tr.tr("Capitalisation")
            subtext: Tr.tr("How workspace labels are cased")
            menuItems: root.capitalisationItems
            active: root.capitalisationItems[Math.max(0, root.capitalisationValues.indexOf(Config.bar.workspaces.capitalisation))]
            onSelected: item => GlobalConfig.bar.workspaces.capitalisation = root.capitalisationValues[root.capitalisationItems.indexOf(item)]
        }

        // Window icons
        SectionHeader {
            text: Tr.tr("Window icons")
        }

        ObjectListEditor {
            function labelFor(item: var): string {
                return root.ruleLabel(item);
            }

            function subtextFor(item: var): string {
                return item.icon ?? "";
            }

            rootParent: root.flickable
            values: GlobalConfig.bar.workspaces.windowIcons
            fields: root.iconFields
            rowIcon: "web_asset"
            addLabel: Tr.tr("Add window icon")
            addHeader: Tr.tr("Add window icon")
            editHeader: Tr.tr("Edit window icon")
            emptyLabel: Tr.tr("Icons are chosen from each app's desktop entry")
            onEdited: values => GlobalConfig.bar.workspaces.windowIcons = values
        }

        // Special workspace icons
        SectionHeader {
            text: Tr.tr("Special workspace icons")
        }

        ObjectListEditor {
            function labelFor(item: var): string {
                return root.ruleLabel(item);
            }

            function subtextFor(item: var): string {
                return item.icon ?? "";
            }

            rootParent: root.flickable
            values: GlobalConfig.bar.workspaces.specialWorkspaceIcons
            fields: root.iconFields
            rowIcon: "star"
            addLabel: Tr.tr("Add special workspace icon")
            addHeader: Tr.tr("Add special workspace icon")
            editHeader: Tr.tr("Edit special workspace icon")
            emptyLabel: Tr.tr("Built-in icons are used for known special workspaces")
            onEdited: values => GlobalConfig.bar.workspaces.specialWorkspaceIcons = values
        }
    }
}
