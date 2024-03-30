//
//  NumLockToggle.swift
//  Num Lock on macOS
//
//  Created by zjyhjqs on 2023.08.01
//  Copyright © 2023 zjyhjqs. All rights reserved.
//

import CoreGraphics
import Foundation

enum LedStatus : CFIndex {
    case On  = 1
    case Off = 0

    func toggle() -> LedStatus {
        switch self {
        case .On:
            return .Off
        case .Off:
            return .On
        }
    }
}

func numpadRemapping(_ numlockLedStatus: LedStatus) {
    // https://developer.apple.com/library/archive/technotes/tn2450/_index.html
    let mask = 0x700000000
    let numericDisabled = [
        [kIOHIDKeyboardModifierMappingSrcKey: mask | kHIDUsage_Keypad0,
         kIOHIDKeyboardModifierMappingDstKey: mask | kHIDUsage_KeyboardInsert
        ],
        [kIOHIDKeyboardModifierMappingSrcKey: mask | kHIDUsage_KeypadPeriod,
         kIOHIDKeyboardModifierMappingDstKey: mask | kHIDUsage_KeyboardDeleteForward
        ],
        [kIOHIDKeyboardModifierMappingSrcKey: mask | kHIDUsage_Keypad1,
         kIOHIDKeyboardModifierMappingDstKey: mask | kHIDUsage_KeyboardEnd
        ],
        [kIOHIDKeyboardModifierMappingSrcKey: mask | kHIDUsage_Keypad2,
         kIOHIDKeyboardModifierMappingDstKey: mask | kHIDUsage_KeyboardDownArrow
        ],
        [kIOHIDKeyboardModifierMappingSrcKey: mask | kHIDUsage_Keypad3,
         kIOHIDKeyboardModifierMappingDstKey: mask | kHIDUsage_KeyboardPageDown
        ],
        [kIOHIDKeyboardModifierMappingSrcKey: mask | kHIDUsage_Keypad4,
         kIOHIDKeyboardModifierMappingDstKey: mask | kHIDUsage_KeyboardLeftArrow
        ],
        [kIOHIDKeyboardModifierMappingSrcKey: mask | kHIDUsage_Keypad5,
         kIOHIDKeyboardModifierMappingDstKey: mask | kHIDUsage_KeyboardClear // `clear` on windows?
        ],
        [kIOHIDKeyboardModifierMappingSrcKey: mask | kHIDUsage_Keypad6,
         kIOHIDKeyboardModifierMappingDstKey: mask | kHIDUsage_KeyboardRightArrow
        ],
        [kIOHIDKeyboardModifierMappingSrcKey: mask | kHIDUsage_Keypad7,
         kIOHIDKeyboardModifierMappingDstKey: mask | kHIDUsage_KeyboardHome
        ],
        [kIOHIDKeyboardModifierMappingSrcKey: mask | kHIDUsage_Keypad8,
         kIOHIDKeyboardModifierMappingDstKey: mask | kHIDUsage_KeyboardUpArrow
        ],
        [kIOHIDKeyboardModifierMappingSrcKey: mask | kHIDUsage_Keypad9,
         kIOHIDKeyboardModifierMappingDstKey: mask | kHIDUsage_KeyboardPageUp
        ]
    ]
    let numericEnabled = [
        [kIOHIDKeyboardModifierMappingSrcKey: mask | kHIDUsage_Keypad0,
         kIOHIDKeyboardModifierMappingDstKey: mask | kHIDUsage_Keypad0
        ],
        [kIOHIDKeyboardModifierMappingSrcKey: mask | kHIDUsage_KeypadPeriod,
         kIOHIDKeyboardModifierMappingDstKey: mask | kHIDUsage_KeypadPeriod
        ],
        [kIOHIDKeyboardModifierMappingSrcKey: mask | kHIDUsage_Keypad1,
         kIOHIDKeyboardModifierMappingDstKey: mask | kHIDUsage_Keypad1
        ],
        [kIOHIDKeyboardModifierMappingSrcKey: mask | kHIDUsage_Keypad2,
         kIOHIDKeyboardModifierMappingDstKey: mask | kHIDUsage_Keypad2
        ],
        [kIOHIDKeyboardModifierMappingSrcKey: mask | kHIDUsage_Keypad3,
         kIOHIDKeyboardModifierMappingDstKey: mask | kHIDUsage_Keypad3
        ],
        [kIOHIDKeyboardModifierMappingSrcKey: mask | kHIDUsage_Keypad4,
         kIOHIDKeyboardModifierMappingDstKey: mask | kHIDUsage_Keypad4
        ],
        [kIOHIDKeyboardModifierMappingSrcKey: mask | kHIDUsage_Keypad5,
         kIOHIDKeyboardModifierMappingDstKey: mask | kHIDUsage_Keypad5
        ],
        [kIOHIDKeyboardModifierMappingSrcKey: mask | kHIDUsage_Keypad6,
         kIOHIDKeyboardModifierMappingDstKey: mask | kHIDUsage_Keypad6
        ],
        [kIOHIDKeyboardModifierMappingSrcKey: mask | kHIDUsage_Keypad7,
         kIOHIDKeyboardModifierMappingDstKey: mask | kHIDUsage_Keypad7
        ],
        [kIOHIDKeyboardModifierMappingSrcKey: mask | kHIDUsage_Keypad8,
         kIOHIDKeyboardModifierMappingDstKey: mask | kHIDUsage_Keypad8
        ],
        [kIOHIDKeyboardModifierMappingSrcKey: mask | kHIDUsage_Keypad9,
         kIOHIDKeyboardModifierMappingDstKey: mask | kHIDUsage_Keypad9
        ]
    ]

    let system = IOHIDEventSystemClientCreateSimpleClient(kCFAllocatorDefault)
    let keyboardServices = (IOHIDEventSystemClientCopyServices(system) as! [IOHIDServiceClient])
        .filter { IOHIDServiceClientConformsTo($0, UInt32(kHIDPage_GenericDesktop), UInt32(kHIDUsage_GD_Keyboard)) != 0 }
    for keyboard in keyboardServices {
        let result = IOHIDServiceClientSetProperty(
            keyboard,
            kIOHIDUserKeyUsageMapKey as CFString,
            (numlockLedStatus == .On ? numericEnabled : numericDisabled) as CFArray)
        if (!result) {
            print("Fail to remap")
        }
    }
}

