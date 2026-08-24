/* Which CPUs, GPUs and batteries this machine actually exposes.
 *
 * The sensor tree carries readable names on the object rows and sensor ids
 * only on their leaves, so an object's id is taken from its first child.  The
 * tree fills in asynchronously, hence the debounced rescan. */
import QtQuick
import org.kde.ksysguard.sensors as Sensors

QtObject {
    id: inventory

    property var gpus: []
    property var batteries: []
    property var coreIds: []
    property var disks: []
    readonly property int coreCount: coreIds.length

    readonly property Sensors.SensorTreeModel tree: Sensors.SensorTreeModel {}

    function objectsOf(subsystem, capabilityLeaf) {
        var out = []
        for (var i = 0; i < tree.rowCount(); i++) {
            var subsystemIdx = tree.index(i, 0)
            for (var j = 0; j < tree.rowCount(subsystemIdx); j++) {
                var objectIdx = tree.index(j, 0, subsystemIdx)
                var childCount = tree.rowCount(objectIdx)
                if (childCount === 0)
                    continue
                var leafId = tree.data(tree.index(0, 0, objectIdx),
                                       Sensors.SensorTreeModel.SensorId)
                if (!leafId)
                    continue
                var parts = String(leafId).split("/")
                if (parts[0] !== subsystem)
                    continue
                var objectId = parts[0] + "/" + parts[1]
                /* Skip the "all" aggregate and the regex group rows. */
                if (parts[1] === "all" || objectId.indexOf("(") >= 0 || objectId.indexOf("\\") >= 0)
                    continue

                var entry = { id: objectId, label: String(tree.data(objectIdx, Qt.DisplayRole)) }

                if (capabilityLeaf) {
                    var wanted = objectId + "/" + capabilityLeaf
                    var has = false
                    for (var k = 0; k < childCount; k++) {
                        if (tree.data(tree.index(k, 0, objectIdx), Sensors.SensorTreeModel.SensorId) === wanted) {
                            has = true
                            break
                        }
                    }
                    entry.hasCapacity = has
                }

                out.push(entry)
            }
        }
        return out
    }

    function rescan() {
        var foundGpus = objectsOf("gpu")
        if (JSON.stringify(foundGpus) !== JSON.stringify(gpus))
            gpus = foundGpus

        var foundBatteries = objectsOf("power")
        if (JSON.stringify(foundBatteries) !== JSON.stringify(batteries))
            batteries = foundBatteries

        var foundDisks = objectsOf("disk", "usedPercent").filter(function (d) { return d.hasCapacity })
        if (JSON.stringify(foundDisks) !== JSON.stringify(disks))
            disks = foundDisks

        var cores = objectsOf("cpu").filter(function (object) {
            return /^cpu\/cpu\d+$/.test(object.id)
        }).map(function (object) {
            return object.id
        }).sort(function (a, b) {
            return parseInt(a.replace("cpu/cpu", "")) - parseInt(b.replace("cpu/cpu", ""))
        })
        if (JSON.stringify(cores) !== JSON.stringify(coreIds))
            coreIds = cores
    }

    readonly property Timer rescanTimer: Timer {
        interval: 250
        repeat: false
        onTriggered: inventory.rescan()
    }

    readonly property Connections treeWatcher: Connections {
        target: inventory.tree
        function onRowsInserted() { inventory.rescanTimer.restart() }
        function onModelReset() { inventory.rescanTimer.restart() }
        function onLayoutChanged() { inventory.rescanTimer.restart() }
    }

    Component.onCompleted: rescanTimer.restart()
}
