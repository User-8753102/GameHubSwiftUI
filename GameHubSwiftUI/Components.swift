import SwiftUI

struct Sidebar: View {
    let selected: AppPage?
    let navigate: (AppRoute) -> Void
    let showSearch: () -> Void

    private let railWidth: CGFloat = 86
    private let buttonSize: CGFloat = 50
    private let mainPages: [AppPage] = [.home, .rankings, .browse, .library]

    var body: some View {
        VStack(spacing: 8) {
            Image("tray")
                .resizable()
                .renderingMode(.template)
                .scaledToFit()
                .foregroundStyle(.white)
                .frame(width: 27, height: 27)
                .padding(.bottom, 26)

            ForEach(mainPages) { page in
                sidebarButton(page)
            }

            Spacer()

            iconButton(symbol: "magnifyingglass", selected: false, action: showSearch)
            iconButton(symbol: AppPage.downloads.symbol, selected: selected == .downloads) {
                navigate(.page(.downloads))
            }
            iconButton(symbol: AppPage.settings.symbol, selected: selected == .settings) {
                navigate(.page(.settings))
            }
        }
        .padding(.vertical, 42)
        .frame(minWidth: railWidth, idealWidth: railWidth, maxWidth: railWidth, maxHeight: .infinity)
        .fixedSize(horizontal: true, vertical: false)
        .layoutPriority(1000)
        .background(Color.white.opacity(0.025))
        .overlay(alignment: .trailing) { Rectangle().fill(Color.white.opacity(0.06)).frame(width: 1) }
        .transaction { transaction in
            transaction.animation = nil
        }
    }

    private func sidebarButton(_ page: AppPage) -> some View {
        iconButton(symbol: page.symbol, selected: selected == page) {
            navigate(.page(page))
        }
    }

    private func iconButton(symbol: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(selected ? .white : .white.opacity(0.62))
                .frame(width: buttonSize, height: buttonSize)
                .background(selected ? Color.white.opacity(0.12) : .clear, in: RoundedRectangle(cornerRadius: 14))
                .overlay {
                    if selected {
                        RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.12))
                    }
                }
                .frame(width: railWidth)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(symbol)
    }
}

struct PageTitle: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.system(size: 36, weight: .heavy, design: .rounded))
            .foregroundStyle(GHTheme.text)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct CapsuleButton: View {
    let title: String
    var symbol: String?
    var primary = false
    var action: () -> Void = { }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 9) {
                if let symbol { Image(systemName: symbol) }
                Text(title)
            }
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(primary ? .black : GHTheme.blue)
            .padding(.horizontal, 20)
            .frame(height: 42)
            .background(primary ? Color.white : Color.white.opacity(0.065), in: RoundedRectangle(cornerRadius: 14))
            .overlay { RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.10)) }
        }
        .buttonStyle(.plain)
    }
}

struct GameCard: View {
    let game: Game
    var compact = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: compact ? 7 : 10) {
                ArtworkImage(name: game.artwork)
                    .frame(maxWidth: .infinity)
                    .aspectRatio(1.72, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
                    .overlay { RoundedRectangle(cornerRadius: 17).stroke(Color.white.opacity(0.09)) }
                HStack(alignment: .firstTextBaseline) {
                    Text(game.name)
                        .font(.system(size: compact ? 15 : 17, weight: .bold))
                        .foregroundStyle(GHTheme.text)
                        .lineLimit(1)
                    Spacer()
                    if !compact {
                        Text(game.score)
                            .font(.system(size: 18, weight: .heavy, design: .rounded))
                            .foregroundStyle(GHTheme.accent)
                    }
                }
                if !compact {
                    Text(game.genres + "  ·  ◉")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(GHTheme.secondary)
                        .lineLimit(1)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct SearchOverlay: View {
    @Binding var isPresented: Bool
    @State private var query = "Baldur's Gate 3"
    private let suggestions = ["Baldur's Gate 3", "Cyberpunk 2077", "Slay the Spire 2", "Valheim", "SILENT HILL f", "Little Nightmares II", "Terraria", "God of War Ragnarök", "Satisfactory", "Stardew Valley"]

    var body: some View {
        ZStack {
            Color.black.opacity(0.62)
                .background(.ultraThinMaterial)
                .ignoresSafeArea()
                .onTapGesture { isPresented = false }

            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    TextField("Search", text: $query)
                        .textFieldStyle(.plain)
                        .font(.title3)
                        .onSubmit { isPresented = false }
                }
                .padding(20)

                Divider().opacity(0.5)

                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("Recommended games").font(.headline)
                        Spacer()
                        Label("Refresh", systemImage: "arrow.clockwise").foregroundStyle(.secondary)
                    }
                    FlowLayout(spacing: 9) {
                        ForEach(suggestions, id: \.self) { suggestion in
                            Button(suggestion) { query = suggestion }
                                .buttonStyle(.plain)
                                .padding(.horizontal, 13)
                                .padding(.vertical, 6)
                                .background(Color.white.opacity(0.10), in: Capsule())
                        }
                    }
                }
                .padding(20)
            }
            .frame(width: 620)
            .glassPanel(radius: 18)
            .shadow(color: .black.opacity(0.5), radius: 40)
        }
        .transition(.opacity)
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(proposal: proposal, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, point) in result.points.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + point.x, y: bounds.minY + point.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, points: [CGPoint]) {
        let maxWidth = proposal.width ?? 600
        var x: CGFloat = 0
        var y: CGFloat = 0
        var lineHeight: CGFloat = 0
        var points: [CGPoint] = []
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += lineHeight + spacing
                lineHeight = 0
            }
            points.append(CGPoint(x: x, y: y))
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
        return (CGSize(width: maxWidth, height: y + lineHeight), points)
    }
}
