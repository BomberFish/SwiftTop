// bomberfish
// AboutView.swift – SwiftTop
// created on 2023-12-14

//import CachedAsyncImage
import SwiftUI
//import LocalConsole

struct AboutView: View {
    @AppStorage("showConsole") var showConsole = false
    
    @AppStorage("debugMode") var debugMode = false
    @AppStorage("autoRefresh") var autoRefresh = true
    @AppStorage("forceAutoRefreshBtn") var forceBtn = false
    @AppStorage("refreshInterval") var refreshInterval = 1.0
    /// 0: process name, 1: bundle id (when available), 2: app name (when available)
    @AppStorage("titleDisplayMode") var titleDisplayMode = 0
    @AppStorage("iHaveTFP0") var iHaveTFP0 = false
    @State var showInterval = UserDefaults.standard.bool(forKey: "autoRefresh")
    @State var showDebug = UserDefaults.standard.bool(forKey: "debugMode")
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var cs
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    ZStack {
                        Image(systemName: "swift")
                            .font(.system(size: 50))
                            .opacity(cs == .dark ? 0.35 : 0.25)
                        Image(systemName: "waveform.path.ecg")
                            .font(.system(size: 75))
                    }

                    Text("SwiftTop")
                        .font(.system(size: 50).weight(.light))
                }
                .padding(.top, 30)
                Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")")
                    .font(.subheadline)
                List {
                    if showDebug {
                        Section(header: Label("Debug Settings", systemImage: "ladybug.fill")) {
                            NavigationLink("Logs") {
                                LogView()
                            }
                            Button("Attempt to restart SwiftTop as root", action: {
                                let ret = spawnAsRoot(Bundle.main.path(forResource: "SwiftTop", ofType: nil)!, CommandLine.arguments)
                                if (ret != 0) {
                                    UIApplication.shared.alert(body: "ret \(ret)")
                                }
                            })
                            Button("Reset UserDefaults") {
                                UserDefaults.standard.register(defaults: [:])
                            }
                            Toggle("Show LocalConsole", isOn: $showConsole)
                                .onChange(of: showConsole) {_ in
                                    LCManager.shared.isVisible = showConsole
                                }
                                .tint(.accentColor)
                            Toggle("I CAN HAZ TFP0", isOn: $iHaveTFP0)
                                .tint(.accentColor)
                        }
                    }
                    Section {
                        Picker("Process Title", selection: $titleDisplayMode) {
                            Text("Process Name").tag(0)
                            Text("Bundle ID").tag(1)
                            Text("App Name").tag(2)
                        }
                        Toggle(isOn: $autoRefresh) {
                            Label("Auto-Refresh", systemImage: "arrow.clockwise")
                        }
                        .tint(.accentColor)
                        .onChange(of: autoRefresh) { new in
                            withAnimation(.snappy) {
                                showInterval = new
                            }
                        }
                        Toggle(isOn: $debugMode) {
                            Label("Debug Mode", systemImage: "ladybug")
                        }
                        .tint(.accentColor)
                        .onChange(of: debugMode) { new in
                            withAnimation(.snappy) {
                                showDebug = new
                            }
                        }
                        if showInterval {
                            HStack {
                                Image(systemName: "timer")
                                    .foregroundColor(.secondary)
                                Slider(value: $refreshInterval, in: 0.1 ... 3.0, step: 0.1)
                                    .tint(.accentColor)
                                    .onChange(of: refreshInterval) {new in
                                        Haptic.shared.selection()
                                    }
                                Text(String(round(refreshInterval * 10) / 10.0))
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                            Toggle("Show Refresh Button", isOn: $forceBtn)
                                .tint(.accentColor)
                        }
                    } header: { Label("Settings", systemImage: "gear").textCase(nil) }
                    Section {
                        LinkCell(title: "BomberFish", detail: "Author", link: "https://bomberfish.ca", imageURL: "https://bomberfish.ca/misc/pfps/bomberfish-picasso.png")
                        LinkCell(title: "Donato Fiore", detail: "Processes Syscall method, help with bugfixes", link: "https://github.com/donato-fiore", imageURL: "https://cdn.discordapp.com/avatars/396496265430695947/0904860dfb31d8b1f39f0e7dc4832b1e.webp?size=160")
                    } header: { Label("Credits", systemImage: "heart.fill").textCase(nil) }
                }
                .listStyle(.inset)
            }
            .toolbar {
                #if !os(macOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Haptic.shared.play(.light)
                        dismiss()
                    } label: {
                        CloseButton()
                    }
                }
                #else
                ToolbarItem {
                    Button {
                        dismiss()
                    } label: {
                        CloseButton()
                    }
                }
                #endif
            }
