// bomberfish
// SwiftTopApp.swift – SwiftTop
// created on 2023-12-14

//import LocalConsole
import SwiftUI



@main
struct SwiftTopApp: App {
    /// stdout
    var pipe = Pipe()
    /// stderr
    var pipe2 = Pipe()
    
    public func openConsolePipe() { // thanks alfiecg
        setvbuf(stdout, nil, _IONBF, 0)
        setvbuf(stderr, nil, _IONBF, 0)
        dup2(pipe.fileHandleForWriting.fileDescriptor,
             STDOUT_FILENO)
        dup2(pipe2.fileHandleForWriting.fileDescriptor,
             STDERR_FILENO)
        // listening on the readabilityHandler
        pipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            let str = String(data: data, encoding: .ascii) ?? "<Non-ascii data of size\(data.count)>\n"
            DispatchQueue.main.async {
                Log.shared.items.append(.init(type: .regular, message: str))
                LCManager.shared.print(str)
            }
        }
        
        pipe2.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            let str = String(data: data, encoding: .ascii) ?? "<Non-ascii data of size\(data.count)>\n"
            DispatchQueue.main.async {
                Log.shared.items.append(.init(type: .error, message: str))
                LCManager.shared.print(str)
            }
        }
    }
    
    @AppStorage("showConsole") var showConsole = false
    init() {
        openConsolePipe()
        // register some defaults
        if UserDefaults.standard.value(forKey: "timeInterval") == nil {
            UserDefaults.standard.setValue(1.0, forKey: "timeInterval")
        }
        
        if UserDefaults.standard.value(forKey: "autoRefresh") == nil {
            UserDefaults.standard.setValue(true, forKey: "autoRefresh")
        }
        let lc = LCManager.shared
        lc.isVisible = showConsole
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
