pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.modules.nexus.common

PageBase {
    id: root

    // Actions understood by IdleMonitors.handleIdleAction: bare strings are Hyprland
    // dispatches (with "lock"/"unlock" special cased), lists go to the session manager.
    readonly property list<var> actionOptions: [
        {
            label: qsTr("Nothing"),
            value: ""
        },
        {
            label: qsTr("Lock"),
            value: "lock"
        },
        {
            label: qsTr("Unlock"),
            value: "unlock"
        },
        {
            label: qsTr("Screen off"),
            value: "dpms off"
        },
        {
            label: qsTr("Screen on"),
            value: "dpms on"
        },
        {
            label: qsTr("Suspend"),
            value: ["suspend"]
        },
        {
            label: qsTr("Suspend then hibernate"),
            value: ["suspendThenHibernate"]
        },
        {
            label: qsTr("Hibernate"),
            value: ["hibernate"]
        },
        {
            label: qsTr("Log out"),
            value: ["logout"]
        },
        {
            label: qsTr("Power off"),
            value: ["poweroff"]
        },
        {
            label: qsTr("Reboot"),
            value: ["reboot"]
        },
        {
            label: qsTr("Custom command"),
            custom: "command",
            placeholder: "notify-send Idle"
        },
        {
            label: qsTr("Hyprland dispatch"),
            custom: "text",
            placeholder: "dpms off"
        }
    ]

    readonly property list<var> timeoutFields: [
        {
            key: "timeout",
            label: qsTr("Timeout (seconds)"),
            type: "int",
            from: 5,
            to: 86400,
            stepSize: 30,
            defaultValue: 300
        },
        {
            key: "idleAction",
            label: qsTr("On idle"),
            type: "select",
            options: root.actionOptions,
            defaultValue: "lock"
        },
        {
            key: "returnAction",
            label: qsTr("On return"),
            type: "select",
            options: root.actionOptions,
            defaultValue: ""
        },
        {
            key: "enabled",
            label: qsTr("Enabled"),
            type: "bool",
            defaultValue: true
        },
        {
            key: "respectInhibitors",
            label: qsTr("Respect idle inhibitors"),
            type: "bool",
            defaultValue: true
        },
        {
            key: "inhibitWhenAudio",
            label: qsTr("Skip while media is playing"),
            type: "bool",
            defaultValue: false
        },
        {
            key: "inhibitWhenCharging",
            label: qsTr("Skip while charging"),
            type: "bool",
            defaultValue: false
        }
    ]

    readonly property list<var> warnLevelFields: [
        {
            key: "level",
            label: qsTr("Battery percentage"),
            type: "int",
            from: 1,
            to: 100,
            stepSize: 1,
            defaultValue: 20
        },
        {
            key: "title",
            label: qsTr("Title"),
            type: "text",
            defaultValue: ""
        },
        {
            key: "message",
            label: qsTr("Message"),
            type: "text",
            hint: qsTr("Basic HTML is supported"),
            defaultValue: ""
        },
        {
            key: "icon",
            label: qsTr("Icon"),
            type: "text",
            hint: qsTr("Material symbol name"),
            defaultValue: "battery_android_frame_2"
        },
        {
            key: "critical",
            label: qsTr("Critical"),
            type: "bool",
            defaultValue: false
        }
    ]

    function formatTimeout(seconds: int): string {
        if (seconds >= 3600)
            return qsTr("%1 h").arg(Math.round(seconds / 360) / 10);
        if (seconds >= 60)
            return qsTr("%1 min").arg(Math.round(seconds / 6) / 10);
        return qsTr("%1 s").arg(seconds);
    }

    function describeAction(action: var): string {
        if (!action)
            return qsTr("nothing");
        const json = JSON.stringify(action);
        const match = root.actionOptions.find(o => !o.custom && JSON.stringify(o.value) === json);
        if (match)
            return match.label.toLowerCase();
        return Array.isArray(action) ? action.join(" ") : action;
    }

    title: qsTr("Power & idle")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // Idle behaviour
        SectionHeader {
            first: true
            text: qsTr("Idle behaviour")
        }

        ToggleRow {
            first: true
            text: qsTr("Lock before sleep")
            subtext: qsTr("Lock the session when the system suspends")
            checked: GlobalConfig.general.idle.lockBeforeSleep
            onToggled: GlobalConfig.general.idle.lockBeforeSleep = checked
        }

        ToggleRow {
            text: qsTr("Stay awake while media is playing")
            checked: GlobalConfig.general.idle.inhibitWhenAudio
            onToggled: GlobalConfig.general.idle.inhibitWhenAudio = checked
        }

        ToggleRow {
            last: true
            text: qsTr("Stay awake while charging")
            checked: GlobalConfig.general.idle.inhibitWhenCharging
            onToggled: GlobalConfig.general.idle.inhibitWhenCharging = checked
        }

        // Idle timeouts
        SectionHeader {
            text: qsTr("Idle timeouts")
        }

        ObjectListEditor {
            function labelFor(item: var): string {
                return qsTr("After %1").arg(root.formatTimeout(item.timeout ?? 0));
            }

            function subtextFor(item: var): string {
                const idle = root.describeAction(item.idleAction);
                if (!item.returnAction)
                    return idle;
                return qsTr("%1, then %2 on return").arg(idle).arg(root.describeAction(item.returnAction));
            }

            rootParent: root.flickable
            values: GlobalConfig.general.idle.timeouts
            fields: root.timeoutFields
            rowIcon: "timer"
            addLabel: qsTr("Add timeout")
            addHeader: qsTr("Add idle timeout")
            editHeader: qsTr("Edit idle timeout")
            emptyLabel: qsTr("The session never idles")
            onEdited: values => GlobalConfig.general.idle.timeouts = values
        }

        // Battery
        SectionHeader {
            text: qsTr("Battery")
        }

        StepperRow {
            first: true
            last: true
            label: qsTr("Critical level")
            subtext: qsTr("Battery percentage that triggers hibernation")
            value: GlobalConfig.general.battery.criticalLevel
            from: 0
            to: 50
            stepSize: 1
            onMoved: v => GlobalConfig.general.battery.criticalLevel = Math.round(v)
        }

        // Battery warnings
        SectionHeader {
            text: qsTr("Battery warnings")
        }

        ObjectListEditor {
            function labelFor(item: var): string {
                return item.title || qsTr("Warning at %1%").arg(item.level ?? 0);
            }

            function subtextFor(item: var): string {
                return qsTr("At %1%").arg(item.level ?? 0);
            }

            rootParent: root.flickable
            values: GlobalConfig.general.battery.warnLevels
            fields: root.warnLevelFields
            rowIcon: "battery_alert"
            addLabel: qsTr("Add warning")
            addHeader: qsTr("Add battery warning")
            editHeader: qsTr("Edit battery warning")
            emptyLabel: qsTr("No low battery warnings")
            onEdited: values => GlobalConfig.general.battery.warnLevels = values
        }
    }
}
