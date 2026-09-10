/* One row in the Network card's per-interface breakdown in the same shape as the merged card */

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import "../code/util.js" as Util

ColumnLayout {
    id: row

    property var backend
    property string label: ""
    property int interfaceIndex: -1

    Layout.fillWidth: true
    spacing: Kirigami.Units.smallSpacing * 2

    readonly property real down: row.backend.modelValue(row.backend.netDownModel, row.interfaceIndex)
    readonly property real up: row.backend.modelValue(row.backend.netUpModel, row.interfaceIndex)
    readonly property real totalDown: row.backend.modelValue(row.backend.netTotalDownModel, row.interfaceIndex)
    readonly property real totalUp: row.backend.modelValue(row.backend.netTotalUpModel, row.interfaceIndex)
    readonly property var downHistory: row.backend.deviceHistory(row.backend.netIfDownHistory, row.interfaceIndex, [])
    readonly property var upHistory: row.backend.deviceHistory(row.backend.netIfUpHistory, row.interfaceIndex, [])
    readonly property real peak: row.backend.deviceHistory(row.backend.netIfPeak, row.interfaceIndex, 1)

    Text {
        Layout.fillWidth: true
        text: row.label
        color: Kirigami.Theme.textColor
        opacity: 0.75
        font.pointSize: Kirigami.Theme.smallFont.pointSize
        font.weight: Font.DemiBold
        elide: Text.ElideRight
    }

    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: Kirigami.Units.gridUnit * 2.8

        Sparkline {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: parent.height / 2 - 1
            values: row.downHistory
            revision: row.backend.historyTick
            capacity: row.backend.historyLength
            maximum: row.peak
            lineColor: Util.accent.network
        }
        Sparkline {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: parent.height / 2 - 1
            values: row.upHistory
            revision: row.backend.historyTick
            capacity: row.backend.historyLength
            maximum: row.peak
            lineColor: Util.accent.disk
            mirrored: true
        }
    }

    GridLayout {
        Layout.fillWidth: true
        columns: 2
        columnSpacing: Kirigami.Units.largeSpacing
        rowSpacing: Kirigami.Units.smallSpacing

        StatLine {
            label: "Download"
            value: Util.rate(row.down)
            valueSample: "999.9 MiB/s"
            valueColor: Util.accent.network
            emphasized: true
        }
        StatLine {
            label: "Upload"
            value: Util.rate(row.up)
            valueSample: "999.9 MiB/s"
            valueColor: Util.accent.disk
            emphasized: true
        }
        StatLine {
            label: "Received"
            value: Util.bytes(row.totalDown)
            valueSample: "999.9 GiB"
        }
        StatLine {
            label: "Sent"
            value: Util.bytes(row.totalUp)
            valueSample: "999.9 GiB"
        }
    }
}
