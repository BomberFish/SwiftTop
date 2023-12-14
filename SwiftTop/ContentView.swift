// bomberfish
// ContentView.swift – SwiftTop
// created on 2023-12-14

import SwiftUI

struct ContentView: View {
    @State var ps: [NSDictionary]? = sysctl_ps() as? [NSDictionary]
    @State var psFiltered: [NSDictionary] = []
    @AppStorage("autoRefresh") var autoRefresh = true
    @AppStorage("refreshInterval") var refreshInterval = 1.0
    @State private var searchText = ""
    @State var settingsOpen: Bool = false
    var timer = Timer.publish(every: UserDefaults.standard.double(forKey: "refreshInterval"), on: .main, in: .common).autoconnect()
    var body: some View {
        NavigationView {
            Group {
                if ps != nil {
                    List {
                        ForEach(psFiltered, id: \.self) { proc in
                            NavigationLink(destination: ProcessView(proc: proc)) {
                                ProcessCell(proc: proc)
                            }
                        }
                    }
                } else {
                    Text("Error while getting processes.")
                }
            }
            .navigationTitle("SwiftTop")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        if !autoRefresh {
                            Button(action: {
                                ps = sysctl_ps() as? [NSDictionary]
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
            }
            .onChange(of: searchText) {prompt in
                filterPS()
            }
            .onChange(of: ps) {new in
                filterPS()
            }
            .onAppear {
                filterPS()
            }
            .searchable(text: $searchText, prompt: "Search by executable name or PID")
            .sheet(isPresented: $settingsOpen) {
                AboutView()
            }
            .onChange(of: refreshInterval) {new in
                timer.upstream.connect().cancel()
                let _ = timer.upstream.connect()
            }
            .onReceive(timer, perform: { _ in
                if autoRefresh {
                    ps = sysctl_ps() as? [NSDictionary]
                }
            })
        }
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
    ContentView()
}
