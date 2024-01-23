// bomberfish
// RootView.swift – SwiftTop
// created on 2024-01-09

import SwiftUI

struct RootView: View {
    @State var selection = 0
    var body: some View {
        TabView(selection: $selection) {
            MainView()
                .tag(0)
                .tabItem {
                    Label("Processes", systemImage: "list.bullet")
                }
            ResMonView()
                .tag(1)
                .tabItem {
                    Label("Resources", systemImage: "chart.pie")
                }
        }
        .onChange(of: selection) {_ in
            Haptic.shared.play(.heavy)
        }
    }
}

#Preview {
    RootView()
}
