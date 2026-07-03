import SwiftUI
import AppKit

private enum AppWindowMetrics {
    static let minimumWidth: CGFloat = 860
    static let minimumHeight: CGFloat = 620
    static let defaultWidth: CGFloat = 1440
    static let defaultHeight: CGFloat = 900

    static var minimumContentSize: NSSize {
        NSSize(width: minimumWidth, height: minimumHeight)
    }
}

@main
struct GameHubSwiftUIApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
                .frame(
                    minWidth: AppWindowMetrics.minimumWidth,
                    maxWidth: .infinity,
                    minHeight: AppWindowMetrics.minimumHeight,
                    maxHeight: .infinity,
                    alignment: .topLeading
                )
                .background(WindowConfigurator(minimumContentSize: AppWindowMetrics.minimumContentSize))
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentMinSize)
        .defaultSize(width: AppWindowMetrics.defaultWidth, height: AppWindowMetrics.defaultHeight)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
    }
}

private struct WindowConfigurator: NSViewRepresentable {
    let minimumContentSize: NSSize

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        DispatchQueue.main.async {
            configure(window: view.window)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            configure(window: nsView.window)
        }
    }

    private func configure(window: NSWindow?) {
        guard let window else { return }

        window.contentMinSize = minimumContentSize
        window.minSize = minimumContentSize

        guard let contentSize = window.contentView?.bounds.size else { return }
        let targetSize = NSSize(
            width: max(contentSize.width, minimumContentSize.width),
            height: max(contentSize.height, minimumContentSize.height)
        )

        if contentSize.width < targetSize.width || contentSize.height < targetSize.height {
            window.setContentSize(targetSize)
        }
    }
}
