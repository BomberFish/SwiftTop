// bomberfish
// ProcessView.swift – SwiftTop
// created on 2023-12-14

import SwiftUI
#if canImport(UIKit)
import MarqueeText
#endif

struct ProcessView: View {
    public var proc: NSDictionary
    var body: some View {
        List {
            Section("General Info") {
                InfoCell(title: "Name", value: proc["proc_name"] as? String ?? "Unknown")
                InfoCell(title: "Path", value: proc["proc_path"] as? String ?? "Unknown")
                InfoCell(title: "PID", value: proc["pid"] as! String)
            }
            
            Section("Quick Actions") {
                Button(role: .destructive, action: {
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
                    killall(proc["proc_name"] as? String)
                }) {
                    Label("Kill process by process name", systemImage: "xmark")
                        .foregroundColor(Color(UIColor.systemRed))
                }

                Button(role: .destructive, action: {
                    do {
                        try TrollStoreRootHelper.kill(pid: Int(proc["pid"] as! String)!) // idk if i can typecast in one shot
                    } catch {
                        UIApplication.shared.alert(body: error.localizedDescription)
                    }
                }) {
                    Label("Kill process (root)", systemImage: "xmark")
                        .foregroundColor(Color(UIColor.systemRed))
                }
                
                Button(role: .destructive, action: {
                    do {
                        try TrollStoreRootHelper.pkill(proc: proc["proc_name"] as! String)
                    } catch {
                        UIApplication.shared.alert(body: error.localizedDescription)
                    }
                }) {
                    Label("Kill process by process name (root)", systemImage: "xmark")
                        .foregroundColor(Color(UIColor.systemRed))
                }
            }
        }
        .navigationTitle(proc["proc_name"] as? String ?? "Unknown")
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
