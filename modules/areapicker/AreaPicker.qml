pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.components.containers
import qs.components.misc
import qs.services

// Region tool ported from illogical-impulse's region selector: screenshot,
// annotate, Google Lens, OCR and region recording from one picker.
Scope {
    id: scope

    // Circle-to-search when opened via the Lens shortcut (ii's useCircleSelection)
    readonly property bool searchUsesCircle: false

    function launch(action: string, freeze: bool): void {
        // Like ii, triggering record again while a recording runs stops it
        if ((action === "record" || action === "recordSound") && Recorder.running) {
            Recorder.stop();
            return;
        }

        // Picker is parked on a running recording; don't hijack it
        if (root.active && root.recording)
            return;

        root.action = action;
        root.circle = action === "search" && searchUsesCircle;
        root.freeze = freeze;
        root.closing = false;
        root.recording = false;
        root.activeAsync = true;
    }

    LazyLoader {
        id: root

        // copy | edit | search | ocr | record | recordSound
        property string action: "copy"
        property bool circle
        property bool freeze
        property bool closing
        // Set once a region recording starts; the picker stays as a click-through
        // border on that screen until the recording stops
        property bool recording
        property string recordScreen

        readonly property bool isRecord: action === "record" || action === "recordSound"

        Variants {
            model: Screens.screens

            StyledWindow {
                id: win

                required property ShellScreen modelData

                screen: modelData
                name: "area-picker"
                WlrLayershell.exclusionMode: ExclusionMode.Ignore
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.keyboardFocus: root.closing ? WlrKeyboardFocus.None : WlrKeyboardFocus.Exclusive
                mask: root.closing ? empty : null

                anchors.top: true
                anchors.bottom: true
                anchors.left: true
                anchors.right: true

                Region {
                    id: empty
                }

                Picker {
                    loader: root
                    screen: win.modelData
                }
            }
        }
    }

    IpcHandler {
        function open(): void {
            scope.launch("edit", false);
        }

        function openFreeze(): void {
            scope.launch("edit", true);
        }

        function openClip(): void {
            scope.launch("copy", false);
        }

        function openFreezeClip(): void {
            scope.launch("copy", true);
        }

        function screenshot(): void {
            scope.launch("copy", true);
        }

        function search(): void {
            scope.launch("search", true);
        }

        function ocr(): void {
            scope.launch("ocr", true);
        }

        function record(): void {
            scope.launch("record", false);
        }

        function recordWithSound(): void {
            scope.launch("recordSound", false);
        }

        target: "picker"
    }

    // Original Caelestia shortcuts, kept so existing binds keep working.
    // Right click still annotates in every mode, like ii.

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "screenshot"
        description: "Open screenshot tool"
        onPressed: scope.launch("edit", false)
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "screenshotFreeze"
        description: "Open screenshot tool (freeze mode)"
        onPressed: scope.launch("edit", true)
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "screenshotClip"
        description: "Open screenshot tool (clipboard)"
        onPressed: scope.launch("copy", false)
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "screenshotFreezeClip"
        description: "Open screenshot tool (freeze mode, clipboard)"
        onPressed: scope.launch("copy", true)
    }

    // ii-style region shortcuts

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "regionScreenshot"
        description: "Copy the selected region (right click to annotate)"
        onPressed: scope.launch("copy", true)
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "regionSearch"
        description: "Search the selected region with Google Lens"
        onPressed: scope.launch("search", true)
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "regionOcr"
        description: "Recognise text in the selected region"
        onPressed: scope.launch("ocr", true)
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "regionRecord"
        description: "Record the selected region"
        onPressed: scope.launch("record", false)
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "regionRecordWithSound"
        description: "Record the selected region with sound"
        onPressed: scope.launch("recordSound", false)
    }
}
