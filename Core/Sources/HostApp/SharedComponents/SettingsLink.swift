import SwiftUI

struct SettingsLink: View {
    let url: URL
    let title: String
    let subtitle: String?
    let badge: BadgeItem?

    init(
        _ url: URL,
        title: String,
        subtitle: String? = nil,
        badge: BadgeItem? = nil
    ) {
        self.url = url
        self.title = title
        self.subtitle = subtitle
        self.badge = badge
    }

    init(
        url: String,
        title: String,
        subtitle: String? = nil,
        badge: BadgeItem? = nil
    ) {
        self.init(
            URL(string: url)!,
            title: title,
            subtitle: subtitle,
            badge: badge
        )
    }

    var body: some View {
        Link(destination: url) {
            VStack(alignment: .leading) {
                HStack{
                    Text(title).font(.body)
                    if let badge = self.badge {
                        Badge(badgeItem: badge)
                    }
                }
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.footnote)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
        }
        .foregroundStyle(.primary)
        .padding(10)
    }
}

#Preview {
    SettingsLink(
        url: "https://example.com",
        title: "Example",
        subtitle: "This is an example",
        badge: .init(text: "Not Granted", level: .danger)
    )
}
