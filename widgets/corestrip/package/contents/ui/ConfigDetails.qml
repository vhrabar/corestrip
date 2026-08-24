import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: page

    property alias cfg_popupCores: coresBox.checked
    property alias cfg_popupGpu: gpuBox.checked
    property alias cfg_popupMemory: memoryBox.checked
    property alias cfg_popupNetwork: networkBox.checked
    property alias cfg_popupDisk: diskBox.checked
    property string cfg_diskMode
    property string cfg_mainDisk
    property alias cfg_popupBattery: batteryBox.checked
    property alias cfg_popupProcesses: processesBox.checked

    SensorInventory {
        id: inventory
    }

    Kirigami.FormLayout {
        anchors.fill: parent

        QQC2.CheckBox {
            id: coresBox
            Kirigami.FormData.label: "Show in popup:"
            text: "Per-core load"
        }

        QQC2.CheckBox {
            id: gpuBox
            text: "Graphics cards"
        }

        QQC2.CheckBox {
            id: memoryBox
            text: "Memory"
        }

        QQC2.CheckBox {
            id: networkBox
            text: "Network"
        }

        QQC2.CheckBox {
            id: diskBox
            text: "Storage"
        }

        QQC2.ComboBox {
            id: diskModeBox
            Kirigami.FormData.label: "Storage breakdown:"
            enabled: diskBox.checked
            textRole: "label"
            valueRole: "key"
            model: [
                { key: "merged", label: "All disks merged" },
                { key: "separated", label: "Each partition separately" },
                { key: "main", label: "Only main partition" }
            ]
            currentIndex: Math.max(0, indexOfValue(page.cfg_diskMode))
            onActivated: page.cfg_diskMode = currentValue
        }

        QQC2.ComboBox {
            id: mainDiskBox
            Kirigami.FormData.label: "Main partition:"
            enabled: diskBox.checked && diskModeBox.currentValue === "main"
            textRole: "label"
            valueRole: "key"
            model: {
                var entries = [{ key: "auto", label: "Automatic" }]
                for (var i = 0; i < inventory.disks.length; i++) {
                    entries.push({
                        key: inventory.disks[i].id,
                        label: inventory.disks[i].label
                    })
                }
                return entries
            }
            currentIndex: Math.max(0, indexOfValue(page.cfg_mainDisk))
            onActivated: page.cfg_mainDisk = currentValue
        }

        QQC2.CheckBox {
            id: batteryBox
            text: "Battery"
        }

        QQC2.CheckBox {
            id: processesBox
            text: "Top processes"
        }

        QQC2.Label {
            Kirigami.FormData.label: "Note:"
            text: "Sections that need extra sensors are only polled while the popup is open."
            wrapMode: Text.WordWrap
            opacity: 0.7
            font: Kirigami.Theme.smallFont
            Layout.fillWidth: true
            Layout.maximumWidth: Kirigami.Units.gridUnit * 18
        }
    }
}