func getNumlockLeds(_ manager: IOHIDManager, _ keyboardMatching: CFDictionary) -> any Sequence<IOHIDElement> {
    let keyboards = (IOHIDManagerCopyDevices(manager) as! Set<IOHIDDevice>)
        .filter { IOHIDDeviceConformsTo($0, UInt32(kHIDPage_GenericDesktop), UInt32(kHIDUsage_GD_Keyboard)) }

    return keyboards.compactMap({
        (IOHIDDeviceCopyMatchingElements($0, keyboardMatching, IOOptionBits(kIOHIDOptionsTypeNone)) as! [IOHIDElement])
            .first(where: { IOHIDElementGetUsagePage($0) == kHIDPage_LEDs &&
                            IOHIDElementGetUsage($0) == kHIDUsage_LED_NumLock })
    })
}

func setNumlockLed(_ numlockLed: IOHIDElement, _ newStatus: LedStatus) -> ()? {
    assert(IOHIDElementGetUsagePage(numlockLed) == kHIDPage_LEDs
        && IOHIDElementGetUsage(numlockLed) == kHIDUsage_LED_NumLock)

    let newValue = IOHIDValueCreateWithIntegerValue(kCFAllocatorDefault, numlockLed, mach_absolute_time(), newStatus.rawValue)
    let result = IOHIDDeviceSetValue(IOHIDElementGetDevice(numlockLed), numlockLed, newValue)
    switch (result) {
    case kIOReturnSuccess:
        return ()
    case kIOReturnExclusiveAccess:
        print("Error when setting NumLock state: `kIOReturnExclusiveAccess`")
        print("Try to close `Karabiner-Elements` if opened.")
        return nil
    default:
        print("Error when setting NumLock state: \(result)")
        return nil
    }
}

func setNumlock(_ manager: IOHIDManager, _ keyboardMatching: CFDictionary, _ newStatus: LedStatus) -> ()? {
    var result: ()? = nil
    for numlockLed in getNumlockLeds(manager, keyboardMatching) {
        result = result ?? setNumlockLed(numlockLed, newStatus)
    }
    // TODO: assert same status?

    if (result != nil) {
        numpadRemapping(newStatus)
    }
    return result
}
