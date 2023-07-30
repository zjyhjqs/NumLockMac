# Num Lock (LED and function keys) for macOS

The command-line program is designed to implement the [Num Lock](https://wikipedia.org/wiki/Num_Lock) functionality on macOS.

Similar to how it works on IBM compatible PCs, the NumLock key (`Clear` key on macOS) toggles the status indicated by the NumLock LED, and assesses the status of any attached keyboards with numeric-pad.

# Usage

The initial state is Number mode. Press the NumLock key (`Clear`) to toggle the state.

# Known issues:

1. Cannot use with `Karabiner-Elements`: [Why?](https://github.com/pqrs-org/Karabiner-Elements/issues/2560#issuecomment-751698700)
2. `HIToolbox.framework` is marked as [deprecated](https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/OSX_Technology_Overview/SystemFrameworks/SystemFrameworks.html), but seems no replacements in `Cocoa.framework`. ([Related questions](https://stackoverflow.com/a/4642095/12442419))
3. Attach a keyboard when the program is running sometimes may not set the NumLock to proper state. Try to toggle the NumLock key usually works well.
4. Cannot toggle the state in situations:
    - password dialog box
    - Microsoft Remote Desktop
    - login page

# Credits

[setledsmac](https://github.com/damieng/setledsmac)
