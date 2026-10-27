# Research notes

Scratch probes used while figuring out how macOS drives the Touch Bar backlight.
They are not part of the tool; keep them for reproduction and for the dead ends
they document.

All of them compile with:

```sh
clang -fobjc-arc -framework Foundation -o /tmp/x <file>.m
clang -framework Foundation -framework IOKit -o /tmp/x <file>.c
```

| File | What it showed |
|---|---|
| `01-runtime-dump.m` | Dumps every DFR / brightness ObjC class and its methods at runtime (system frameworks live in the dyld shared cache, so `nm` on disk is empty) |
| `02-dfr-client.m` | `DFRBrightnessClient` works from user space, but `dimToStep:` only stores a preference in CoreBrightness. `_DFRService` is NULL so nothing reaches hardware |
| `03-dfr-display.m` | `DFRDisplayCreate` returns an object but the interface never becomes present (`IsInterfacePresent`/`IsReady` stay 0); `DFRDisplaySetBrightness` fails with `0xe00002d8` |
| `04-hid-services.m` | Enumerates the 143 IOHID services. Only `TouchBarUserDevice` is Touch Bar related; there is no DFR backlight service visible to user space |
| `05-als-events.c` | Builds and dispatches an AmbientLightSensor HID event (`IOHIDEventCreateAmbientLightSensorEvent` + `SetFloatValue` + `DispatchEvent`). It is not delivered to other clients, so CoreBrightness never sees it |
| `06-als-override.m` | **The breakthrough**: `AABSensorOverride` on `BrightnessSystemClient` is the lux value itself. 0.5 → 0.5 lux, 5000 → 5000 lux, 50000 → clamped to 5000 |
| `07-lux-monitor.m` | Watches `Lux` and `AABSensorOverride` over time. `Lux` lags ~1s behind the override |
| `08-als-service.m` | Reads `CurrentLux` from the `als` HID service — the raw sensor value, independent of the override |

## Gotchas discovered

* `setProperty:nil` on `BrightnessSystemClient` **crashes `corebrightnessd`**:
  `-[CBColorModuleShared setPropertyInternal:forKey:]` does
  `[_dict setObject:forKey:]` and throws on nil, aborting the daemon. Use `-1`.
* ObjC classes from the shared cache have no symbols on disk; use the runtime
  (`objc_getClassList`) or `dyld_info -exports <framework path>`.
* `DFRDisplay*` / `DFRFoundation` functions can be resolved with `dlsym` after
  `dlopen`; the C signatures have to be recovered from disassembly
  (e.g. `IOHIDEventCreateAmbientLightSensorEvent(alloc, timestamp, usage, options)`
  has **no** level argument).
