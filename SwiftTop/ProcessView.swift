// bomberfish
// ProcessView.swift – SwiftTop
// created on 2023-12-14

import SwiftUI

struct ProcessView: View {
    public var proc: NSDictionary
    var body: some View {
        List {
            InfoCell(title: "Name", value: proc["proc_name"] as? String ?? "Unknown")
            InfoCell(title: "Path", value: proc["proc_path"] as? String ?? "Unknown")
            InfoCell(title: "PID", value: proc["pid"] as! String)
        }
        .navigationTitle(proc["proc_name"] as? String ?? "Unknown")
    }
}

struct InfoCell: View {
    public var title: String
    public var value: String
    var body: some View {
        HStack {
            Text(title)
                .multilineTextAlignment(.leading)
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
                .textSelection(.enabled)
                .foregroundColor(.secondary)
        }
    }
}
