/* One row in the Storage card's per-partition breakdown in the same shape as the merged card */

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.ksysguard.sensors as Sensors
import "../code/util.js" as Util

ColumnLayout {
    id: row

    property var backend
    property string label: ""
    property int diskIndex: -1

    Layout.fillWidth: true
    spacing: Kirigami.Units.smallSpacing * 2

    readonly property real read: {
        var reactOnTick = row.backend.historyTick
        var m = row.backend.diskReadModel
        if (row.diskIndex < 0 || row.diskIndex >= m.columnCount())
            return NaN
        var v = m.data(m.index(0, row.diskIndex), Sensors.SensorDataModel.Value)
        return (v === undefined || v === null) ? NaN : v
    }
    readonly property real write: {
        var reactOnTick = row.backend.historyTick
        var m = row.backend.diskWriteModel
        if (row.diskIndex < 0 || row.diskIndex >= m.columnCount())
            return NaN
        var v = m.data(m.index(0, row.diskIndex), Sensors.SensorDataModel.Value)
        return (v === undefined || v === null) ? NaN : v
    }
    readonly property real used: {
        var reactOnTick = row.backend.historyTick
        var m = row.backend.diskUsedModel
        if (row.diskIndex < 0 || row.diskIndex >= m.columnCount())
            return NaN
        var v = m.data(m.index(0, row.diskIndex), Sensors.SensorDataModel.Value)
        return (v === undefined || v === null) ? NaN : v
    }
    readonly property real totalCapacity: {
        var reactOnTick = row.backend.historyTick
        var m = row.backend.diskCapacityModel
        if (row.diskIndex < 0 || row.diskIndex >= m.columnCount())
            return NaN
        var v = m.data(m.index(0, row.diskIndex), Sensors.SensorDataModel.Value)
        return (v === undefined || v === null) ? NaN : v
    }
    readonly property real usedRatio: row.totalCapacity > 0 ? row.used / row.totalCapacity : 0

    Text {
        Layout.fillWidth: true
        text: row.label
        color: Kirigami.Theme.textColor
        opacity: 0.75
        font.pointSize: Kirigami.Theme.smallFont.pointSize
        font.weight: Font.DemiBold
        elide: Text.ElideRight
    }

    MeterBar {
        Layout.fillWidth: true
        value: Util.clamp01(row.usedRatio)
        barColor: Util.loadColor(Util.accent.disk, row.usedRatio)
    }

    GridLayout {
        Layout.fillWidth: true
        columns: 2
        columnSpacing: Kirigami.Units.largeSpacing
        rowSpacing: Kirigami.Units.smallSpacing

        StatLine {
            label: "Used"
            value: Util.bytes(row.used) + " / " + Util.bytes(row.totalCapacity)
            valueSample: "999 GiB / 999 GiB"
            emphasized: true
        }
        StatLine {
            label: "Free"
            value: Util.bytes(row.totalCapacity - row.used)
            valueSample: "999.9 GiB"
        }
    }

    GridLayout {
        Layout.fillWidth: true
        columns: 2
        columnSpacing: Kirigami.Units.largeSpacing
        rowSpacing: Kirigami.Units.smallSpacing

        StatLine {
            label: "Read"
            value: Util.rate(row.read)
            valueSample: "999.9 MiB/s"
        }
        StatLine {
            label: "Write"
            value: Util.rate(row.write)
            valueSample: "999.9 MiB/s"
        }
    }
}
