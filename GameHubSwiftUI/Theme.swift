import AppKit
import SwiftUI

enum GHTheme {
    static let background = Color(red: 0.075, green: 0.078, blue: 0.085)
    static let panel = Color.white.opacity(0.055)
    static let panelStrong = Color.white.opacity(0.085)
    static let border = Color.white.opacity(0.10)
    static let text = Color(red: 0.90, green: 0.94, blue: 0.98)
    static let secondary = Color(red: 0.58, green: 0.68, blue: 0.78)
    static let accent = Color(red: 0.45, green: 0.94, blue: 0.82)
    static let blue = Color(red: 0.66, green: 0.81, blue: 0.95)
}

struct AmbientBackground: View {
    var body: some View {
        ZStack {
            GHTheme.background
            GeometryReader { proxy in
                Circle()
                    .fill(Color.orange.opacity(0.16))
                    .frame(width: proxy.size.width * 0.48)
                    .blur(radius: 120)
                    .offset(x: -proxy.size.width * 0.17, y: -proxy.size.height * 0.28)
                Circle()
                    .fill(Color.green.opacity(0.13))
                    .frame(width: proxy.size.width * 0.44)
                    .blur(radius: 130)
                    .offset(x: proxy.size.width * 0.24, y: proxy.size.height * 0.25)
                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: proxy.size.width * 0.42)
                    .blur(radius: 135)
                    .offset(x: proxy.size.width * 0.55, y: proxy.size.height * 0.42)
            }
        }
        .ignoresSafeArea()
    }
}

struct ArtworkImage: View {
    let name: String
    var contentMode: ContentMode = .fill

    var body: some View {
        Group {
            if let image = Self.load(name) {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else {
                Rectangle()
                    .fill(.white.opacity(0.06))
                    .overlay(Image(systemName: "photo").font(.largeTitle).foregroundStyle(.secondary))
            }
        }
    }

    private static func load(_ name: String) -> NSImage? {
        if let image = NSImage(named: name) { return image }
        if let url = Bundle.main.url(forResource: name, withExtension: "jpg") { return NSImage(contentsOf: url) }
        if let url = Bundle.main.url(forResource: name, withExtension: "jpg", subdirectory: "Artwork") { return NSImage(contentsOf: url) }
        return nil
    }
}

extension View {
    func glassPanel(radius: CGFloat = 18) -> some View {
        self
            .background(GHTheme.panel, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(GHTheme.border, lineWidth: 1)
            }
    }
}
