// bomberfish
// LogsView.swift – SwiftTop
// created on 2024-01-29

import SwiftUI

enum LogType {
    case regular, error
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

struct LogsView: View {
    @ObservedObject var log = Log.shared
    @State var logsCurrent: [LogItem] = []
    @State var paused = false
    @State var searchTerm = ""
    var body: some View {
        ScrollViewReader { sc in
            ScrollView {
                LazyVStack(alignment: .leading) {
                    ForEach(logsCurrent) { item in
                        Text(item.message)
                            .multilineTextAlignment(.leading)
                            .font(.system(size: 13.0, design: .monospaced).weight(.light))
                            .foregroundColor(item.type == .error ? .init(UIColor.systemRed) : .init(UIColor.label))
                            .padding(.horizontal)
                    }
                }
                .searchable(text: $searchTerm, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search logs")
                .onChange(of: searchTerm) { _ in
                    withAnimation {
                        logsCurrent = log.items.filter { $0.message.localizedCaseInsensitiveContains(searchTerm) }
                    }
                }
                .onChange(of: log.items) { _ in
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
                        if log.items.count > 1 {
                           sc.scrollTo(log.items.last!.id)
                        }
                    }
                }
            }
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
                        share([log.items.map { $0.message }.joined(separator: "\n")])
                    }, label: {
                        Image(systemName: "square.and.arrow.up")
                    })
                }
            }
        }
        .navigationTitle("Debug Logs")
    }
}

#Preview {
    LogsView()
}
