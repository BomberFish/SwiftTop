// bomberfish
// main.swift – SwiftTop
// created on 2024-02-12

import Foundation

let args = CommandLine.arguments
let argc = CommandLine.argc
let unsafeArgv = CommandLine.unsafeArgv

// MARK: - HOLY SHIT WTF
let falseObjc = ObjCBool(false)
let unsafeFalseObjc = UnsafeMutablePointer<ObjCBool>.allocate(capacity: 1)
unsafeFalseObjc.initialize(to: falseObjc)
// MARK: - Log
if !FileManager.default.fileExists(atPath: "/var/mobile/Library/Logs/swifttop.txt", isDirectory: unsafeFalseObjc) {
    FileManager.default.createFile(atPath: "/var/mobile/Library/Logs/swifttop.txt", contents: nil)
}
let contents = try? String(contentsOf: .init(fileURLWithPath: "/var/mobile/Library/Logs/swifttop.txt"))
try? (contents ?? "" + "\n[\(Date.now)] SwiftTop invoked with command line " + args.joined(separator: " ")).write(to: .init(fileURLWithPath: "/var/mobile/Library/Logs/swifttop.txt\n"), atomically: true, encoding: .ascii)
// MARK: - Main
if argc > 1 && args[safe: 1] == "--cli" {
    // Run as roothelper
    var signal: Int32 = SIGTERM
    let silent = args.contains(where: {$0 == "--silent"})

    func printDebug(_ message: String) {
        if !silent {
            print(message)
        }
    }

    printDebug("(\(#file):\(#line)) [PrivHelper:INFO] RootHelper started")

    func getArgValueByName(_ name: String) -> String? {
        guard let item = args.firstIndex(where: { $0 == name }) else {
            printDebug("(\(#file):\(#line)) [PrivHelper:ERR] \(name) is not an argument!!!")
            exit(EXIT_FAILURE)
        }
        if argc == args.count - 1 {
            printDebug("(\(#file):\(#line)) [PrivHelper:ERR] No value provided for \(name)")
            exit(EXIT_FAILURE)
        } else {
            return args[safe: item + 1]
        }
    }

    // Check if the command was provided
    guard argc > 2 else {
        print("(\(#file):\(#line)) [PrivHelper:ERR] No verb provided")
        exit(69)
    }

    let userName = NSUserName()
    let fullUserName = NSFullUserName()

    if userName != "root" {
        printDebug("(\(#file):\(#line)) [PrivHelper:WARN] Not running as root! This could end badly!")
        printDebug("(\(#file):\(#line)) [PrivHelper:INFO] Running as user \(userName) (full name \(fullUserName))")
    }

    switch args[safe: 2] {
    case "--kill":
        killProc()
    case "--libs":
        dylibs()
    case "--spin":
        while true {
            print("(\(#file):\(#line)) Weeeeeeeee.....")
            sleep(2)
        }
    default:
        printDebug("(\(#file):\(#line)) [PrivHelper:ERR] Unknown verb \(args[safe: 2] ?? "")")
    }

    func killProc() {
        if let signalString = args[safe: 5],
           let signalNumber = Int32(signalString) {
            signal = signalNumber
        }
        
        guard let pidString = getArgValueByName("--kill") else {print("[PrivHelper:ERR] No pid provided!");exit(EXIT_FAILURE)}
        guard let pid = Int32(pidString) else {
            printDebug("(\(#file):\(#line)) [PrivHelper:ERR] Invalid pid \(pidString)")
            exit(EXIT_FAILURE)
        }
        
        let result = kill(pid, signal)
        if result != 0 {
            printDebug("(\(#file):\(#line)) [PrivHelper:ERR] Failed to kill process \(pidString) \(result)")
            exit(EXIT_FAILURE)
        }
    }

    func dylibs() {
        guard let pid = getArgValueByName("--libs") else {print("[PrivHelper:ERR] No pid provided!");exit(EXIT_FAILURE)}
        guard let pidInt = Int32(pid) else { printDebug("(\(#file):\(#line)) [PrivHelper:ERR] Invalid pid \(getArgValueByName("--libs") ?? "")"); exit(-1) }
        
        let dylibs = getDylibsForPID(pidInt)
        do {
            // Convert the NSDictionary to JSON data
            let jsonData = try JSONSerialization.data(withJSONObject: dylibs ?? [[:]])
            
            // Convert JSON data to a string (optional)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print(jsonString)
            } else {
                printDebug("(\(#file):\(#line)) [PrivHelper] Error converting JSON data to string")
                exit(-1)
            }
        } catch {
            printDebug("(\(#file):\(#line)) [PrivHelper] Error converting to JSON: \(error.localizedDescription)")
            exit(-1)
        }
    }

} else {
  // Run the app when launching from the home screen
  SwiftTopApp.main()
}
