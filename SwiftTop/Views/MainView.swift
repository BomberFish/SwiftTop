// bomberfish
// ContentView.swift – SwiftTop
// created on 2023-12-14

import SwiftUI

struct MainView: View {
    @State var ps: [NSDictionary] = []
    @State var psFiltered: [NSDictionary] = []
    @AppStorage("autoRefresh") var autoRefresh = true
    @AppStorage("refreshInterval") var refreshInterval = 1.0
    @AppStorage("forceAutoRefreshBtn") var forceBtn = false
    /// 0: process name, 1: bundle id (when available), 2: app name (when available)
    @AppStorage("titleDisplayMode") var titleDisplayMode = 0
    @State private var searchText = ""
    @State var settingsOpen: Bool = false
    @State var timer = Timer.publish(every: UserDefaults.standard.double(forKey: "refreshInterval"), on: .main, in: .common).autoconnect()

    @ViewBuilder
    var list: some View {
        List {
            Section(content: {
                ForEach(psFiltered, id: \.self) { proc in
                    NavigationLink(destination: ProcessView(proc: proc)) {
                        ProcessCell(proc: proc, titleDisplayMode: $titleDisplayMode)
                            .contextMenu {
                                Button(role: .destructive, action: {
                                    do {
                                        try killProcess(Int32(proc["pid"] as! String)!) // idk if i can typecast in one shot
                                    } catch {
                                        UIApplication.shared.alert(body: error.localizedDescription)
                                    }
                                }) {
                                    Label("Kill process", systemImage: "xmark")
                                }

                                Button(role: .destructive, action: {
                                    do {
                                        try TrollStoreRootHelper.kill(pid: Int(proc["pid"] as! String)!) // idk if i can typecast in one shot
                                    } catch {
                                        UIApplication.shared.alert(body: error.localizedDescription)
                                    }
                                }) {
                                    Label("Kill process as root", systemImage: "xmark")
                                }
                            }
                    }
                }
            }, header: {
                Label("\(ps.count) Processes \(searchText.isEmpty ? "" : "(\(psFiltered.count) filtered)")", systemImage: "terminal").textCase(nil)
            })
        }
        .listStyle(.plain)
        .onChange(of: ps) { _ in
            filterPS()
        }
        .onChange(of: searchText) { _ in
            filterPS()
        }
        .onAppear {
            refreshPS()
            filterPS()
        }
        .refreshable {
            ps = []
            refreshPS()
        }
        .searchable(text: $searchText, prompt: "Search by executable name, bundle ID, or PID")
    }

    @ViewBuilder
    var toolbarItems: some View {
        HStack {
            if !autoRefresh || forceBtn {
                Button(action: {
                    Task {
                        Haptic.shared.selection()
                        ps = []
                        refreshPS()
                        Haptic.shared.play(.light)
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                }
            }
            Button(action: {
                Haptic.shared.play(.light)
                settingsOpen = true
            }) {
                Image(systemName: "gear")
            }
        }
    }

    var body: some View {
        NavigationView {
            Group {
                list
            }
            .navigationTitle("SwiftTop")
            .toolbar {
                #if os(macOS)
                ToolbarItem {
                    toolbarItems
                }
                #else
                ToolbarItem(placement: .navigationBarTrailing) {
                    toolbarItems
                }
                #endif
            }
            .sheet(isPresented: $settingsOpen) {
                AboutView()
            }
            .onChange(of: autoRefresh) { new in
                if !new {
                    timer.upstream.connect().cancel()
                } else {
                    timer = Timer.publish(every: refreshInterval, on: .main, in: .common).autoconnect()
                }
            }
            .onChange(of: refreshInterval) { _ in
                timer.upstream.connect().cancel()
                timer = Timer.publish(every: refreshInterval, on: .main, in: .common).autoconnect()
            }
            .onReceive(timer, perform: { _ in
                if autoRefresh {
//                    Haptic.shared.selection()
                    refreshPS()
                }
            })
        }
        #if !os(macOS)
        .navigationViewStyle(StackNavigationViewStyle())
        #endif
    }

    func refreshPS() {
        Task {
            do {
                ps = try getProcesses()
            } catch {
                await UIApplication.shared.alert(body: error.localizedDescription)
            }
        }
    }

    func filterPS() {
        if searchText.isEmpty {
            psFiltered = ps
        } else {
            psFiltered = ps.filter {
                ($0["proc_name"] as! String).localizedCaseInsensitiveContains(searchText) || ($0["pid"] as! String).localizedStandardContains(searchText)
            }
        }
    }
}

struct ProcessCell: View {
    public var proc: NSDictionary
    /// 0: process name, 1: bundle id (when available), 2: app name (when available)
    @Binding public var titleDisplayMode: Int
    var body: some View {
        let name: String = proc["proc_name"] as? String ?? "Unknown"
        let path: String = proc["proc_path"] as! String
        let pid: String = proc["pid"] as! String
        let app: SBApp? = getAppInfoFromExecutablePath(path)
        HStack {
            var iconImage: UIImage? {
//                if let app {
                    if let iconFileName = app?.pngIconPaths[safe: 0] {
                        let iconPath = app!.bundleURL.path + "/" + iconFileName
                        return .init(contentsOfFile: iconPath)
                    } else {
                        return nil
                    }
//                } else {
//                    return nil
//                }
            }
            
            if let app {
                if let iconImage {
                    Image(uiImage: iconImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 30, height: 30)
                        .cornerRadius(6)
                } else {
                    Image(systemName: "app.dashed")
                        .foregroundColor(Color(UIColor.label))
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 30, height: 30)
                        .font(.system(size: 30))
                }
            } else {
                Image(systemName: "terminal")
                    .foregroundColor(Color(UIColor.label))
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 30, height: 30)
                    .font(.system(size: 20))
            }
            VStack(alignment: .leading) {
                Text(app != nil ? (titleDisplayMode == 0 ? name : (titleDisplayMode == 2 ? app!.name : app!.bundleIdentifier)) : name) // ternary black magic
                    .font(.headline)
                    .lineLimit(1)
                Text(path)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .font(.callout)
            }
            Spacer()
            Text(pid)
                .foregroundColor(.secondary)
                .font(.system(.callout, design: .monospaced))
        }
    }
}

#Preview {
    MainView()
}
