// bomberfish
// IconView.swift – SwiftTop
// created on 2024-01-29

import SwiftUI

struct Icon: Identifiable {
    var id = UUID()
    var name: String
    var assetCatalogName: String?
    var previewImage: Image
}

struct IconView: View {
    @State var currentIcon: String? = UIApplication.shared.alternateIconName
    var icons: [Icon] = [
        // AppIcon-Beta2 AppIcon-Normal AppIcon-Skeuo AppIcon-Noir
        .init(name: "Default", assetCatalogName: nil, previewImage: .init(systemName: "app.dashed")),
        .init(name: "Original", assetCatalogName: "AppIcon-Normal", previewImage: .init("Normal")),
        .init(name: "TestFlight", assetCatalogName: "AppIcon-Beta2", previewImage: .init("Beta")),
        .init(name: "Noir", assetCatalogName: "AppIcon-Noir", previewImage: .init("Noir")),
        .init(name: "Skeuo", assetCatalogName: "AppIcon-Skeuo", previewImage: .init("Skeuo"))
    ]
    var body: some View {
        List {
            ForEach(icons) {icon in
                Button(action: {
                    Haptic.shared.selection()
                    withAnimation {
                        currentIcon = icon.assetCatalogName
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        UIApplication.shared.setAlternateIconName(icon.assetCatalogName) { (error) in
                            if let error = error {
                                Haptic.shared.notify(.error)
                                UIApplication.shared.alert(body: "Failed request to update the app’s icon: \(error)")
                            } else {
                                Haptic.shared.notify(.success)
                            }
                        }
                        withAnimation {
                            currentIcon = UIApplication.shared.alternateIconName
                        }
                    }
                }) {
                    HStack(spacing: 20) {
                        icon.previewImage
                            .resizable()
                            .frame(width: 48, height: 48)
                            .foregroundColor(.primary)
                            .cornerRadius(12)
                        Text(icon.name)
                            .font(.title2.weight(.semibold))
                            .foregroundColor(.primary)
                        Spacer()
                        if currentIcon == icon.assetCatalogName {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accent)
                        }
                    }
                }
            }
        }
        .navigationTitle("App Icon")
    }
}

#Preview {
    IconView()
}
