// bomberfish
// ProcessView.swift – SwiftTop
// created on 2023-12-14

import Darwin
import MachO
import OSLog
import SwiftUI

struct ProcessView: View {
    public var proc: NSDictionary
    @State var loadedModules: [NSDictionary]?
    @State var currentModules: [NSDictionary]?
    
    @State var selectedTab = 0
    
    @State var stdout: String = ""
    @State var stderr: String = ""
    
    @State var searchText: String = ""
    
    init(proc: NSDictionary) {
        self.proc = proc
    }
    
    @ViewBuilder
    var info: some View {
        List {
            Section("Basic Info") {
                InfoCell(title: "Name", value: proc["proc_name"] as? String ?? "Unknown")
                InfoCell(title: "Path", value: proc["proc_path"] as? String ?? "Unknown")
                InfoCell(title: "PID", value: proc["pid"] as? String ?? "Unknown")
                InfoCell(title: "User", value: proc["proc_owner"] as? String ?? "Unknown")
            }
                
            Section("Advanced Info") {
                InfoCell(title: "Parent PID", value: getNameFromPID(proc["ppid"] as? String) ?? "Unknown (most likely 1)")
                InfoCell(title: "Executable type", value: parseMachO(proc["proc_path"] as! String)?.rawValue ?? "Unknown")
            }
        }
    }
    
    @ViewBuilder
    var modulesRoot: some View {
        ScrollView([.horizontal, .vertical]) {
            LazyVStack(alignment: .leading) {
                Group {
                    Text(stderr)
                        .foregroundColor(Color(UIColor.systemRed))
                    Text(stdout)
                }
                .padding()
                .multilineTextAlignment(.leading)
                .textSelection(.enabled)
            }
        }
    }
    
