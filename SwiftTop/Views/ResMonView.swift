// bomberfish
// ResMonView.swift – SwiftTop
// created on 2024-01-09

import Charts
import SwiftUI

struct ResMonView: View {
    @State var cpu = CPU()
    let mem = Memory()
    @State var cpuUsage: (system: Double, user: Double, idle: Double, nice: Double) = (0, 0, 0, 0)
    @State var memUsage: Int64 = 0
    @State var freeMem: Int64 = 0
    let totalMem = Int64(Memory().getTotalMemory())
    @State var cpuChartData: [(type: String, value: Double)] = []
    @State var memChartData: [(type: String, value: Double)] = []
    @State var timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()

    @State var forceOld = false
    let columns = [
        GridItem(.adaptive(minimum: 275))
    ]

    @available(iOS, introduced: 15.0, deprecated: 17.0, message: "ffs use the graphs")
    @ViewBuilder
    var legacy: some View {
        HStack(alignment: .bottom) {
            Text("CPU Usage")
                .font(.title3)
                .padding()
            Spacer()
            Text("\(cpuUsage.user + cpuUsage.system + cpuUsage.nice, specifier: "%.2f")%")
                .font(.headline.weight(.regular))
                .padding()
        }
        ProgressView(value: (cpuUsage.user + cpuUsage.system + cpuUsage.nice) / 100.00)
            .progressViewStyle(.linear)
            .padding()
        HStack(alignment: .bottom) {
            Text("Memory Usage")
                .font(.title3)
                .padding()
            Spacer()
            Text(ByteCountFormatter.string(fromByteCount: memUsage, countStyle: .memory) + "/" + ByteCountFormatter.string(fromByteCount: totalMem, countStyle: .memory))
                .font(.headline.weight(.regular))
                .padding()
        }
        ProgressView(value: Float(memUsage) / Float(totalMem))
            .progressViewStyle(.linear)
            .padding()
    }

    @available(iOS 17.0, *)
    @ViewBuilder
    var graph: some View {
        LazyVGrid(columns: columns, spacing: 20) {
            HStack(alignment: .center, spacing: 20) {
                ZStack {
                    VStack(alignment: .center) {
                        Text("CPU Usage")
                            .font(.title.weight(.heavy))
                            .padding()
                        Text("\(cpuUsage.user + cpuUsage.system + cpuUsage.nice, specifier: "%.2f")%")
                            .font(.headline.weight(.regular))
                            .padding()
                    }
                    .frame(width: 175, height: 175)
                    Chart(cpuChartData, id: \.type) { item in
                        SectorMark(angle: .value("Type", item.value),
                                   innerRadius: .ratio(0.75),
                                   angularInset: 2.5)
                            .cornerRadius(8)
                            .opacity(item.type != "Idle" ? 1 : 0.5)
                            .foregroundStyle(Color(cpuTypeToColor(item.type)))
                    }
                    .padding()
                    .frame(width: 275, height: 275)
                }
                .frame(width: 275, height: 275)
                VStack(alignment: .trailing) {
                    ColorChip(label: "User", color: cpuTypeToColor("User"))
                    ColorChip(label: "Sys", color: cpuTypeToColor("System"))
                    ColorChip(label: "Nice", color: cpuTypeToColor("Nice"))
                    ColorChip(label: "Idle", color: cpuTypeToColor("Idle"))
                }
            }
            HStack(alignment: .center, spacing: 20) {
                ZStack {
                    VStack(alignment: .center) {
                        Text("Memory Usage")
                            .font(.title.weight(.heavy))
                            .padding()
                        Text(ByteCountFormatter.string(fromByteCount: memUsage, countStyle: .memory) + "/" + ByteCountFormatter.string(fromByteCount: totalMem, countStyle: .memory))
                            .font(.headline.weight(.regular))
                            .padding()
                    }
                    .frame(width: 175, height: 175)
                    Chart(memChartData, id: \.type) { item in
                        SectorMark(angle: .value("Type", item.value),
                                   innerRadius: .ratio(0.75),
                                   angularInset: 2.5)
                            .cornerRadius(8)
                            .opacity(item.type != "Free" ? 1 : 0.5)
                            .foregroundStyle(.accent)
                    }
                    .padding()
                    .frame(width: 275, height: 275)
                }
                .frame(width: 275, height: 275)
                VStack(alignment: .trailing) {
                    ColorChip(label: "Used", color: .accent)
                    ColorChip(label: "Free", color: .accent.withAlphaComponent(0.5))
                }
            }
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack {
                    if #available(iOS 17.0, *) {
                        if forceOld {
                            legacy
                        } else {
                            graph
                        }
                    } else {
                        legacy
                    }
                }
            }
            #if DEBUG
            .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: { Haptic.shared.selection(); withAnimation{ forceOld.toggle() } }, label: { Image(systemName: "arrow.2.circlepath") })
                    }
                }
            #endif
            .navigationTitle("Resources")
        }
        .onReceive(timer) { _ in
            withAnimation(.easeInOut(duration: 0.25)) {
                update()
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.75)) {
                update()
            }
        }
        .navigationViewStyle(.stack)
    }

    func cpuTypeToColor(_ s: String) -> UIColor {
        switch s {
        case "User":
            return .systemRed
        case "System":
            return .systemBlue
        case "Nice":
            return .systemGreen
        case "Idle":
            return .systemGray4
        default:
            return .systemGray
        }
    }

    func update() {
        cpuUsage = cpu.usageCPU()
        memUsage = mem.getUsedMemory()
        freeMem = mem.getFreeMemory()
        cpuChartData = [
            (type: "User", cpuUsage.user),
            (type: "System", cpuUsage.system),
            (type: "Nice", cpuUsage.nice),
            (type: "Idle", cpuUsage.idle)
        ]
        memChartData = [
            (type: "Used", Double(memUsage)),
            (type: "Free", Double(totalMem - memUsage))
        ]
    }
}

struct ColorChip: View {
    public var label: String
    public var color: UIColor
    var body: some View {
        HStack {
            Rectangle()
                .fill(Color(color))
                .frame(width: 16, height: 16)
                .cornerRadius(2)
            Text(label)
                .font(.system(size: 15))
        }
    }
}

#Preview {
    ResMonView()
}
