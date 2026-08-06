pragma ComponentBehavior: Bound

import QtQuick.Layouts
import Caelestia.Config
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Files & assets")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // Folders
        SectionHeader {
            first: true
            text: qsTr("Folders")
        }

        TextFieldRow {
            first: true
            label: qsTr("Wallpapers")
            subtext: qsTr("Folder scanned for wallpapers")
            value: GlobalConfig.paths.wallpaperDir
            placeholderText: "~/Pictures/Wallpapers"
            onEditingFinished: value => GlobalConfig.paths.wallpaperDir = value
        }

        TextFieldRow {
            last: true
            label: qsTr("Lyrics")
            subtext: qsTr("Folder searched for local .lrc files")
            value: GlobalConfig.paths.lyricsDir
            placeholderText: "~/Music/Lyrics/"
            onEditingFinished: value => GlobalConfig.paths.lyricsDir = value
        }

        // Images
        SectionHeader {
            text: qsTr("Images")
        }

        TextFieldRow {
            first: true
            label: qsTr("Distro logo")
            subtext: qsTr("Icon name or path, empty follows the OS")
            value: GlobalConfig.general.logo
            placeholderText: qsTr("caelestia")
            onEditingFinished: value => GlobalConfig.general.logo = value
        }

        TextFieldRow {
            label: qsTr("Session menu GIF")
            value: Config.paths.sessionGif
            placeholderText: "root:/assets/kurukuru.gif"
            onEditingFinished: value => GlobalConfig.paths.sessionGif = value
        }

        TextFieldRow {
            label: qsTr("Media GIF")
            subtext: qsTr("Shown on the dashboard media tab")
            value: Config.paths.mediaGif
            placeholderText: "root:/assets/bongocat.gif"
            onEditingFinished: value => GlobalConfig.paths.mediaGif = value
        }

        TextFieldRow {
            label: qsTr("Empty notifications image")
            value: Config.paths.noNotifsPic
            placeholderText: "root:/assets/dino.png"
            onEditingFinished: value => GlobalConfig.paths.noNotifsPic = value
        }

        TextFieldRow {
            last: true
            label: qsTr("Empty notifications image (lock screen)")
            value: Config.paths.lockNoNotifsPic
            placeholderText: "root:/assets/dino.png"
            onEditingFinished: value => GlobalConfig.paths.lockNoNotifsPic = value
        }

        // Animation
        SectionHeader {
            text: qsTr("Animation")
        }

        StepperRow {
            first: true
            label: qsTr("Media GIF speed divisor")
            subtext: qsTr("The GIF plays at the track's BPM divided by this")
            value: Config.general.mediaGifSpeedAdjustment
            from: 10
            to: 2000
            stepSize: 10
            onMoved: v => GlobalConfig.general.mediaGifSpeedAdjustment = v
        }

        StepperRow {
            last: true
            label: qsTr("Session menu GIF speed")
            value: Config.general.sessionGifSpeed
            from: 0.1
            to: 5
            stepSize: 0.1
            onMoved: v => GlobalConfig.general.sessionGifSpeed = v
        }

        // Windows
        SectionHeader {
            text: qsTr("Windows")
        }

        ToggleRow {
            first: true
            last: true
            text: qsTr("Show over fullscreen")
            subtext: qsTr("Draw shell panels above fullscreen windows")
            checked: Config.general.showOverFullscreen
            onToggled: GlobalConfig.general.showOverFullscreen = checked
        }
    }
}
