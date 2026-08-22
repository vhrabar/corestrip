# Changelog

## 1.0.0

First release.

- Panel shows album art, an animated equalizer, the title block and transport
  buttons, in a configurable order and with a progress line.
- Popup with the cover, seek bar, shuffle and repeat, volume and a player list.
- Reads MPRIS2, so browsers and desktop players are both understood.
- Five equalizer styles; the colour can be taken from the album art.
- Scroll wheel changes the volume, middle click plays or pauses. The wheel
  drives the player's own audio stream in the mixer — the level browsers and
  Spotify actually obey — with the MPRIS volume as the fallback, a step from
  1 to 25 % per notch and the level shown over the strip while it moves.
- Equalizer, buttons and cover all follow the text size setting, and the bars
  carry falling peak caps.