    @ViewBuilder
    var modules: some View {
        VStack(spacing: 12) {
            if let loadedModules,
                let currentModules {
                if loadedModules.isEmpty {
                    Spacer()
                    Image(systemName: "app.dashed")
                        .font(.system(size: 84).weight(.medium))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    Text("Could not find any loaded modules.")
                        .font(.title2.weight(.semibold))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    Text("Hint: check the app logs for more information.")
                        .font(.caption.weight(.regular))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                    Spacer()
                } else {
                    List {
                        ForEach(currentModules, id: \.self) { dylib in
                            HStack {
                                Image(systemName: "building.columns.fill")
                                    .foregroundColor(Color(UIColor.label))
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 32, height: 32)
                                    .font(.system(size: 24))
                                VStack(alignment: .leading) {
                                    Text(dylib["imageName"] as? String ?? "foo.dylib")
                                        .font(.headline)
                                    Text(dylib["imagePath"] as? String ?? "/baz/bar/foo.dylib")
                                        .font(.callout)
                                    // TODO: loadAddr
                                }
                            }
                        }
                    }
                    .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search loaded modules")
                }
            } else {
//                let logs = Log.shared.items.suffix(10)
                Spacer()
                Image(systemName: "app.dashed")
                    .font(.system(size: 84).weight(.medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                Text("There was an error loading the modules.")
                    .font(.title2.weight(.semibold))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                Text("Hint: check the app logs for more information.")
                    .font(.caption.weight(.regular))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
//                ForEach(logs) {log in
//                    Text(log.message)
//                        .font(.system(.caption2, design: .monospaced))
//                    
//                }
                Spacer()
            }
        }
    }
    
    var body: some View {
        Group {
            switch selectedTab {
            case 0:
                info
            case 1:
                modules
                    .onAppear {
                        if let pidString = proc["pid"] as? String {
                            do {
                                if let pid = Int32(pidString) {
                                    loadedModules = try getDylibs(pid)
                                    currentModules = loadedModules
                                } else {
                                    print("Could not typecast pid \(pidString)!")
                                }
                            } catch {
                                print("Could not get loaded modules for pid \(pidString)")
                            }
                        } else {
                            print("Could not get pid?!")
                        }
                    }
            case 2:
                modulesRoot
                    .onAppear {
                        if let pidString = proc["pid"] as? String {
                            let result = spawnRootWithOutput(helperPath!, ["libs", pidString])
                            stderr = "\(result.ret != 0 ? "Exited with code \(result)\n\n" : "")"
                            stderr += result.stderr
                            stdout = "\(result.ret == 0 ? "Command completed successfully\n\n" : "")"
                            stdout += result.stdout
                        }
                    }
            default:
                Text("Not Implemented :(")
            }
        }
        .onChange(of: searchText) { _ in
            if let loadedModules {
                withAnimation {
                    if searchText == "" {
                        currentModules = loadedModules
                    } else {
                        currentModules = loadedModules.filter({ dylib in
                            let name = dylib["imageName"] as? String ?? "foo.dylib"
                            let path = dylib["imagePath"] as? String ?? "/baz/bar/foo.dylib"
                            return name.localizedCaseInsensitiveContains(searchText) || path.localizedCaseInsensitiveContains(searchText)
                        })
                    }
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle(proc["proc_name"] as? String ?? "Unknown")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack {
                    Menu {
                        Section("Info") {
                            Button(action: { withAnimation { selectedTab = 0 }}, label: { Label("Info", systemImage: "info.circle") })
                            Button(action: { withAnimation { selectedTab = 1 }}, label: { Label("Mapped modules", systemImage: "memorychip") })
//                            Button(action: {withAnimation{selectedTab=2}}, label: {Label("Mapped modules (RootHelper)", systemImage: "memorychip.fill")})
                        }
                        Section("Quick Actions") {
                            Button(role: .destructive, action: {
                                Haptic.shared.play(.heavy)
                                do {
                                    try killProcess(Int32(proc["pid"] as! String)!) // idk if i can typecast in one shot
                                } catch {
                                    UIApplication.shared.alert(body: error.localizedDescription)
                                }
                            }) {
                                Label("Kill process", systemImage: "xmark")
                                    .foregroundColor(Color(UIColor.systemRed))
                            }
                            
                            Button(role: .destructive, action: {
                                Haptic.shared.play(.heavy)
                                do {
                                    try kill_priviledged(Int32(proc["pid"] as! String)!) // idk if i can typecast in one shot
                                } catch {
                                    UIApplication.shared.alert(body: error.localizedDescription)
                                }
                            }) {
                                Label("Kill process (root)", systemImage: "xmark")
                                    .foregroundColor(Color(UIColor.systemRed))
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .onTapGesture {
                        Haptic.shared.play(.light)
                    }
                }
            }
        }
    }
}

func getNameFromPID(_ pid: String?) -> String? {
    if let pid {
        guard let procs = try? getProcesses() else { return nil }
        for proc in procs {
            if proc["pid"] as? String == pid {
                if let name = proc["proc_name"] as? String {
                    return "\(name) (\(pid))"
                }
            }
        }
    }
    return nil
}

private func getIcon(_ i: Int) -> String {
    switch i {
    case 0:
        return "info.circle"
    case 1:
        return ""
    default:
        return "ellipsis.circle"
    }
}

struct InfoCell: View {
    public var title: String
    public var value: String
    var body: some View {
        HStack(alignment: .center) {
            Text(title)
                .multilineTextAlignment(.leading)
                .padding(.trailing, 14)
            Spacer()
            // #if canImport(UIKit)
//                MarqueeText(text: value, font: .systemFont(ofSize: UIFont.systemFontSize), leftFade: 16, rightFade: 16, startDelay: 2.0)
//                    .multilineTextAlignment(.trailing)
//                    .textSelection(.enabled)
//                    .foregroundColor(.secondary)
//            #else
            Text(value)
                .multilineTextAlignment(.trailing)
                .font(.body.monospacedDigit())
                .foregroundColor(.secondary)
//            #endif
        }
    }
}
