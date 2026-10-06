pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Caelestia
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.effects
import qs.services

MouseArea {
    id: root

    required property LazyLoader loader
    required property ShellScreen screen

    readonly property string action: loader.action // qmllint disable missing-property
    readonly property bool isRecord: action === "record" || action === "recordSound"
    readonly property bool circle: loader.circle // qmllint disable missing-property
    // This screen is showing the border of a running recording
    readonly property bool recordingHere: loader.recording && loader.recordScreen === screen.name // qmllint disable missing-property

    // Lens upload host and engine, same as ii
    readonly property string uploadEndpoint: "https://uguu.se/upload"
    readonly property string searchBaseUrl: "https://lens.google.com/uploadbyurl?url="
    readonly property real circlePadding: 10

    property bool onClient
    property var hoveredClient: null
    property int button: Qt.LeftButton
    property var points: []

    property real realBorderWidth: onClient ? (Hypr.options["general:border_size"] ?? 1) : 2
    property real realRounding: onClient ? (Hypr.options["decoration:rounding"] ?? 0) : 0

    property real ssx
    property real ssy

    property real sx: 0
    property real sy: 0
    property real ex: screen.width
    property real ey: screen.height

    property real rsx: Math.min(sx, ex)
    property real rsy: Math.min(sy, ey)
    property real sw: Math.abs(sx - ex)
    property real sh: Math.abs(sy - ey)

    property list<var> clients: {
        const mon = Hypr.monitorFor(screen);
        if (!mon)
            return [];

        const special = mon.lastIpcObject?.specialWorkspace;
        const wsId = special?.name ? special.id : mon.activeWorkspace?.id;
        if (wsId === undefined)
            return [];

        return Hypr.toplevelsForWs(wsId).sort((a, b) => {
            // Pinned first, then fullscreen, then floating, then any other
            const ac = a?.lastIpcObject;
            const bc = b?.lastIpcObject;
            if (!ac || !bc)
                return !ac - !bc; // Missing IPC last
            return (bc.pinned - ac.pinned) || ((bc.fullscreen !== 0) - (ac.fullscreen !== 0)) || (bc.floating - ac.floating);
        });
    }

    function checkClientRects(x: real, y: real): void {
        for (const client of clients) {
            if (!client)
                continue;

            const ipc = client.lastIpcObject;
            if (!ipc?.at || !ipc?.size)
                continue;

            let {
                at: [cx, cy],
                size: [cw, ch]
            } = ipc;
            cx -= screen.x;
            cy -= screen.y;
            if (cx <= x && cy <= y && cx + cw >= x && cy + ch >= y) {
                onClient = true;
                hoveredClient = ipc;
                sx = cx;
                sy = cy;
                ex = cx + cw;
                ey = cy + ch;
                break;
            }
        }
    }

    function clampedRect(): rect {
        const x = Math.max(0, Math.ceil(rsx));
        const y = Math.max(0, Math.ceil(rsy));
        const w = Math.min(screen.width, Math.floor(rsx + sw)) - x;
        const h = Math.min(screen.height, Math.floor(rsy + sh)) - y;
        return Qt.rect(x, y, w, h);
    }

    function finish(): void {
        if (isRecord)
            startRecording();
        else if (loader.freeze) // qmllint disable missing-property
            save();
        else {
            // Hide everything we draw so the live capture doesn't include it
            ui.visible = false;
            screencopy.visible = false;
            screencopy.active = true;
        }
    }

    function save(): void {
        const r = clampedRect();
        if (r.width <= 0 || r.height <= 0) {
            closeAnim.start();
            return;
        }

        // Right click annotates regardless of mode, like ii
        const act = button === Qt.RightButton ? "edit" : action;
        const tmpfile = Qt.resolvedUrl(`/tmp/caelestia-picker-${Quickshell.processId}-${Date.now()}.png`);
        CUtils.saveItem(screencopy, tmpfile, r, path => {
            run(act, path);
            closeAnim.start();
        });
    }

    function run(act: string, path: string): void {
        // path is generated above, so it never needs quoting beyond this
        const p = `'${path}'`;
        const notify = `notify-send -a caelestia-cli`;

        if (act === "copy") {
            Quickshell.execDetached(["sh", "-c", `wl-copy --type image/png < ${p}`]);
            Quickshell.execDetached(["notify-send", "-a", "caelestia-cli", "-i", path, Tr.tr("Screenshot taken"), Tr.tr("Screenshot copied to clipboard")]);
        } else if (act === "edit") {
            Quickshell.execDetached(["swappy", "-f", path]);
        } else if (act === "search") {
            Quickshell.execDetached(["sh", "-c", `url=$(curl -sfF files[]=@${p} ${uploadEndpoint} | jq -r '.files[0].url // empty'); rm -f ${p}; ` + `if [ -n "$url" ]; then xdg-open "${searchBaseUrl}$url"; ` + `else ${notify} -i image-missing '${Tr.tr("Image search failed")}' '${Tr.tr("Could not upload the image")}'; fi`]);
        } else if (act === "ocr") {
            Quickshell.execDetached(["sh", "-c", `langs=$(tesseract --list-langs 2>/dev/null | awk 'NR>1 && $1 != "osd" {print $1}' | paste -sd+); ` + `text=$(tesseract ${p} stdout -l "\${langs:-eng}" 2>/dev/null); rm -f ${p}; ` + `if [ -n "$(printf %s "$text" | tr -d '[:space:]')" ]; then printf %s "$text" | wl-copy; ${notify} '${Tr.tr("Text copied")}' "$text"; ` + `else ${notify} '${Tr.tr("No text found")}' '${Tr.tr("Nothing was recognised in the selection")}'; fi`]);
        }
    }

    function startRecording(): void {
        const r = clampedRect();
        if (r.width <= 0 || r.height <= 0) {
            closeAnim.start();
            return;
        }

        // gpu-screen-recorder wants global logical coords, same as slurp
        const region = `${r.width}x${r.height}+${r.x + screen.x}+${r.y + screen.y}`;
        Recorder.start(["-r", region, ...(action === "recordSound" ? ["-s"] : [])]);

        // A frozen frame would end up in the recording
        screencopy.active = false;

        // Snap the selection to what is actually recorded
        sx = r.x;
        sy = r.y;
        ex = r.x + r.width;
        ey = r.y + r.height;

        loader.recordScreen = screen.name; // qmllint disable missing-property
        loader.recording = true; // qmllint disable missing-property
        loader.closing = true; // qmllint disable missing-property
    }

    onClientsChanged: checkClientRects(mouseX, mouseY)

    anchors.fill: parent
    opacity: 0
    hoverEnabled: true
    cursorShape: Qt.CrossCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton

    Component.onCompleted: {
        Hypr.extras.refreshOptions();

        // Break binding if frozen
        if (loader.freeze) // qmllint disable missing-property
            clients = clients;

        opacity = 1;

        const ipc = clients[0]?.lastIpcObject;
        if (ipc?.at && ipc?.size) {
            const cx = ipc.at[0] - screen.x;
            const cy = ipc.at[1] - screen.y;
            onClient = true;
            hoveredClient = ipc;
            sx = cx;
            sy = cy;
            ex = cx + ipc.size[0];
            ey = cy + ipc.size[1];
        } else {
            sx = screen.width / 2 - 100;
            sy = screen.height / 2 - 100;
            ex = screen.width / 2 + 100;
            ey = screen.height / 2 + 100;
        }
    }

    onPressed: event => {
        ssx = event.x;
        ssy = event.y;
        button = event.button;
        points = [Qt.point(event.x, event.y)];
    }

    onReleased: {
        if (closeAnim.running || loader.closing) // qmllint disable missing-property
            return;

        finish();
    }

    onPositionChanged: event => {
        const x = event.x;
        const y = event.y;

        if (pressed) {
            onClient = false;
            hoveredClient = null;

            if (circle) {
                const last = points[points.length - 1];
                if (!last || Math.abs(last.x - x) + Math.abs(last.y - y) > 2)
                    points = [...points, Qt.point(x, y)];

                // Selection follows the lasso's bounding box
                const xs = points.map(p => p.x);
                const ys = points.map(p => p.y);
                sx = Math.min(...xs) - circlePadding;
                sy = Math.min(...ys) - circlePadding;
                ex = Math.max(...xs) + circlePadding;
                ey = Math.max(...ys) + circlePadding;
            } else {
                sx = ssx;
                sy = ssy;
                ex = x;
                ey = y;
            }
        } else {
            checkClientRects(x, y);
        }
    }

    focus: true
    Keys.onEscapePressed: closeAnim.start()

    // Recording lifecycle: hold the border until the recorder stops
    property bool seenRunning
    property bool holdingRef

    onRecordingHereChanged: {
        if (recordingHere && !holdingRef) {
            // Make the service poll so external stops are noticed
            Recorder.refCount++;
            holdingRef = true;
            seenRunning = Recorder.running;
            startTimeout.start();
        }
    }

    Component.onDestruction: {
        if (holdingRef)
            Recorder.refCount--;
    }

    Connections {
        function onRunningChanged(): void {
            if (Recorder.running)
                root.seenRunning = true;
            else if (root.seenRunning)
                closeAnim.start();
        }

        target: Recorder
        enabled: root.recordingHere
    }

    Timer {
        id: startTimeout

        // Recorder never came up (failed to start), don't leave the border stuck
        interval: 5000
        onTriggered: {
            if (!Recorder.running)
                closeAnim.start();
        }
    }

    SequentialAnimation {
        id: closeAnim

        PropertyAction {
            target: root.loader
            property: "closing"
            value: true
        }
        ParallelAnimation {
            Anim {
                target: root
                property: "opacity"
                to: 0
                type: Anim.StandardLarge
            }
            Anim {
                target: root
                properties: "rsx,rsy"
                to: 0
            }
            Anim {
                target: root
                property: "sw"
                to: root.screen.width
            }
            Anim {
                target: root
                property: "sh"
                to: root.screen.height
            }
        }
        PropertyAction {
            target: root.loader
            property: "activeAsync"
            value: false
        }
    }

    Process {
        running: true
        command: ["hyprctl", "cursorpos", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                const pos = JSON.parse(text);
                root.checkClientRects(pos.x - root.screen.x, pos.y - root.screen.y);
            }
        }
    }

    Loader {
        id: screencopy

        asynchronous: true
        anchors.fill: parent

        active: root.loader.freeze // qmllint disable missing-property

        sourceComponent: ScreencopyView {
            captureSource: root.screen

            onHasContentChanged: {
                if (hasContent && !root.loader.freeze) { // qmllint disable missing-property
                    ui.visible = true;
                    root.save();
                }
            }
        }
    }

    Item {
        id: ui

        anchors.fill: parent

        // Other screens fade out once a recording starts elsewhere
        opacity: root.loader.recording && !root.recordingHere ? 0 : 1 // qmllint disable missing-property

        Behavior on opacity {
            Anim {
                type: Anim.StandardLarge
            }
        }

        StyledRect {
            id: overlay

            anchors.fill: parent
            color: Colours.palette.m3secondaryContainer
            opacity: root.recordingHere ? 0 : 0.3

            layer.enabled: true
            layer.effect: Mask {
                maskSource: selectionWrapper
                maskInverted: true
            }

            Behavior on opacity {
                Anim {
                    type: Anim.StandardLarge
                }
            }
        }

        Item {
            id: selectionWrapper

            anchors.fill: parent
            layer.enabled: true
            visible: false

            Rectangle {
                id: selectionRect

                radius: root.realRounding
                x: root.rsx
                y: root.rsy
                implicitWidth: root.sw
                implicitHeight: root.sh
            }
        }

        // Faint outlines of every window, like ii's target regions
        Repeater {
            model: root.clients

            StyledRect {
                id: outline

                required property var modelData
                readonly property var ipc: modelData?.lastIpcObject

                visible: !!ipc?.at && !!ipc?.size
                x: (ipc?.at?.[0] ?? 0) - root.screen.x
                y: (ipc?.at?.[1] ?? 0) - root.screen.y
                implicitWidth: ipc?.size?.[0] ?? 0
                implicitHeight: ipc?.size?.[1] ?? 0
                radius: Hypr.options["decoration:rounding"] ?? 0
                border.width: 1
                border.color: Colours.palette.m3outline
                opacity: root.pressed || root.loader.closing ? 0 : 0.5 // qmllint disable missing-property

                Behavior on opacity {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }
            }
        }

        // Aim lines
        StyledRect {
            visible: !root.loader.closing // qmllint disable missing-property
            x: Math.round(root.mouseX)
            implicitWidth: 1
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            color: Colours.palette.m3primary
            opacity: 0.25
        }

        StyledRect {
            visible: !root.loader.closing // qmllint disable missing-property
            y: Math.round(root.mouseY)
            implicitHeight: 1
            anchors.left: parent.left
            anchors.right: parent.right
            color: Colours.palette.m3primary
            opacity: 0.25
        }

        Rectangle {
            id: border

            color: "transparent"
            radius: root.realRounding > 0 ? root.realRounding + root.realBorderWidth : 0
            border.width: root.realBorderWidth
            border.color: root.recordingHere ? Colours.palette.m3error : Colours.palette.m3primary

            x: selectionRect.x - root.realBorderWidth
            y: selectionRect.y - root.realBorderWidth
            implicitWidth: selectionRect.implicitWidth + root.realBorderWidth * 2
            implicitHeight: selectionRect.implicitHeight + root.realBorderWidth * 2

            Behavior on border.color {
                CAnim {}
            }

            // Breathing border while recording, as in ii
            SequentialAnimation on opacity {
                running: root.recordingHere
                loops: Animation.Infinite
                alwaysRunToEnd: true

                Anim {
                    to: 0.3
                    type: Anim.StandardExtraLarge
                }
                Anim {
                    to: 1
                    type: Anim.StandardExtraLarge
                }
            }
        }

        // Lasso stroke for circle selection
        Shape {
            anchors.fill: parent
            visible: root.circle && root.pressed
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                strokeWidth: 4
                strokeColor: Colours.palette.m3primary
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                joinStyle: ShapePath.RoundJoin
                pathHints: ShapePath.PathLinear

                PathPolyline {
                    path: root.points
                }
            }
        }

        // Hovered window's class
        StyledRect {
            id: clientLabel

            readonly property string appClass: root.hoveredClient?.class ?? ""

            x: root.rsx + Tokens.padding.medium
            y: root.rsy + Tokens.padding.medium
            implicitWidth: clientText.implicitWidth + Tokens.padding.medium * 2
            implicitHeight: clientText.implicitHeight + Tokens.padding.small * 2
            radius: Tokens.rounding.full
            color: Colours.palette.m3surfaceContainer
            opacity: root.onClient && appClass && !root.loader.closing ? 1 : 0 // qmllint disable missing-property
            scale: opacity * 0.2 + 0.8

            StyledText {
                id: clientText

                anchors.centerIn: parent
                text: clientLabel.appClass
                color: Colours.palette.m3onSurface
                font: Tokens.font.label.medium
                animate: true
            }

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }

        // Selection size
        StyledRect {
            id: sizeLabel

            readonly property bool below: root.rsy + root.sh + implicitHeight + Tokens.spacing.small * 2 < root.height

            x: Math.max(0, Math.min(root.width - implicitWidth, root.rsx + root.sw - implicitWidth))
            y: below ? root.rsy + root.sh + Tokens.spacing.small : root.rsy + root.sh - implicitHeight - Tokens.spacing.small
            implicitWidth: sizeText.implicitWidth + Tokens.padding.medium * 2
            implicitHeight: sizeText.implicitHeight + Tokens.padding.small * 2
            radius: Tokens.rounding.full
            color: Colours.palette.m3primaryContainer
            opacity: root.loader.closing ? 0 : 1 // qmllint disable missing-property

            StyledText {
                id: sizeText

                anchors.centerIn: parent
                text: `${Math.round(root.sw)} × ${Math.round(root.sh)}`
                color: Colours.palette.m3onPrimaryContainer
                font: Tokens.font.mono.small
            }

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }

        CursorGuide {
            x: Math.min(root.mouseX + Tokens.spacing.medium, root.width - implicitWidth)
            y: Math.min(root.mouseY + Tokens.spacing.medium, root.height - implicitHeight)
            action: root.action
            circle: root.circle
            opacity: root.containsMouse && !toolbar.hovered && !root.loader.closing ? 1 : 0 // qmllint disable missing-property

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }

        Toolbar {
            id: toolbar

            loader: root.loader

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: shown ? Tokens.spacing.extraLarge : -implicitHeight - Tokens.spacing.large

            // Get out of the way while selecting
            shown: root.opacity > 0 && !root.pressed && !root.loader.closing // qmllint disable missing-property
            onCloseRequested: closeAnim.start()
        }
    }

    Behavior on opacity {
        Anim {
            type: Anim.StandardLarge
        }
    }

    Behavior on rsx {
        enabled: !root.pressed

        Anim {}
    }

    Behavior on rsy {
        enabled: !root.pressed

        Anim {}
    }

    Behavior on sw {
        enabled: !root.pressed

        Anim {}
    }

    Behavior on sh {
        enabled: !root.pressed

        Anim {}
    }
}