//            .background(Color(UIColor.systemGroupedBackground))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemBackground))
    }
}

struct LinkCell: View {
    var title: String
    var detail: String
    var link: String
    var imageURL: String
    var body: some View {
        Link(destination: URL(string: link)!) {
            HStack(alignment: .center) {
                CachedAsyncImage(url: URL(string: imageURL)!) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 32, height: 32)
                        .clipShape(Circle())
                } placeholder: {
                    ZStack {
                        Ellipse()
                            .foregroundColor(.secondary.opacity(0.2))
                            .frame(width: 32, height: 32)
                        ProgressView()
                            .controlSize(.mini)
                    }
                }
                .padding(.trailing, 2)
                VStack(alignment: .leading) {
                    Text(title)
                        .font(.headline)
                    Text(detail)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

enum LogType {
    case regular,error
}

class Log: ObservableObject {
    static let shared = Log()
    @Published var items: [LogItem] = []
}

struct LogItem: Identifiable, Equatable {
    var id = UUID()
    var type: LogType
    var message: String
}

struct LogView: View {
    @ObservedObject var log = Log.shared
    @State var logsCurrent: [LogItem] = []
    @State var paused = false
    @State var searchTerm = ""
    var body: some View {
        ScrollViewReader { sc in
            ScrollView {
                LazyVStack(alignment: .leading) {
                    ForEach(logsCurrent) {item in
                        Text(item.message)
                            .multilineTextAlignment(.leading)
                            .font(.system(size: 15.0, design: .monospaced).weight(.light))
                            .foregroundColor(item.type == .error ? .init(UIColor.systemRed): .init(UIColor.label))
                    }
                }
                .searchable(text: $searchTerm, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search logs")
                .onChange(of: searchTerm) {_ in
                    withAnimation {
                        logsCurrent = log.items.filter({ $0.message.localizedCaseInsensitiveContains(searchTerm) })
                    }
                }
                .onChange(of: log.items) {_ in
                    if !paused {
                        withAnimation {
                            logsCurrent = log.items
                        }
                    }
                    withAnimation {
                        sc.scrollTo(logsCurrent.last!.id)
                    }
                }
                .onAppear {
                    withAnimation {
                        logsCurrent = log.items
                    }
                    if log.items.count > 1 {
                        withAnimation {
                            sc.scrollTo(log.items.last!.id)
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
        
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack {
                    Button(action: {
                        Haptic.shared.play(.light)
                        withAnimation {
                            paused.toggle()
                        }
                    }, label: {
                        Image(systemName: !paused ? "pause.fill" : "play.fill")
                    })
                    Button(action: {
                        Haptic.shared.play(.medium)
                        share([log.items.map {$0.message}.joined(separator: "\n")])
                    }, label: {
                        Image(systemName: "square.and.arrow.up")
                    })
                }
            }
        }
        .navigationTitle("Debug Logs")
    }
}

struct CloseButton: View {
    @Environment(\.colorScheme) var cs
    var body: some View {
        Circle()
            .fill(cs == .dark ? Color(UIColor.secondarySystemGroupedBackground) : Color(UIColor.systemGray).opacity(0.8))
            .frame(width: 26, height: 26)
            .overlay(
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundColor(cs == .dark ? Color(UIColor.label) : Color(UIColor.systemBackground))
            )
    }
}

#Preview {
    AboutView()
}
