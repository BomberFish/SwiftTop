// bomberfish
// AboutView.swift – SwiftTop
// created on 2023-12-14

import CachedAsyncImage
import SwiftUI

struct AboutView: View {
    @AppStorage("autoRefresh") var autoRefresh = true
    @AppStorage("refreshInterval") var refreshInterval = 1.0
    @State var showInterval = UserDefaults.standard.bool(forKey: "autoRefresh")
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
                    Section {
                        Toggle(isOn: $autoRefresh) {
                            Label("Auto-Refresh", systemImage: "arrow.clockwise")
                        }
                        .onChange(of: autoRefresh) { new in
                            withAnimation(.snappy) {
                                showInterval = new
                            }
                        }
                        .tint(.accentColor)
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
                        }
                    } header: { Label("Settings", systemImage: "gear").textCase(nil) }
                    Section {
                        LinkCell(title: "BomberFish", detail: "Author", link: "https://bomberfish.ca", imageURL: "https://bomberfish.ca/misc/pfps/bomberfish-picasso.png")
                        LinkCell(title: "Donato Fiore", detail: "Processes Syscall method", link: "https://github.com/donato-fiore", imageURL: "https://cdn.discordapp.com/avatars/396496265430695947/0904860dfb31d8b1f39f0e7dc4832b1e.webp?size=160")
                    } header: { Label("Credits", systemImage: "heart").textCase(nil) }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        CloseButton()
                    }
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemGroupedBackground))
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
