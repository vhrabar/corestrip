/*
 * The volume you actually hear.
 *
 * MPRIS has a Volume property, but for most of what people play it is a
 * decoration: browsers and Spotify report 1.0 for ever and ignore what is
 * written to it. The level that moves is the one PulseAudio keeps for the
 * application's own audio stream, so that is what this drives.
 *
 * The stream is matched to the player that the strip is showing — by process
 * id first, then by name, and finally by "there is only one thing making
 * sound". Loaded on demand, so a desktop without plasma-pa simply falls back
 * to the MPRIS volume instead of failing to start.
 */
import QtQuick
import QtQml
import org.kde.plasma.private.volume as Vol

Item {
    id: control

    /* The MPRIS player object the strip currently follows, and whether it is
       playing right now — the last-resort guess leans on that. */
    property var player: null
    property bool playing: false

    /* PulseAudio's unity volume: 65536 is 100 %. */
    readonly property int fullVolume: 65536

    /* The matched PulseAudio stream, or null while nothing fits. */
    property var stream: null
    readonly property bool available: stream !== null && stream !== undefined

    /* A write travels to the sound server and comes back; until it does, the
       level shown is the one asked for, so a fast scroll does not read its own
       stale value and undo half of itself. */
    property real pending: -1

    readonly property real volume: pending >= 0
                                   ? pending
                                   : (available ? Math.max(0, Math.min(1, stream.volume / fullVolume)) : 0)
    readonly property bool muted: available && stream.muted

    visible: false
    width: 0
    height: 0

    function setVolume(value) {
        if (!available)
            return
        var wanted = Math.max(0, Math.min(1, value))
        pending = wanted
        settle.restart()
        stream.volume = Math.round(wanted * fullVolume)
        if (stream.muted && wanted > 0)
            stream.muted = false
    }

    function nudge(delta) {
        if (available)
            setVolume(volume + delta)
    }

    // ------------------------------------------------------------ matching --
    function normalize(text) {
        return String(text === undefined || text === null ? "" : text)
               .toLowerCase().replace(/[^a-z0-9]/g, "")
    }

    /* Names rarely match to the letter: "Mozilla Firefox" against "firefox",
       "Chromium" against "chromium-browser". Containment either way is close
       enough, as long as the shorter side is not a two-letter coincidence. */
    function similar(a, b) {
        if (a.length < 3 || b.length < 3)
            return false
        return a === b || a.indexOf(b) >= 0 || b.indexOf(a) >= 0
    }

    function playerNames() {
        var names = []
        if (!player)
            return names
        names.push(normalize(player.identity))
        var entry = String(player.desktopEntry || "")
        names.push(normalize(entry.split("/").pop().replace(/\.desktop$/, "")))
        return names.filter(function (name) { return name.length > 0 })
    }

    function playerPids() {
        var pids = []
        if (!player)
            return pids
        if (player.instancePid > 0)
            pids.push(player.instancePid)
        if (player.kdePid > 0)
            pids.push(player.kdePid)
        return pids
    }

    /* Something audible beats something parked: a paused stream keeps its slot
       in the mixer long after the sound stopped. */
    function preferred(candidates) {
        for (var i = 0; i < candidates.length; i++)
            if (!candidates[i].corked)
                return candidates[i]
        return candidates.length > 0 ? candidates[0] : null
    }

    function matchStream() {
        var live = []
        for (var i = 0; i < entries.count; i++) {
            var entry = entries.objectAt(i)
            if (entry && entry.pulse && !entry.virtualStream)
                live.push(entry)
        }

        var pids = playerPids()
        var names = playerNames()
        var byPid = []
        var byName = []

        for (var j = 0; j < live.length; j++) {
            if (pids.indexOf(live[j].pid) >= 0) {
                byPid.push(live[j])
                continue
            }
            for (var k = 0; k < live[j].names.length; k++) {
                var candidate = live[j].names[k]
                var hit = false
                for (var n = 0; n < names.length; n++)
                    hit = hit || similar(candidate, names[n])
                if (hit) {
                    byName.push(live[j])
                    break
                }
            }
        }

        /* Nothing named itself recognisably. If a single application is making
           sound while the player says it is playing, the two are the same
           thing often enough to be worth the guess — but only then, so a
           paused browser tab never ends up turning a music player down. */
        var lone = live.length === 1 && playing && !live[0].corked ? live[0] : null
        var pick = preferred(byPid) || preferred(byName) || lone
        var found = pick ? pick.pulse : null
        if (found !== stream) {
            stream = found
            pending = -1
        }
    }

    readonly property Timer rematch: Timer {
        interval: 120
        onTriggered: control.matchStream()
    }

    /* The write above is answered by the server, not by us; if the stream
       refuses to move, the shown level must still find its way back. */
    readonly property Timer settle: Timer {
        interval: 1200
        onTriggered: control.pending = -1
    }

    onPlayerChanged: matchStream()
    onPlayingChanged: rematch.restart()

    Vol.SinkInputModel {
        id: sinkInputs
    }

    Instantiator {
        id: entries

        model: sinkInputs

        delegate: QtObject {
            required property var model

            readonly property var pulse: model.PulseObject
            readonly property bool corked: model.Corked
            readonly property bool virtualStream: model.VirtualStream
            readonly property var properties: model.Properties

            readonly property int pid: {
                var value = properties ? properties["application.process.id"] : undefined
                if (value === undefined && pulse && pulse.client && pulse.client.properties)
                    value = pulse.client.properties["application.process.id"]
                return parseInt(value) || 0
            }

            readonly property var names: {
                var found = []
                if (properties) {
                    found.push(control.normalize(properties["application.name"]))
                    found.push(control.normalize(properties["application.process.binary"]))
                    found.push(control.normalize(properties["application.id"]))
                }
                if (pulse && pulse.client)
                    found.push(control.normalize(pulse.client.name))
                return found.filter(function (name) { return name.length > 0 })
            }

            onCorkedChanged: control.rematch.restart()
        }

        onCountChanged: control.rematch.restart()
        onObjectRemoved: function (index, object) {
            if (object && object.pulse === control.stream)
                control.stream = null
            control.rematch.restart()
        }
    }

    Component.onCompleted: matchStream()
}
