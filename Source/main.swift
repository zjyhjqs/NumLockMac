//
//  main.swift
//  Num Lock on macOS
//
//  Created by zjyhjqs on 2023.08.01
//  Copyright © 2023 zjyhjqs. All rights reserved.
//

import Carbon.HIToolbox // for `kVK_ANSI_KeypadClear`. TODO: `HIToolbox.framework` is deprecated. https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/OSX_Technology_Overview/SystemFrameworks/SystemFrameworks.html
import CoreGraphics

// initialize

let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
let openResult = IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
assert(openResult == kIOReturnSuccess)

let keyboardMatching = [
    kIOHIDDeviceUsageKey: kHIDPage_GenericDesktop,
    kIOHIDDeviceKey: kHIDUsage_GD_Keyboard
] as NSMutableDictionary as CFMutableDictionary

IOHIDManagerSetDeviceMatching(manager, keyboardMatching)

var numlockLedStatus = LedStatus.On

// on keyboard attached

func onKeyboardAttached(context: UnsafeMutableRawPointer?, result: IOReturn, sender: UnsafeMutableRawPointer?, device: IOHIDDevice) {
    if (IOHIDDeviceConformsTo(device, UInt32(kHIDPage_GenericDesktop), UInt32(kHIDUsage_GD_Keyboard))) {
        if let numlockLed = (IOHIDDeviceCopyMatchingElements(
            device, keyboardMatching, IOOptionBits(kIOHIDOptionsTypeNone)) as! [IOHIDElement])
            .first(where: { IOHIDElementGetUsagePage($0) == kHIDPage_LEDs &&
                            IOHIDElementGetUsage($0) == kHIDUsage_LED_NumLock })
        {
            setNumlockLed(numlockLed, numlockLedStatus)
            numpadRemapping(numlockLedStatus)
        }
    }
}

IOHIDManagerRegisterDeviceMatchingCallback(manager, onKeyboardAttached, nil)
IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)

// on `NumLock` is toggled

func onNumlock(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent, refcon: UnsafeMutableRawPointer?)
    -> Unmanaged<CGEvent>?
{
    if (type == .tapDisabledByTimeout) {
        // CGEvent.tapEnable(tap: eventTap, enable: true)
        return Unmanaged.passRetained(event)
    }
    assert(type == .keyDown)

    let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
    // Seems no replacement currently
    if (keyCode == kVK_F18) {
        let result: ()? = setNumlock(manager, keyboardMatching, numlockLedStatus.toggle())
        if (result != nil)
        {
            numlockLedStatus = numlockLedStatus.toggle()
        }
    }

    return Unmanaged.passRetained(event)
}

let keyboardEvents : CGEventMask =
    1 << CGEventType.keyDown.rawValue

guard let eventTap = CGEvent.tapCreate(
    tap: .cgSessionEventTap,
    place: .headInsertEventTap,
    options: .defaultTap,
    eventsOfInterest: keyboardEvents,
    callback: onNumlock,
    userInfo: nil
) else {
    print("Failed to create event tap")
    exit(1)
}

let numlockTrigger = CFMachPortCreateRunLoopSource(
    kCFAllocatorDefault, eventTap, 0)!
CFRunLoopAddSource(
    CFRunLoopGetMain(), numlockTrigger, .commonModes)
CGEvent.tapEnable(tap: eventTap, enable: true)

// monitor
CFRunLoopRun()
