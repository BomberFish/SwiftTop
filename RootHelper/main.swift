os_log("[KillHelper] RootHelper started")

import Foundation
import OSLog

let argc = CommandLine.argc
let args = CommandLine.arguments
let argv = CommandLine.unsafeArgv

// Check if the process ID was provided
guard argc > 1 else {
    print("[KillHelper] Usage: kill <pid>")
    exit(EXIT_FAILURE)
}

var signal: Int32 = SIGTERM

if argc == 3 {
    let signalString = args[2]
    let signalNumber: Int32? = Int32(signalString)
    signal = signalNumber ?? SIGTERM
}

let pidString = args[1]
guard let pid = Int32(pidString) else {
    os_log("[KillHelper] Invalid pid \(pidString)")
    exit(EXIT_FAILURE)
}

let result = kill(pid, signal)
if result != 0 {
    os_log("[KillHelper] Failed to kill process \(pidString) \(result)")
    exit(EXIT_FAILURE)
}
