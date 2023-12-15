// bomberfish
// ContentView.swift – SwiftTop
// created on 2023-12-14

import SwiftUI

struct MainView: View {
    @State var ps: [NSDictionary]? = sysctl_ps() as? [NSDictionary]
    @State var psFiltered: [NSDictionary] = []
    @AppStorage("autoRefresh") var autoRefresh = true
    @AppStorage("refreshInterval") var refreshInterval = 1.0
    @AppStorage("forceAutoRefreshBtn") var forceBtn = false
    @State private var searchText = ""
    @State var settingsOpen: Bool = false
    var timer = Timer.publish(every: UserDefaults.standard.double(forKey: "refreshInterval"), on: .main, in: .common).autoconnect()

    @ViewBuilder
    var list: some View {
        if ps != nil {
            List {
                ForEach(psFiltered, id: \.self) { proc in
                    NavigationLink(destination: ProcessView(proc: proc)) {
                        ProcessCell(proc: proc)
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
            }
            .onChange(of: ps) { _ in
                filterPS()
            }
            .onChange(of: searchText) { _ in
                filterPS()
            }
            .onAppear {
                filterPS()
            }
            .refreshable {
                ps = []
                ps = sysctl_ps() as? [NSDictionary]
            }
            .searchable(text: $searchText, prompt: "Search by executable name or PID")
        } else {
            Text("Error while getting processes.")
        }
    }

    @ViewBuilder
    var toolbarItems: some View {
        HStack {
            if !autoRefresh || forceBtn {
                Button(action: {
                    Haptic.shared.selection()
                    ps = []
                    ps = sysctl_ps() as? [NSDictionary]
                    Haptic.shared.play(.light)
                }) {
                    Image(systemName: "arrow.clockwise")
                }
            }
            Button(action: {
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
            .onChange(of: autoRefresh) {new in
                if !new {
                    timer.upstream.connect().cancel()
                }
            }
            .onChange(of: refreshInterval) { _ in
                timer.upstream.connect().cancel()
                let _ = timer.upstream.connect()
            }
            .onReceive(timer, perform: { _ in
                if autoRefresh {
                    Haptic.shared.selection()
                    ps = sysctl_ps() as? [NSDictionary]
                }
            })
        }
        #if !os(macOS)
        .navigationViewStyle(StackNavigationViewStyle())
        #endif
    }

    func filterPS() {
        if searchText.isEmpty {
            psFiltered = ps ?? []
        } else {
            psFiltered = ps?.filter {
                ($0["proc_name"] as! String).localizedCaseInsensitiveContains(searchText) || ($0["pid"] as! String).localizedStandardContains(searchText)
            } ?? (ps ?? [])
        }
    }
}

struct ProcessCell: View {
    var proc: NSDictionary
    var body: some View {
        HStack {
            Image(systemName: "apple.terminal")
            VStack(alignment: .leading) {
                Text(proc["proc_name"] as? String ?? "Unknown")
                Text(proc["proc_path"] as? String ?? "Unknown")
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .font(.footnote)
            }
            Spacer()
            Text(proc["pid"] as! String)
                .foregroundColor(.secondary)
                .font(.callout)
        }
    }
}

#Preview {
    MainView()
}
