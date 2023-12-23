// bomberfish
// ProcessView.swift – SwiftTop
// created on 2023-12-14

import SwiftUI
#if canImport(UIKit)
import MarqueeText
#endif

struct ProcessView: View {
    public var proc: NSDictionary
    @State private var openedSections: [Bool] = [true, true, false, false, false, false]
    @State var loadedModules: [String] = []
    var body: some View {
        List {
            DisclosureGroup("Info", isExpanded: $openedSections[0]) {
                Section("Basic Info") {
                    InfoCell(title: "Name", value: proc["proc_name"] as? String ?? "Unknown")
                    InfoCell(title: "Path", value: proc["proc_path"] as? String ?? "Unknown")
                    InfoCell(title: "PID", value: proc["pid"] as! String)
                }
                
                Section("Advanced Info") {
                    InfoCell(title: "Executable type", value: parseMachO(proc["pid"] as! String)?.rawValue ?? "Unknown")
                }
            }
            
            DisclosureGroup("Quick Actions", isExpanded: $openedSections[1]) {
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
            
//            DisclosureGroup("Threads", isExpanded: $openedSections[2]) {
//                
//            } .onTapGesture {
//                openSection(2)
//            }
//            
//            DisclosureGroup("Open files", isExpanded: $openedSections[3]) {
//                
//            } .onTapGesture {
//                openSection(3)
//            }
//            
//            DisclosureGroup("Open ports", isExpanded: $openedSections[4]) {
//                
//            } .onTapGesture {
//                openSection(4)
//            }
//            
//            DisclosureGroup("Mapped modules", isExpanded: $openedSections[5]) {
//                
//            } .onTapGesture {
//                openSection(5)
//            }
            
        }
        .onAppear {
//            loadedModules = getLoadedModules(Int32(proc["pid"] as! String)!)
        }
//        .headerProminence(.increased)
        .listStyle(.plain)
        .navigationTitle(proc["proc_name"] as? String ?? "Unknown")
    }
    func openSection(_ index: Int) {
        withAnimation(.snappy) {
            openedSections = [Bool](repeating: false, count: openedSections.count)
            openedSections = [Bool](repeating: false, count: openedSections.count)
            openedSections[index] = true
        }
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
#if canImport(UIKit)
                MarqueeText(text: value, font: .systemFont(ofSize: UIFont.systemFontSize), leftFade: 16, rightFade: 16, startDelay: 2.0)
                    .multilineTextAlignment(.trailing)
                    .textSelection(.enabled)
                    .foregroundColor(.secondary)
            #else
                Text(value)
                    .multilineTextAlignment(.trailing)
                    .foregroundColor(.secondary)
            #endif
        }
    }
}
