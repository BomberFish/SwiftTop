import Foundation
import OSLog

let argc = CommandLine.argc
let args = CommandLine.arguments
let argv = CommandLine.unsafeArgv
var signal: Int32 = SIGTERM
let silent = args.contains(where: {$0 == "--silent"})

func printDebug(_ message: String) {
    if !silent {
        print(message)
    }
}

printDebug("(\(#file):\(#line)) [PrivHelper:INFO] RootHelper started")

func getArgValueByName(_ name: String) -> String {
    guard let item = args.firstIndex(where: { $0 == name }) else {
        printDebug("(\(#file):\(#line)) [PrivHelper:ERR] \(name) is not an argument!!!")
        exit(EXIT_FAILURE)
    }
    if argc == args.count - 1 {
        printDebug("(\(#file):\(#line)) [PrivHelper:ERR] No value provided for \(name)")
        exit(EXIT_FAILURE)
    } else {
        return args[item + 1]
    }
}

// Check if the process ID was provided
guard argc > 1 else {
    print("(\(#file):\(#line)) [PrivHelper:ERR] No verb provided")
    exit(69)
}

let userName = NSUserName()
let fullUserName = NSFullUserName()

if userName != "root" {
    printDebug("(\(#file):\(#line)) [PrivHelper:WARN] Not running as root! This could end badly!")
    printDebug("(\(#file):\(#line)) [PrivHelper:INFO] Running as user \(userName) (full name \(fullUserName))")
}

switch args[1] {
case "kill":
    kill()
case "libs":
    dylibs()
case "spin":
    while true {
        print("(\(#file):\(#line)) Weeeeeeeee.....")
        sleep(2)
    }
default:
    printDebug("(\(#file):\(#line)) [PrivHelper:ERR] Unknown verb \(args[1])")
}

func kill() {
    if argc == 3 {
        let signalString = args[3]
        let signalNumber: Int32? = Int32(signalString)
        signal = signalNumber ?? SIGTERM
    }
    
    let pidString = args[2]
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
    let pid = args[2]
    guard let pidInt = Int32(pid) else { printDebug("(\(#file):\(#line)) [PrivHelper:ERR] Invalid pid \(args[2])"); exit(-1) }
    
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
