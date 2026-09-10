/*
 * Single source of truth for every sensor the widget reads.
 *
 * Panel gauges need a handful of sensors all the time; the popup needs many
 * more (per core, per GPU, processes) but only while it is open.  Everything
 * expensive therefore hangs off `detailed`, which the applet ties to the
 * popup's expanded state.
 */
import QtQuick
import org.kde.ksysguard.sensors as Sensors

QtObject {
    id: backend

    property int interval: 2000
    property bool detailed: false
    /* Panel gauges can ask for sensors the popup would otherwise own. */
    property bool panelDisk: false
    property int historyLength: 60
    /* Whether the popup should show Network per interface instead of one merged total. */
    property bool networkSeparated: false
    /* Whether the popup shows Storage: "merged", "separated" (every partition) or "main" (one pinned partition). */
    property string diskMode: "merged"

    /* Discovered at runtime: ids differ per machine (GPUs, batteries, cores). */
    readonly property var gpus: inventory.gpus
    readonly property var batteries: inventory.batteries
    readonly property int coreCount: inventory.coreCount
    readonly property var coreIds: inventory.coreIds
    readonly property var networkInterfaces: inventory.networkInterfaces
    readonly property var disks: inventory.disks

    /* The partition shown in "main" mode. */
    property string mainDiskId: disks.length > 0 ? disks[0].id : ""
    readonly property int mainDiskIndex: {
        for (var i = 0; i < disks.length; i++)
            if (disks[i].id === mainDiskId)
                return i
        return disks.length > 0 ? 0 : -1
    }
    /* The partitions the popup breaks Storage down into */
    readonly property var shownDisks: diskMode === "separated" ? disks
                                    : diskMode === "main" && mainDiskIndex >= 0 ? [disks[mainDiskIndex]]
                                    : []

    readonly property bool hasGpu: gpus.length > 0
    readonly property bool hasBattery: batteries.length > 0

    // ------------------------------------------------------------------ CPU
    readonly property Sensors.Sensor cpuUsage: Sensors.Sensor {
        sensorId: "cpu/all/usage"
        updateRateLimit: backend.interval
    }
    readonly property Sensors.Sensor cpuUser: Sensors.Sensor {
        sensorId: "cpu/all/user"
        updateRateLimit: backend.interval
        enabled: backend.detailed
    }
    readonly property Sensors.Sensor cpuSystem: Sensors.Sensor {
        sensorId: "cpu/all/system"
        updateRateLimit: backend.interval
        enabled: backend.detailed
    }
    readonly property Sensors.Sensor cpuTemp: Sensors.Sensor {
        sensorId: "cpu/cpu0/temperature"
        updateRateLimit: backend.interval
    }

    /* Per-core usage/frequency, only subscribed while the popup is open. */
    readonly property Sensors.SensorDataModel coresModel: Sensors.SensorDataModel {
        sensors: backend.coreIds.map(function (id) { return id + "/usage" })
        enabled: backend.detailed && backend.coreIds.length > 0
        updateRateLimit: backend.interval
    }
    readonly property Sensors.SensorDataModel coreClocksModel: Sensors.SensorDataModel {
        sensors: backend.coreIds.map(function (id) { return id + "/frequency" })
        enabled: backend.detailed && backend.coreIds.length > 0
        updateRateLimit: backend.interval
    }

    readonly property real cpuClock: {
        var reactOnReady = coreClocksModel.ready
        var reactOnTick = historyTick
        if (!detailed || coreClocksModel.columnCount() === 0)
            return 0
        var sum = 0
        var n = 0
        for (var i = 0; i < coreClocksModel.columnCount(); i++) {
            var v = coreClocksModel.data(coreClocksModel.index(0, i), Sensors.SensorDataModel.Value)
            if (v !== undefined && v !== null && !isNaN(v)) {
                sum += v
                n++
            }
        }
        return n > 0 ? sum / n : 0
    }

    // --------------------------------------------------------------- Memory
    readonly property Sensors.Sensor memUsedPercent: Sensors.Sensor {
        sensorId: "memory/physical/usedPercent"
        updateRateLimit: backend.interval
    }
    readonly property Sensors.Sensor memUsed: Sensors.Sensor {
        sensorId: "memory/physical/used"
        updateRateLimit: backend.interval
    }
    readonly property Sensors.Sensor memTotal: Sensors.Sensor {
        sensorId: "memory/physical/total"
        enabled: backend.detailed
    }
    readonly property Sensors.Sensor memApplication: Sensors.Sensor {
        sensorId: "memory/physical/application"
        updateRateLimit: backend.interval
        enabled: backend.detailed
    }
    readonly property Sensors.Sensor memCache: Sensors.Sensor {
        sensorId: "memory/physical/cache"
        updateRateLimit: backend.interval
        enabled: backend.detailed
    }
    readonly property Sensors.Sensor memBuffer: Sensors.Sensor {
        sensorId: "memory/physical/buffer"
        updateRateLimit: backend.interval
        enabled: backend.detailed
    }
    readonly property Sensors.Sensor swapUsed: Sensors.Sensor {
        sensorId: "memory/swap/used"
        updateRateLimit: backend.interval
        enabled: backend.detailed
    }
    readonly property Sensors.Sensor swapTotal: Sensors.Sensor {
        sensorId: "memory/swap/total"
        enabled: backend.detailed
    }

    // -------------------------------------------------------------- Network
    readonly property Sensors.Sensor netDown: Sensors.Sensor {
        sensorId: "network/all/download"
        updateRateLimit: backend.interval
    }
    readonly property Sensors.Sensor netUp: Sensors.Sensor {
        sensorId: "network/all/upload"
        updateRateLimit: backend.interval
    }
    readonly property Sensors.Sensor netTotalDown: Sensors.Sensor {
        sensorId: "network/all/totalDownload"
        updateRateLimit: backend.interval
        enabled: backend.detailed
    }
    readonly property Sensors.Sensor netTotalUp: Sensors.Sensor {
        sensorId: "network/all/totalUpload"
        updateRateLimit: backend.interval
        enabled: backend.detailed
    }

    /* Per-device models.  SensorDataModel subscribes only when its sensor list
       is assigned while enabled, so the lists follow the same gate as `enabled`
       instead of filling as soon as the inventory finds the devices. */

    /* Per-interface rates and cumulative totals */
    readonly property Sensors.SensorDataModel netDownModel: Sensors.SensorDataModel {
        sensors: backend.detailed && backend.networkSeparated
                 ? backend.networkInterfaces.map(function (i) { return i.id + "/download" })
                 : []
        enabled: backend.detailed && backend.networkSeparated && backend.networkInterfaces.length > 0
        updateRateLimit: backend.interval
    }
    readonly property Sensors.SensorDataModel netUpModel: Sensors.SensorDataModel {
        sensors: backend.detailed && backend.networkSeparated
                 ? backend.networkInterfaces.map(function (i) { return i.id + "/upload" })
                 : []
        enabled: backend.detailed && backend.networkSeparated && backend.networkInterfaces.length > 0
        updateRateLimit: backend.interval
    }
    readonly property Sensors.SensorDataModel netTotalDownModel: Sensors.SensorDataModel {
        sensors: backend.detailed && backend.networkSeparated
                 ? backend.networkInterfaces.map(function (i) { return i.id + "/totalDownload" })
                 : []
        enabled: backend.detailed && backend.networkSeparated && backend.networkInterfaces.length > 0
        updateRateLimit: backend.interval
    }
    readonly property Sensors.SensorDataModel netTotalUpModel: Sensors.SensorDataModel {
        sensors: backend.detailed && backend.networkSeparated
                 ? backend.networkInterfaces.map(function (i) { return i.id + "/totalUpload" })
                 : []
        enabled: backend.detailed && backend.networkSeparated && backend.networkInterfaces.length > 0
        updateRateLimit: backend.interval
    }

    // ----------------------------------------------------------------- Disk
    readonly property Sensors.Sensor diskRead: Sensors.Sensor {
        sensorId: "disk/all/read"
        updateRateLimit: backend.interval
        enabled: backend.detailed || backend.panelDisk
    }
    readonly property Sensors.Sensor diskWrite: Sensors.Sensor {
        sensorId: "disk/all/write"
        updateRateLimit: backend.interval
        enabled: backend.detailed || backend.panelDisk
    }
    readonly property Sensors.Sensor diskUsedPercent: Sensors.Sensor {
        sensorId: "disk/all/usedPercent"
        updateRateLimit: backend.interval
        enabled: backend.detailed
    }
    readonly property Sensors.Sensor diskUsed: Sensors.Sensor {
        sensorId: "disk/all/used"
        updateRateLimit: backend.interval
        enabled: backend.detailed
    }
    readonly property Sensors.Sensor diskTotal: Sensors.Sensor {
        sensorId: "disk/all/total"
        enabled: backend.detailed
    }

    /* Per-partition rates and capacity*/
    readonly property Sensors.SensorDataModel diskReadModel: Sensors.SensorDataModel {
        sensors: backend.detailed
                 ? backend.shownDisks.map(function (d) { return d.id + "/read" })
                 : []
        enabled: backend.detailed && backend.shownDisks.length > 0
        updateRateLimit: backend.interval
    }
    readonly property Sensors.SensorDataModel diskWriteModel: Sensors.SensorDataModel {
        sensors: backend.detailed
                 ? backend.shownDisks.map(function (d) { return d.id + "/write" })
                 : []
        enabled: backend.detailed && backend.shownDisks.length > 0
        updateRateLimit: backend.interval
    }
    readonly property Sensors.SensorDataModel diskUsedModel: Sensors.SensorDataModel {
        sensors: backend.detailed
                 ? backend.shownDisks.map(function (d) { return d.id + "/used" })
                 : []
        enabled: backend.detailed && backend.shownDisks.length > 0
        updateRateLimit: backend.interval
    }
    readonly property Sensors.SensorDataModel diskCapacityModel: Sensors.SensorDataModel {
        sensors: backend.detailed
                 ? backend.shownDisks.map(function (d) { return d.id + "/total" })
                 : []
        enabled: backend.detailed && backend.shownDisks.length > 0
        updateRateLimit: backend.interval
    }

    // ------------------------------------------------------------------ GPU
    /* The panel shows one GPU; the popup shows them all (see GpuSection). */
    property string panelGpuId: gpus.length > 0 ? gpus[0].id : ""

    readonly property Sensors.Sensor gpuUsage: Sensors.Sensor {
        sensorId: backend.panelGpuId ? backend.panelGpuId + "/usage" : ""
        updateRateLimit: backend.interval
    }
    readonly property Sensors.Sensor gpuName: Sensors.Sensor {
        sensorId: backend.panelGpuId ? backend.panelGpuId + "/name" : ""
    }
    readonly property Sensors.Sensor gpuTemp: Sensors.Sensor {
        sensorId: backend.panelGpuId ? backend.panelGpuId + "/temperature" : ""
        updateRateLimit: backend.interval
    }

    // -------------------------------------------------------------- Battery
    readonly property string batteryId: batteries.length > 0 ? batteries[0].id : ""
    readonly property Sensors.Sensor batteryCharge: Sensors.Sensor {
        sensorId: backend.batteryId ? backend.batteryId + "/chargePercentage" : ""
        updateRateLimit: backend.interval
        enabled: backend.detailed
    }
    readonly property Sensors.Sensor batteryRate: Sensors.Sensor {
        sensorId: backend.batteryId ? backend.batteryId + "/chargeRate" : ""
        updateRateLimit: backend.interval
        enabled: backend.detailed
    }
    readonly property Sensors.Sensor batteryHealth: Sensors.Sensor {
        sensorId: backend.batteryId ? backend.batteryId + "/health" : ""
        enabled: backend.detailed
    }

    // ------------------------------------------------------------------- OS
    readonly property Sensors.Sensor osName: Sensors.Sensor {
        sensorId: "os/system/prettyName"
    }
    readonly property Sensors.Sensor hostname: Sensors.Sensor {
        sensorId: "os/system/hostname"
    }
    readonly property Sensors.Sensor uptime: Sensors.Sensor {
        sensorId: "os/system/uptime"
        updateRateLimit: 60000
    }
    readonly property Sensors.Sensor kernel: Sensors.Sensor {
        sensorId: "os/kernel/version"
    }

    // -------------------------------------------------------------- History
    /* Fixed-length ring buffers feeding the sparklines.  Arrays are mutated in
       place and `historyTick` is the repaint signal, so no array is copied. */
    property var cpuHistory: []
    property var gpuHistory: []
    property var memHistory: []
    property var netDownHistory: []
    property var netUpHistory: []
    property var diskReadHistory: []
    property var diskWriteHistory: []
    property int historyTick: 0
    property real netPeak: 1
    property real diskPeak: 1

    /* One ring buffer + peak per discovered interface */
    property var netIfDownHistory: []
    property var netIfUpHistory: []
    property var netIfPeak: []

    /* One reading from a per-device model */
    function modelValue(model, column) {
        var reactOnTick = historyTick
        if (column < 0 || column >= model.columnCount())
            return NaN
        var v = model.data(model.index(0, column), Sensors.SensorDataModel.Value)
        return (v === undefined || v === null) ? NaN : v
    }

    /* One per-device history entry */
    function deviceHistory(list, index, fallback) {
        var reactOnTick = historyTick
        return index >= 0 && index < list.length ? list[index] : fallback
    }

    function pushSample(buffer, value) {
        var v = (value === undefined || value === null || isNaN(value)) ? 0 : value
        buffer.push(v)
        while (buffer.length > historyLength)
            buffer.shift()
    }

    function sample() {
        pushSample(cpuHistory, cpuUsage.value)
        pushSample(gpuHistory, gpuUsage.value)
        pushSample(memHistory, memUsedPercent.value)
        pushSample(netDownHistory, netDown.value)
        pushSample(netUpHistory, netUp.value)
        pushSample(diskReadHistory, diskRead.value)
        pushSample(diskWriteHistory, diskWrite.value)

        /* Rates have no fixed ceiling, so each plot scales to its own peak. */
        var peak = 1
        for (var i = 0; i < netDownHistory.length; i++)
            peak = Math.max(peak, netDownHistory[i], netUpHistory[i])
        netPeak = peak

        var diskMax = 1
        for (var j = 0; j < diskReadHistory.length; j++)
            diskMax = Math.max(diskMax, diskReadHistory[j], diskWriteHistory[j])
        diskPeak = diskMax

        if (networkSeparated)
            sampleDevices(networkInterfaces, netDownModel, netUpModel, netIfDownHistory, netIfUpHistory, netIfPeak)

        historyTick++
    }

    /* Samples one reading per discovered device */
    function sampleDevices(ids, modelA, modelB, historyA, historyB, peaks) {
        while (historyA.length < ids.length) {
            historyA.push([])
            historyB.push([])
            peaks.push(1)
        }
        historyA.length = ids.length
        historyB.length = ids.length
        peaks.length = ids.length

        for (var i = 0; i < ids.length; i++) {
            var a = i < modelA.columnCount() ? modelA.data(modelA.index(0, i), Sensors.SensorDataModel.Value) : 0
            var b = i < modelB.columnCount() ? modelB.data(modelB.index(0, i), Sensors.SensorDataModel.Value) : 0
            pushSample(historyA[i], a)
            pushSample(historyB[i], b)

            var p = 1
            for (var k = 0; k < historyA[i].length; k++)
                p = Math.max(p, historyA[i][k], historyB[i][k])
            peaks[i] = p
        }
    }

    readonly property Timer sampler: Timer {
        interval: backend.interval
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: backend.sample()
    }

    // ------------------------------------------------------------ Discovery
    readonly property SensorInventory inventory: SensorInventory {}
}
