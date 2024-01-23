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

    /// 0: none, 1: name, 2: pid
    @AppStorage("procSortType") var sortType = 0
    /// 0: ascending, 1: descending
    @AppStorage("procSortDirection") var sortDirection = 0
    
    @ViewBuilder
    var processNameMenu: some View {
        Menu(content: {
            Button(action: {
                Haptic.shared.selection()
                sortType = 1
                sortDirection = 0
                filterPS()
            }, label: {
                HStack {
                    Label("Ascending", systemImage: "arrow.up")
                    if sortType == 1 && sortDirection == 0 {
                        Image(systemName: "checkmark")
                    }
                }
            })
            Button(action: {
                Haptic.shared.selection()
                sortType = 1
                sortDirection = 1
                filterPS()
            }, label: {
                HStack {
                    Label("Descending", systemImage: "arrow.down")
                    if sortType == 1 && sortDirection == 1 {
                        Image(systemName: "checkmark")
                    }
                }
            })
        }, label: {
            Label("Process Name", systemImage: "terminal")
        })
    }
    
    @ViewBuilder
    var pidMenu: some View {
        Menu(content: {
            Button(action: {
                Haptic.shared.selection()
                sortType = 2
                sortDirection = 0
                filterPS()
            }, label: {
                HStack {
                    Label("Ascending", systemImage: "arrow.up")
                    if sortType == 2 && sortDirection == 0 {
                        Image(systemName: "checkmark")
                    }
                }
            })
            Button(action: {
                Haptic.shared.selection()
                sortType = 2
                sortDirection = 1
                filterPS()
            }, label: {
                HStack {
                    Label("Descending", systemImage: "arrow.down")
                    if sortType == 2 && sortDirection == 1 {
                        Image(systemName: "checkmark")
                    }
                }
            })
        }, label: {
            Label("PID", systemImage: "number")
        })
    }
    
    @ViewBuilder
    var sortMenu: some View {
        Menu(content: {
            Button(action: {
                Haptic.shared.selection()
                sortType = 0
                sortDirection = 0
                filterPS()
            }, label: {
                HStack {
                    Label("None", systemImage: "minus")
                    if sortType == 0 && sortDirection == 0 {
                        Image(systemName: "checkmark")
                    }
                }
            })
            
            processNameMenu
            pidMenu
            
        }, label: {
            Image(systemName: sortType == 0 ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
        })
    }
    
    @ViewBuilder
    var list: some View {
        List {
            Section(content: {
                ForEach(psFiltered, id: \.self) { proc in
                    NavigationLink(destination: ProcessView(proc: proc)) {
                        ProcessCell(proc: proc, titleDisplayMode: $titleDisplayMode)
                            .swipeActions {
                                Button(role: .cancel, action: {
                                    do {
                                        try kill_priviledged(Int32(proc["pid"] as! String)!) // idk if i can typecast in one shot
                                    } catch {
                                        UIApplication.shared.alert(body: error.localizedDescription)
                                    }
                                }) {
                                    Text("Kill as Root")
                                }
                                Button(role: .destructive, action: {
                                    do {
                                        try killProcess(Int32(proc["pid"] as! String)!) // idk if i can typecast in one shot
                                    } catch {
                                        UIApplication.shared.alert(body: error.localizedDescription)
                                    }
                                }) {
                                    Text("Kill")
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
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: titleDisplayMode == 1 ? "Search by executable name, bundle ID, or PID" : "Search by executable name or PID")
    }

    @ViewBuilder
    var toolbarItems: some View {
        HStack {
            if !autoRefresh || forceBtn {
                Button(action: {
                    Task {
                        Haptic.shared.play(.medium)
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
                ToolbarItem(placement: .topBarTrailing) {
                    toolbarItems
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    sortMenu
                }
                #else
                ToolbarItem(placement: .topBarTrailing) {
                    toolbarItems
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    sortMenu
                        .onTapGesture {
                            Haptic.shared.play(.light)
                        }
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
            .onAppear {
                timer = Timer.publish(every: refreshInterval, on: .main, in: .common).autoconnect()
            }
            .onDisappear {
                timer.upstream.connect().cancel()
            }
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
                if titleDisplayMode == 1 {
                    ($0["proc_name"] as! String).localizedCaseInsensitiveContains(searchText) || ($0["pid"] as! String).localizedStandardContains(searchText) || (getAppInfoFromExecutablePath($0["proc_path"] as! String)?.bundleIdentifier.localizedCaseInsensitiveContains(searchText) ?? false)
                } else {
                    ($0["proc_name"] as! String).localizedCaseInsensitiveContains(searchText) || ($0["pid"] as! String).localizedStandardContains(searchText)
                }
            }
        }
        
        switch sortType {
        case 1:
            if sortDirection == 1 {
                psFiltered.sort {
                    ($0["proc_name"] as! String) > ($1["proc_name"] as! String)
                }
            } else {
                psFiltered.sort {
                    ($0["proc_name"] as! String) < ($1["proc_name"] as! String)
                }
            }
        case 2:
            if sortDirection == 1 {
                psFiltered.sort {
                    Int($0["pid"] as! String)! > Int($1["pid"] as! String)!
                }
            } else {
                psFiltered.sort {
                    Int($0["pid"] as! String)! < Int($1["pid"] as! String)!
                }
            }
        default:
            print("not filtering")
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
            
            if app != nil {
                if let iconImage {
                    Image(uiImage: iconImage)
                        .interpolation(.none)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 32, height: 32)
                        .cornerRadius(8)
                } else {
                    Image(systemName: "app.dashed")
                        .foregroundColor(Color(UIColor.label))
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 32, height: 32)
                        .font(.system(size: 32))
                }
            } else {
                Image(systemName: "terminal")
                    .foregroundColor(Color(UIColor.label))
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32, height: 32)
                    .font(.system(size: 24))
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
