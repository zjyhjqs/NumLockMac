add_rules("mode.debug", "mode.release")

target("NumLockMac")
    add_rules("xcode.application")
    set_kind("binary")
    add_files("Source/*.swift")
    set_warnings("allextra", "error")
target_end()
