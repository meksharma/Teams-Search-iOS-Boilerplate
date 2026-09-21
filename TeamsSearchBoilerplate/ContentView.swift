import SwiftUI

struct ContentView: View {
    let onDismiss: () -> Void
    private let automatedQuery: String?

    @State private var query = ""
    @State private var selectedFilter: SearchFilter?
    @State private var isLoadingResults = false
    @State private var filterLoadTask: Task<Void, Never>?
    @FocusState private var isSearchFocused: Bool

    init(automatedQuery: String? = nil, onDismiss: @escaping () -> Void) {
        self.automatedQuery = automatedQuery
        self.onDismiss = onDismiss
    }

    var body: some View {
        VStack(spacing: 0) {
            searchHeader

            if query.isEmpty {
                zeroQueryContent
            } else {
                filterBar
                searchResults
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.white)
        .preferredColorScheme(.light)
        .task {
            await Task.yield()
            try? await Task.sleep(nanoseconds: 150_000_000)
            guard !Task.isCancelled else { return }
            isSearchFocused = true

            if let automatedQuery {
                try? await Task.sleep(nanoseconds: 450_000_000)
                for character in automatedQuery {
                    guard !Task.isCancelled else { return }
                    query.append(character)
                    try? await Task.sleep(nanoseconds: 500_000_000)
                }
            }
        }
        .onChange(of: query) { _, newValue in
            if newValue.isEmpty {
                filterLoadTask?.cancel()
                selectedFilter = nil
                isLoadingResults = false
            }
        }
        .onDisappear {
            filterLoadTask?.cancel()
        }
    }

    private var searchHeader: some View {
        HStack(spacing: 12) {
            HStack(spacing: 16) {
                Image("SearchIcon")
                    .resizable()
                    .frame(width: 20, height: 20)

                TextField("Search", text: $query)
                    .focused($isSearchFocused)
                    .font(.system(size: 17))
                    .foregroundStyle(TeamsColor.textPrimary)
                    .tint(TeamsColor.interactive)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.search)

                Button {
                    if query.isEmpty {
                        isSearchFocused = false
                        onDismiss()
                    } else {
                        query = ""
                        isSearchFocused = true
                    }
                } label: {
                    Image("DismissIcon")
                        .resizable()
                        .frame(width: 20, height: 20)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(query.isEmpty ? "Dismiss search" : "Clear search")
            }
            .padding(.horizontal, 16)
            .frame(height: 36)
            .background(TeamsColor.raisedFill, in: RoundedRectangle(cornerRadius: 10))
            .contentShape(RoundedRectangle(cornerRadius: 10))
            .simultaneousGesture(
                TapGesture().onEnded {
                    isSearchFocused = true
                }
            )

            if !query.isEmpty {
                Button("Cancel") {
                    query = ""
                    selectedFilter = nil
                    isSearchFocused = true
                }
                .buttonStyle(.plain)
                .font(.system(size: 17))
                .foregroundStyle(TeamsColor.textSecondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
        .padding(.bottom, 8)
    }

    private var zeroQueryContent: some View {
        ScrollView {
            VStack(spacing: 0) {
                avatarCarousel

                ForEach(ZeroQueryItem.items) { item in
                    Button {
                        if let query = item.query {
                            self.query = query
                        }
                    } label: {
                        ZeroQueryRow(item: item)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .scrollIndicators(.hidden)
    }

    private var avatarCarousel: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 0) {
                ForEach(CarouselPerson.people) { person in
                    VStack(spacing: 6) {
                        Image(person.image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 52, height: 52)
                            .clipShape(Circle())

                        Text(person.name)
                            .font(.system(size: 11))
                            .foregroundStyle(TeamsColor.textPrimary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .frame(height: 32, alignment: .top)
                    }
                    .frame(width: 84, height: 108)
                    .padding(.top, 8)
                }
            }
        }
        .scrollIndicators(.hidden)
    }

    private var filterBar: some View {
        HStack(spacing: 8) {
            ForEach(SearchFilter.allCases) { filter in
                Button {
                    select(filter)
                } label: {
                    Text(filter.rawValue)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(selectedFilter == filter ? Color.white : TeamsColor.textPrimary)
                        .padding(.horizontal, 12)
                        .frame(height: 32)
                        .background(
                            selectedFilter == filter ? TeamsColor.interactive : TeamsColor.raisedFill,
                            in: Capsule()
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .frame(height: 44)
        .padding(.horizontal, 16)
    }

    private var searchResults: some View {
        Group {
            if isLoadingResults {
                Color.clear
            } else if automatedQuery != nil && selectedFilter == nil {
                PortfolioSearchResults(query: query)
            } else if selectedFilter == .messages {
                MessageSearchResults(query: query)
            } else if selectedFilter == .channels {
                ChannelSearchResults(query: query)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(results) { result in
                            SearchResultRow(result: result, query: query)
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var results: [SearchResult] {
        switch selectedFilter {
        case .people:
            SearchResult.people
        case .messages:
            SearchResult.messages
        case .files:
            SearchResult.files
        case .channels:
            SearchResult.channels
        case nil:
            SearchResult.mixed
        }
    }

    private func select(_ filter: SearchFilter) {
        filterLoadTask?.cancel()
        selectedFilter = filter
        isLoadingResults = true
        isSearchFocused = true

        filterLoadTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            isLoadingResults = false
        }
    }
}

private struct PortfolioSuggestion: Identifiable {
    enum Kind {
        case person(String)
        case feature
        case channel(String)
        case group
        case history
    }

    let id: String
    let title: String
    let subtitle: String
    let kind: Kind
    let queryStages: Set<String>

    static let all = [
        PortfolioSuggestion(id: "suchitra", title: "Suchitra Mohan", subtitle: "Senior content designer", kind: .person("ActivitySarah"), queryStages: ["s", "su"]),
        PortfolioSuggestion(id: "sue", title: "Sue Grimshaw", subtitle: "Senior product manager", kind: .person("ActivityKeiko"), queryStages: ["s", "su"]),
        PortfolioSuggestion(id: "sq-summarize", title: "SQ - Summarize", subtitle: "Outlook Team", kind: .feature, queryStages: ["s", "su", "sum", "summ"]),
        PortfolioSuggestion(id: "studio", title: "Studio 8 All", subtitle: "Summer, Abby, Alex + 90", kind: .channel("StudioVAIcon"), queryStages: ["s", "su", "sum", "summ"]),
        PortfolioSuggestion(id: "summer", title: "Summer Xuan", subtitle: "Senior product designer", kind: .person("ActivitySerena"), queryStages: ["sum", "summ"]),
        PortfolioSuggestion(id: "copilot-card", title: "Summarize Copilot Card", subtitle: "Caleb, Cookie, Colin + 17", kind: .group, queryStages: ["sum", "summ"]),
        PortfolioSuggestion(id: "research", title: "summarize research", subtitle: "Recent search", kind: .history, queryStages: ["summ"])
    ]
}

private struct PortfolioSearchResults: View {
    let query: String

    private var suggestions: [PortfolioSuggestion] {
        let normalized = query.lowercased()
        return PortfolioSuggestion.all.filter { $0.queryStages.contains(normalized) }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(suggestions) { suggestion in
                    PortfolioSuggestionRow(suggestion: suggestion, query: query)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .animation(.easeOut(duration: 0.22), value: query)
        }
        .scrollIndicators(.hidden)
    }
}

private struct PortfolioSuggestionRow: View {
    let suggestion: PortfolioSuggestion
    let query: String

    var body: some View {
        HStack(spacing: 14) {
            artwork
                .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                highlightedTitle
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(TeamsColor.textPrimary)
                    .lineLimit(1)

                Text(suggestion.subtitle)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(TeamsColor.textSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 20)
        .frame(height: 58)
    }

    @ViewBuilder
    private var artwork: some View {
        switch suggestion.kind {
        case .person(let image):
            Image(image)
                .resizable()
                .scaledToFill()
                .clipShape(Circle())
        case .feature:
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(TeamsColor.interactive)
                Image("CalendarIcon")
                    .resizable()
                    .frame(width: 16, height: 16)
            }
        case .channel(let image):
            Image(image)
                .resizable()
                .scaledToFit()
        case .group:
            Image("GroupAvatar")
                .resizable()
                .scaledToFill()
                .clipShape(Circle())
        case .history:
            Image("HistoryIcon")
                .resizable()
                .scaledToFit()
        }
    }

    private var highlightedTitle: Text {
        guard
            !query.isEmpty,
            let range = suggestion.title.range(of: query, options: .caseInsensitive)
        else {
            return Text(suggestion.title)
        }

        return Text(String(suggestion.title[..<range.lowerBound]))
            + Text(String(suggestion.title[range])).bold()
            + Text(String(suggestion.title[range.upperBound...]))
    }
}

private struct MessageSearchResult: Identifiable {
    let id = UUID()
    let sender: String
    let time: String
    let avatar: String
    let source: String
    let sourceIcon: String?
    let snippet: String

    static let items = [
        MessageSearchResult(
            sender: "Lisa Phillips",
            time: "Monday",
            avatar: "LisaPhillips",
            source: "STCA Design",
            sourceIcon: "CalendarIcon",
            snippet: "Weekly briefing — Sep 14. Top of mind: advance the iPad chat ship readiness through design alignment..."
        ),
        MessageSearchResult(
            sender: "Lina Chung",
            time: "Wednesday",
            avatar: "LinaChung",
            source: "Vibe coding community > General",
            sourceIcon: nil,
            snippet: "Hi Lisa, the team is starting the next review Monday. This channel now has the latest files and notes..."
        ),
        MessageSearchResult(
            sender: "Alina Lin",
            time: "Monday",
            avatar: "AlinaLin",
            source: "Studio VA",
            sourceIcon: nil,
            snippet: "Posted the new prototype for the search experience. The interaction details and updated states are ready..."
        ),
        MessageSearchResult(
            sender: "Lisa Larsson",
            time: "Monday",
            avatar: "LisaLarsson",
            source: "Studio VA > Design",
            sourceIcon: nil,
            snippet: "Here it is. I’m sharing one more option for the message results so we can compare the hierarchy..."
        )
    ]
}

private struct MessageSearchResults: View {
    let query: String

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(MessageSearchResult.items) { item in
                    MessageSearchResultRow(item: item, query: query)
                }

                Button(action: {}) {
                    Text("View all messages")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(TeamsColor.interactive)
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                }
                .buttonStyle(.plain)
                .overlay(alignment: .top) {
                    Color(red: 225 / 255, green: 225 / 255, blue: 225 / 255)
                        .frame(height: 0.5)
                }
            }
        }
        .scrollIndicators(.hidden)
    }
}

private struct MessageSearchResultRow: View {
    let item: MessageSearchResult
    let query: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                Image(item.avatar)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())

                Circle()
                    .fill(Color(red: 216 / 255, green: 32 / 255, blue: 45 / 255))
                    .frame(width: 13, height: 13)
                    .overlay { Circle().stroke(Color.white, lineWidth: 2) }
                    .offset(x: 2, y: 2)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .firstTextBaseline) {
                    highlighted(item.sender)
                        .font(.system(size: 17, weight: .regular))
                        .foregroundStyle(TeamsColor.textPrimary)
                        .lineLimit(1)

                    Spacer(minLength: 8)

                    Text(item.time)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(TeamsColor.textSecondary)
                }

                HStack(spacing: 6) {
                    if let sourceIcon = item.sourceIcon {
                        Image(sourceIcon)
                            .resizable()
                            .frame(width: 16, height: 16)
                            .frame(width: 20, height: 20)
                            .background(TeamsColor.interactive, in: Circle())
                    } else {
                        Image(systemName: "person.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(Color.white)
                            .frame(width: 20, height: 20)
                            .background(Color(red: 225 / 255, green: 225 / 255, blue: 225 / 255), in: Circle())
                    }

                    Text(item.source)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(TeamsColor.textSecondary)
                        .lineLimit(1)
                }

                highlighted(item.snippet)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(TeamsColor.textSecondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(minHeight: 126, alignment: .top)
    }

    private func highlighted(_ value: String) -> Text {
        guard
            !query.isEmpty,
            let range = value.range(of: query, options: .caseInsensitive)
        else {
            return Text(value)
        }

        return Text(String(value[..<range.lowerBound]))
            + Text(String(value[range])).bold()
            + Text(String(value[range.upperBound...]))
    }
}

private struct ChannelSearchResult: Identifiable {
    enum Artwork {
        case teams
        case linkedIn
        case outlook
        case initials(String, Color, Color)
    }

    let id = UUID()
    let name: String
    let organization: String?
    let artwork: Artwork

    static let items = [
        ChannelSearchResult(name: "FC - PSTN Lite", organization: "Teams Consumer", artwork: .teams),
        ChannelSearchResult(name: "LinkedIn", organization: "Microsoft Design", artwork: .linkedIn),
        ChannelSearchResult(name: "Livesite", organization: "Teams Consumer", artwork: .teams),
        ChannelSearchResult(name: "Livesite - Teams MSA (Test)", organization: "Teams Consumer", artwork: .teams),
        ChannelSearchResult(name: "om-idc-live-support", organization: "Outlook Mobile", artwork: .outlook),
        ChannelSearchResult(
            name: "Personal OS - Live Site",
            organization: "Outlook Team",
            artwork: .initials("OT", Color(red: 247 / 255, green: 232 / 255, blue: 196 / 255), Color(red: 126 / 255, green: 92 / 255, blue: 28 / 255))
        ),
        ChannelSearchResult(
            name: "Suzhou Life",
            organization: nil,
            artwork: .initials("SL", Color(red: 226 / 255, green: 47 / 255, blue: 0), Color.white)
        )
    ]
}

private struct ChannelSearchResults: View {
    let query: String

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(ChannelSearchResult.items) { item in
                    ChannelSearchResultRow(item: item, query: query)
                }

                Button(action: {}) {
                    Text("View all channels")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(TeamsColor.interactive)
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                }
                .buttonStyle(.plain)
                .overlay(alignment: .top) {
                    Color(red: 225 / 255, green: 225 / 255, blue: 225 / 255)
                        .frame(height: 0.5)
                }
            }
        }
        .scrollIndicators(.hidden)
    }
}

private struct ChannelSearchResultRow: View {
    let item: ChannelSearchResult
    let query: String

    var body: some View {
        HStack(spacing: 12) {
            artwork
                .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 2) {
                highlightedName
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(TeamsColor.textPrimary)
                    .lineLimit(1)

                if let organization = item.organization {
                    Text(organization)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(TeamsColor.textSecondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .frame(height: 64)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var artwork: some View {
        switch item.artwork {
        case .teams:
            Image("TeamsLoader")
                .resizable()
                .scaledToFit()
                .padding(6)
                .background(Color(red: 241 / 255, green: 240 / 255, blue: 1), in: RoundedRectangle(cornerRadius: 6))
        case .linkedIn:
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(red: 37 / 255, green: 41 / 255, blue: 48 / 255))
                Image(systemName: "link")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color(red: 74 / 255, green: 215 / 255, blue: 255 / 255))
            }
        case .outlook:
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(red: 0, green: 120 / 255, blue: 212 / 255))
                Image(systemName: "envelope.fill")
                    .font(.system(size: 19))
                    .foregroundStyle(Color.white)
            }
        case .initials(let initials, let background, let foreground):
            Text(initials)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(foreground)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(background, in: RoundedRectangle(cornerRadius: 4))
        }
    }

    private var highlightedName: Text {
        guard
            !query.isEmpty,
            let range = item.name.range(of: query, options: .caseInsensitive)
        else {
            return Text(item.name)
        }

        return Text(String(item.name[..<range.lowerBound]))
            + Text(String(item.name[range])).bold()
            + Text(String(item.name[range.upperBound...]))
    }
}

private enum TeamsColor {
    static let textPrimary = Color(red: 33 / 255, green: 33 / 255, blue: 33 / 255)
    static let textSecondary = Color(red: 110 / 255, green: 110 / 255, blue: 110 / 255)
    static let raisedFill = Color(red: 241 / 255, green: 241 / 255, blue: 241 / 255)
    static let interactive = Color(red: 91 / 255, green: 95 / 255, blue: 199 / 255)
}

private enum SearchFilter: String, CaseIterable, Identifiable {
    case people = "People"
    case messages = "Messages"
    case files = "Files"
    case channels = "Channels"

    var id: Self { self }
}

private struct CarouselPerson: Identifiable {
    let id = UUID()
    let name: String
    let image: String

    static let people = [
        CarouselPerson(name: "Lisa\nPhillips", image: "CarouselLisa"),
        CarouselPerson(name: "Aadi\nChopra", image: "CarouselAadi"),
        CarouselPerson(name: "Lisa\nLarsson", image: "CarouselLarsson"),
        CarouselPerson(name: "Joan\nFeller", image: "CarouselJoan"),
        CarouselPerson(name: "Elvia\nAtkins", image: "CarouselElvia")
    ]
}

private struct ZeroQueryItem: Identifiable {
    enum Kind {
        case team(TeamArtwork)
        case history
        case file
    }

    enum TeamArtwork {
        case stca
        case studioVA
        case vibe
    }

    let id = UUID()
    let title: String
    let kind: Kind
    let query: String?

    static let items = [
        ZeroQueryItem(title: "STCA Design", kind: .team(.stca), query: nil),
        ZeroQueryItem(title: "Studio VA", kind: .team(.studioVA), query: nil),
        ZeroQueryItem(title: "Vibe coding community", kind: .team(.vibe), query: nil),
        ZeroQueryItem(title: "workshop", kind: .history, query: "workshop"),
        ZeroQueryItem(title: "vs code", kind: .history, query: "vs code"),
        ZeroQueryItem(title: "summarize", kind: .history, query: "summarize"),
        ZeroQueryItem(title: "Proactive summaries", kind: .file, query: nil),
        ZeroQueryItem(title: "Crypto introduction", kind: .file, query: nil)
    ]
}

private struct ZeroQueryRow: View {
    let item: ZeroQueryItem

    var body: some View {
        HStack(spacing: 12) {
            leadingIcon
                .frame(width: 32, height: 32)

            Text(item.title)
                .font(.system(size: 17, weight: .regular))
                .kerning(-0.41)
                .foregroundStyle(TeamsColor.textPrimary)
                .frame(height: 22)
                .frame(maxWidth: .infinity, alignment: .leading)

            trailingIcon
                .frame(width: 20, height: 20)
        }
        .padding(.leading, 16)
        .padding(.trailing, 12)
        .frame(height: rowHeight)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var leadingIcon: some View {
        switch item.kind {
        case .team(let artwork):
            switch artwork {
            case .stca:
                Image("STCAIcon")
                    .resizable()
                    .frame(width: 20, height: 20)
                    .frame(width: 32, height: 32)
                    .background(TeamsColor.interactive, in: Circle())
            case .studioVA:
                Image("StudioVAIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 34)
            case .vibe:
                Image("VibeIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
            }
        case .history:
            Image("HistoryIcon")
                .resizable()
                .frame(width: 24, height: 24)
        case .file:
            Image("PowerPointIcon32")
                .resizable()
                .frame(width: 32, height: 32)
        }
    }

    @ViewBuilder
    private var trailingIcon: some View {
        switch item.kind {
        case .team(let artwork):
            Image(peopleIcon(for: artwork))
                .resizable()
                .frame(width: 20, height: 20)
        case .history:
            Image(systemName: "xmark")
                .font(.system(size: 14))
                .foregroundStyle(Color.gray)
        case .file:
            Image("ShareIcon")
                .resizable()
                .frame(width: 20, height: 20)
        }
    }

    private var rowHeight: CGFloat {
        if case .team(.studioVA) = item.kind {
            return 50
        }
        return 48
    }

    private func peopleIcon(for artwork: ZeroQueryItem.TeamArtwork) -> String {
        switch artwork {
        case .stca:
            "STCAPeopleIcon"
        case .studioVA:
            "StudioPeopleIcon"
        case .vibe:
            "VibePeopleIcon"
        }
    }
}

private struct SearchResult: Identifiable {
    enum Kind {
        case person(String)
        case group
        case channel
        case meeting
        case powerpoint
        case word
        case history
        case search
    }

    let id = UUID()
    let title: String
    let kind: Kind

    static let people = [
        SearchResult(title: "Lisa Phillips", kind: .person("LisaPhillips")),
        SearchResult(title: "Lina Chung", kind: .person("LinaChung")),
        SearchResult(title: "Alina Lin", kind: .person("AlinaLin")),
        SearchResult(title: "John, Lisa and 5+", kind: .group)
    ]

    static let files = [
        SearchResult(title: "Linear regression metrics.pptx", kind: .powerpoint),
        SearchResult(title: "Sales team list.docx", kind: .word)
    ]

    static let messages = [
        SearchResult(title: "FY22 OKR listen in", kind: .meeting)
    ]

    static let channels = [
        SearchResult(title: "Vibe coding community", kind: .channel),
        SearchResult(title: "Studio VA", kind: .channel),
        SearchResult(title: "STCA Design", kind: .channel)
    ]

    static let mixed = [
        SearchResult(title: "Lisa Phillips", kind: .person("LisaPhillips")),
        SearchResult(title: "John, Lisa and 5+", kind: .group),
        SearchResult(title: "FY22 OKR listen in", kind: .meeting),
        SearchResult(title: "Linear regression metrics.pptx", kind: .powerpoint),
        SearchResult(title: "Sales team list.docx", kind: .word),
        SearchResult(title: "Linear", kind: .history),
        SearchResult(title: "Search for “Li”", kind: .search)
    ]
}

private struct SearchResultRow: View {
    let result: SearchResult
    let query: String

    var body: some View {
        HStack(spacing: 24) {
            leadingIcon
                .frame(width: 24, height: 24)

            highlightedTitle
                .font(.system(size: 17))
                .foregroundStyle(TeamsColor.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            if case .person = result.kind {
                Image("ContactIcon")
                    .resizable()
                    .frame(width: 24, height: 24)
            }
        }
        .padding(.horizontal, 24)
        .frame(height: 48)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var leadingIcon: some View {
        switch result.kind {
        case .person(let image):
            Image(image)
                .resizable()
                .scaledToFill()
                .clipShape(Circle())
        case .group:
            Image("GroupAvatar")
                .resizable()
                .scaledToFill()
                .clipShape(Circle())
        case .channel:
            ZStack {
                Circle().fill(TeamsColor.interactive)
                Image(systemName: "person.3.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
            }
        case .meeting:
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(TeamsColor.interactive)
                Image("CalendarIcon")
                    .resizable()
                    .frame(width: 16, height: 16)
            }
        case .powerpoint:
            Image("PowerPointIcon").resizable()
        case .word:
            Image("WordIcon").resizable()
        case .history:
            Image("HistoryIcon").resizable()
        case .search:
            Image("SearchIcon").resizable()
        }
    }

    private var highlightedTitle: Text {
        guard
            !query.isEmpty,
            let range = result.title.range(of: query, options: .caseInsensitive)
        else {
            return Text(result.title)
        }

        return Text(String(result.title[..<range.lowerBound]))
            + Text(String(result.title[range])).bold()
            + Text(String(result.title[range.upperBound...]))
    }
}

#Preview {
    ContentView(onDismiss: {})
}