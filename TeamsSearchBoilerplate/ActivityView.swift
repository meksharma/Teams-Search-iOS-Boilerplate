import SwiftUI

struct ActivityView: View {
    let onSearch: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            activityHeader
            activityFeed
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.white)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            ActivityTabBar()
        }
    }

    private var activityHeader: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image("ActivityHeaderAvatar")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())

                Text("Activity")
                    .font(.system(size: 26, weight: .bold, design: .default))
                    .kerning(0.33)
                    .foregroundStyle(Color.black)

                Spacer(minLength: 0)

                Button(action: onSearch) {
                    Image("ActivitySearch")
                        .resizable()
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Search")

                Button(action: {}) {
                    Image("ActivityMore")
                        .resizable()
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("More options")
            }
            .padding(.leading, 16)
            .padding(.trailing, 18)
            .frame(height: 48)

            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ActivityFilterPill(title: "Unread")
                    ActivityFilterPill(title: "Mention")
                    ActivityFilterPill(title: "Replies")
                    ActivityFilterPill(title: "Following")
                }
                .padding(.horizontal, 16)
            }
            .scrollIndicators(.hidden)
            .frame(height: 44)
        }
    }

    private var activityFeed: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(ActivityItem.items) { item in
                    ActivityRow(item: item)
                }
            }
        }
        .scrollIndicators(.hidden)
    }
}

private struct ActivityFilterPill: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 15, weight: .medium))
            .kerning(-0.08)
            .foregroundStyle(ActivityColor.textPrimary)
            .padding(.horizontal, 16)
            .frame(height: 32)
            .background(Color.white, in: Capsule())
            .overlay {
                Capsule().stroke(ActivityColor.divider, lineWidth: 1)
            }
    }
}

private struct ActivityItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let caption: String?
    let time: String
    let avatar: String
    let reaction: String?
    let isUnread: Bool

    static let items = [
        ActivityItem(title: "Marie mentioned you", subtitle: "Daniela Mandera Can you check the latest revisions?", caption: "Chat with Marie", time: "4:55 PM", avatar: "ActivityMarie", reaction: nil, isUnread: true),
        ActivityItem(title: "Serena mentioned you", subtitle: "Can you take a look at this latest file?", caption: "Chat with Serena", time: "4:28 PM", avatar: "ActivitySerena", reaction: nil, isUnread: false),
        ActivityItem(title: "Will posted", subtitle: "I’ve attached the file we discussed...", caption: "Van Arsdel > Marketing", time: "3:08 PM", avatar: "ActivityWill", reaction: nil, isUnread: false),
        ActivityItem(title: "Sarah +2 reacted to your message", subtitle: "Any cool sights from your trip?", caption: "Dream Team", time: "3:05 PM", avatar: "ActivitySarah", reaction: "ActivitySarahBadge", isUnread: true),
        ActivityItem(title: "Chris posted an announcement", subtitle: "We’re going live with our latest pro...", caption: "Van Arsdel > General", time: "1:29 PM", avatar: "ActivityChris", reaction: nil, isUnread: true),
        ActivityItem(title: "Darren mentioned Van Arsdel", subtitle: "Hi everyone! This months all hands...", caption: "Metadata", time: "10:41 AM", avatar: "ActivityDarren", reaction: nil, isUnread: false),
        ActivityItem(title: "Voicemail from Aadi", subtitle: "(121) 489-1902", caption: nil, time: "10:35 AM", avatar: "ActivityAadi", reaction: nil, isUnread: false),
        ActivityItem(title: "Keiko reacted to your message", subtitle: "That’s me every afternoon", caption: "Chat with Keiko", time: "9:51 AM", avatar: "ActivityKeiko", reaction: "ActivityKeikoBadge", isUnread: false)
    ]
}

