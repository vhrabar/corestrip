/* One row in the Network card's per-interface breakdown in the same shape as the merged card */

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.ksysguard.sensors as Sensors
import "../code/util.js" as Util

ColumnLayout {
    id: row

    property var backend
    property string label: ""
    property int interfaceIndex: -1

    Layout.fillWidth: true
    spacing: Kirigami.Units.smallSpacing * 2

    readonly property real down: {
        var reactOnTick = row.backend.historyTick
        var m = row.backend.netDownModel
        if (row.interfaceIndex < 0 || row.interfaceIndex >= m.columnCount())
            return NaN
        var v = m.data(m.index(0, row.interfaceIndex), Sensors.SensorDataModel.Value)
        return (v === undefined || v === null) ? NaN : v
    }
    readonly property real up: {
        var reactOnTick = row.backend.historyTick
        var m = row.backend.netUpModel
        if (row.interfaceIndex < 0 || row.interfaceIndex >= m.columnCount())
            return NaN
        var v = m.data(m.index(0, row.interfaceIndex), Sensors.SensorDataModel.Value)
        return (v === undefined || v === null) ? NaN : v
    }
    readonly property real totalDown: {
        var reactOnTick = row.backend.historyTick
        var m = row.backend.netTotalDownModel
        if (row.interfaceIndex < 0 || row.interfaceIndex >= m.columnCount())
            return NaN
        var v = m.data(m.index(0, row.interfaceIndex), Sensors.SensorDataModel.Value)
        return (v === undefined || v === null) ? NaN : v
    }
    readonly property real totalUp: {
        var reactOnTick = row.backend.historyTick
        var m = row.backend.netTotalUpModel
        if (row.interfaceIndex < 0 || row.interfaceIndex >= m.columnCount())
            return NaN
        var v = m.data(m.index(0, row.interfaceIndex), Sensors.SensorDataModel.Value)
        return (v === undefined || v === null) ? NaN : v
    }
    readonly property var downHistory: {
        var reactOnTick = row.backend.historyTick
        return row.interfaceIndex >= 0 && row.interfaceIndex < row.backend.netIfDownHistory.length
               ? row.backend.netIfDownHistory[row.interfaceIndex] : []
    }
    readonly property var upHistory: {
        var reactOnTick = row.backend.historyTick
        return row.interfaceIndex >= 0 && row.interfaceIndex < row.backend.netIfUpHistory.length
               ? row.backend.netIfUpHistory[row.interfaceIndex] : []
    }
    readonly property real peak: {
        var reactOnTick = row.backend.historyTick
        return row.interfaceIndex >= 0 && row.interfaceIndex < row.backend.netIfPeak.length
               ? row.backend.netIfPeak[row.interfaceIndex] : 1
    }

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
