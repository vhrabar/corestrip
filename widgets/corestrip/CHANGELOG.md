# Changelog

## 1.2.0

- Network and Storage cards can break their totals down instead of only
  showing one merged number: every network interface separately, and
  either every mounted partition or just one pinned "main" partition.
  Merged stays the default for both.

## 1.1.1

- Popup sections switch off completely: the summary rings on top follow the
  same switches, and the processor section has one of its own instead of only
  its per-core grid ([#1](https://github.com/stektus/corestrip/issues/1)).
- With every panel gauge switched off the widget keeps a small icon rather
  than becoming an invisible gap that cannot be clicked or configured.

## 1.1.0

- Text size setting (50–150 %) that scales the readouts and the gauges
  together, within what the panel thickness allows.

## 1.0.0

First release.

- Panel gauges for processor, graphics, memory, network and disk activity,
  in four styles: plot and readout (default), rings, history bars, numbers.
- Readout adapts to panel height — two lines where they fit, a single
  `CPU 32% 51°` line where they do not — and reserves width for the widest
  value so the panel never shifts while numbers change.
- Hover tooltip summarising processor, graphics, memory, network and disk.
- Popup with per-core load, one card per GPU (usage, temperature, clock,
  power, video memory), memory breakdown, network and disk throughput,
  battery and the top processes by CPU or memory.
- All readings come from `ksystemstats`; sensors only the popup needs stay
  unsubscribed until it opens.