private struct ActivityRow: View {
    let item: ActivityItem

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            avatar

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.system(size: 17, weight: item.isUnread ? .bold : .regular))
                    .kerning(-0.41)
                    .foregroundStyle(ActivityColor.textPrimary)
                    .frame(height: 22)

                Text(item.subtitle)
                    .font(.system(size: 15, weight: .regular))
                    .kerning(-0.08)
                    .foregroundStyle(ActivityColor.textSecondary)
                    .frame(height: 20)

                if let caption = item.caption {
                    Text(caption)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(ActivityColor.textSecondary)
                        .frame(height: 16)
                        .padding(.top, 2)
                }
            }
            .lineLimit(1)
            .truncationMode(.tail)
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(item.time)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(ActivityColor.textSecondary)
                .frame(height: 16, alignment: .top)
        }
        .padding(.leading, 16)
        .padding(.trailing, 12)
        .padding(.vertical, 12)
        .frame(height: 84, alignment: .top)
        .overlay(alignment: .leading) {
            if item.isUnread {
                Circle()
                    .fill(ActivityColor.interactive)
                    .frame(width: 8, height: 8)
                    .offset(x: 4)
            }
        }
    }

    private var avatar: some View {
        ZStack(alignment: .bottomTrailing) {
            Image(item.avatar)
                .resizable()
                .scaledToFill()
                .frame(width: 44, height: 44)
                .clipShape(Circle())

            if let reaction = item.reaction {
                Image(reaction)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 15.385, height: 15.385)
                    .padding(2.308)
                    .background(Color.white, in: Circle())
            }
        }
        .frame(width: 44, height: 44)
    }
}

private struct ActivityTabBar: View {
    private let tabs = [
        ActivityTab(title: "Activity", icon: "ActivityTabAlert", isSelected: true, badge: nil, hasDot: false),
        ActivityTab(title: "Chat", icon: "ActivityTabChat", isSelected: false, badge: "2", hasDot: false),
        ActivityTab(title: "Calendar", icon: "ActivityTabCalendar", isSelected: false, badge: nil, hasDot: false),
        ActivityTab(title: "Calls", icon: "ActivityTabCalls", isSelected: false, badge: nil, hasDot: false),
        ActivityTab(title: "More", icon: "ActivityTabMore", isSelected: false, badge: nil, hasDot: true)
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs) { tab in
                VStack(spacing: 0) {
                    ZStack(alignment: .topTrailing) {
                        Image(tab.icon)
                            .resizable()
                            .frame(width: 24, height: 24)

                        if let badge = tab.badge {
                            Text(badge)
                                .font(.system(size: 11))
                                .foregroundStyle(Color.white)
                                .frame(width: 16, height: 16)
                                .background(ActivityColor.mention, in: Circle())
                                .overlay { Circle().stroke(Color.white, lineWidth: 2) }
                                .offset(x: 8, y: -5)
                        } else if tab.hasDot {
                            Circle()
                                .fill(ActivityColor.mention)
                                .frame(width: 11, height: 11)
                                .offset(x: 8.5, y: -4)
                        }
                    }

                    Text(tab.title)
                        .font(.system(size: 12, weight: .medium))
                        .kerning(0.12)
                        .foregroundStyle(tab.isSelected ? ActivityColor.interactive : ActivityColor.textPrimary)
                        .frame(height: 12)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
            }
        }
        .background(Color.white)
        .overlay(alignment: .top) {
            ActivityColor.divider.frame(height: 0.5)
        }
    }
}

private struct ActivityTab: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let isSelected: Bool
    let badge: String?
    let hasDot: Bool
}

private enum ActivityColor {
    static let textPrimary = Color(red: 33 / 255, green: 33 / 255, blue: 33 / 255)
    static let textSecondary = Color(red: 110 / 255, green: 110 / 255, blue: 110 / 255)
    static let interactive = Color(red: 91 / 255, green: 95 / 255, blue: 199 / 255)
    static let mention = Color(red: 204 / 255, green: 74 / 255, blue: 49 / 255)
    static let divider = Color(red: 225 / 255, green: 225 / 255, blue: 225 / 255)
}

#Preview {
    ActivityView(onSearch: {})
}