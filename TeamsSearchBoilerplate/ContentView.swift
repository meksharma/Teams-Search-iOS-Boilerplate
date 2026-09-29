import SwiftUI

struct ContentView: View {
    let onDismiss: () -> Void
    private let automatedQuery: String?
    private let automatedFilterTitles: [String]

    @State private var query = ""
    @State private var selectedFilter: SearchFilter?
    @State private var isLoadingResults = false
    @State private var showsZeroQueryContent = false
    @State private var filterLoadTask: Task<Void, Never>?
    @State private var zeroQueryRevealTask: Task<Void, Never>?
    @FocusState private var isSearchFocused: Bool

    init(
        automatedQuery: String? = nil,
        automatedFilterTitles: [String] = [],
        onDismiss: @escaping () -> Void
    ) {
        self.automatedQuery = automatedQuery
        self.automatedFilterTitles = automatedFilterTitles
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
            revealZeroQueryContent()

            if let automatedQuery {
                try? await Task.sleep(nanoseconds: 1_400_000_000)
                for character in automatedQuery {
                    guard !Task.isCancelled else { return }
                    query.append(character)
                    try? await Task.sleep(nanoseconds: 360_000_000)
                }

                try? await Task.sleep(nanoseconds: 1_400_000_000)
                for title in automatedFilterTitles {
                    guard
                        !Task.isCancelled,
                        let filter = SearchFilter.allCases.first(where: { $0.rawValue == title })
                    else {
                        return
                    }
                    select(filter)
                    try? await Task.sleep(nanoseconds: 1_800_000_000)
                }
            }
        }
        .onChange(of: query) { _, newValue in
            if newValue.isEmpty {
                filterLoadTask?.cancel()
                selectedFilter = nil
                isLoadingResults = false
                revealZeroQueryContent()
            } else {
                zeroQueryRevealTask?.cancel()
                showsZeroQueryContent = false
            }
        }
        .onDisappear {
            filterLoadTask?.cancel()
            zeroQueryRevealTask?.cancel()
        }
    }

    private var searchHeader: some View {
        HStack(spacing: 12) {
            HStack(spacing: 16) {
                Image("SearchIcon")
                    .resizable()
                    .frame(width: 16, height: 16)

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
                    .opacity(showsZeroQueryContent ? 1 : 0)
                    .offset(y: showsZeroQueryContent ? 0 : 6)
                    .animation(.easeOut(duration: 0.32), value: showsZeroQueryContent)

                ForEach(Array(ZeroQueryItem.items.enumerated()), id: \.element.id) { index, item in
                    Button {
                        if let query = item.query {
                            self.query = query
                        }
                    } label: {
                        ZeroQueryRow(item: item)
                    }
                    .buttonStyle(.plain)
                    .opacity(showsZeroQueryContent ? 1 : 0)
                    .offset(y: showsZeroQueryContent ? 0 : 8)
                    .animation(
                        .easeOut(duration: 0.28)
                            .delay(Double(index) * 0.035),
                        value: showsZeroQueryContent
                    )
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
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
    }

    private var searchResults: some View {
        Group {
            if isLoadingResults {
                SearchResultsLoadingView()
                    .transition(.opacity)
            } else if automatedQuery != nil && selectedFilter == nil {
                PortfolioSearchResults(query: query)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            } else if selectedFilter == .messages {
                MessageSearchResults(query: query)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            } else if selectedFilter == .channels {
                ChannelSearchResults(query: query)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            } else {
                SearchResultList(results: results, query: query)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .animation(.easeOut(duration: 0.22), value: isLoadingResults)
        .animation(.easeOut(duration: 0.22), value: selectedFilter)
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

    private func revealZeroQueryContent() {
        zeroQueryRevealTask?.cancel()
        showsZeroQueryContent = false
        zeroQueryRevealTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 120_000_000)
            guard !Task.isCancelled, query.isEmpty else { return }
            showsZeroQueryContent = true
        }
    }
}

private struct SearchResultsLoadingView: View {
    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<4, id: \.self) { index in
                HStack(spacing: 12) {
                    Circle()
                        .fill(TeamsColor.raisedFill)
                        .frame(width: 40, height: 40)

                    VStack(alignment: .leading, spacing: 7) {
                        Capsule()
                            .fill(TeamsColor.raisedFill)
                            .frame(width: index.isMultiple(of: 2) ? 154 : 128, height: 12)
                        Capsule()
                            .fill(TeamsColor.raisedFill.opacity(0.72))
                            .frame(width: index.isMultiple(of: 2) ? 210 : 184, height: 10)
                    }

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 16)
                .frame(height: 64)
            }
        }
        .accessibilityLabel("Loading search results")
    }
}

private struct ResultRevealModifier: ViewModifier {
    let isVisible: Bool
    let index: Int

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 7)
            .animation(
                .easeOut(duration: 0.24)
                    .delay(min(Double(index) * 0.045, 0.22)),
                value: isVisible
            )
    }
}

private extension View {
    func resultReveal(isVisible: Bool, index: Int) -> some View {
        modifier(ResultRevealModifier(isVisible: isVisible, index: index))
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

    static let all = [
        PortfolioSuggestion(id: "suchitra", title: "Suchitra Mohan", subtitle: "Senior content designer", kind: .person("ActivitySarah")),
        PortfolioSuggestion(id: "sue", title: "Sue Grimshaw", subtitle: "Senior product manager", kind: .person("ActivityKeiko")),
        PortfolioSuggestion(id: "sq-summarize", title: "SQ - Summarize", subtitle: "Outlook Team", kind: .feature),
        PortfolioSuggestion(id: "studio", title: "Studio 8 All", subtitle: "Summer, Abby, Alex + 90", kind: .channel("StudioVAIcon")),
        PortfolioSuggestion(id: "summer", title: "Summer Xuan", subtitle: "Senior product designer", kind: .person("ActivitySerena")),
        PortfolioSuggestion(id: "copilot-card", title: "Summarize Copilot Card", subtitle: "Caleb, Cookie, Colin + 17", kind: .group),
        PortfolioSuggestion(id: "research", title: "summarize research", subtitle: "Recent search", kind: .history)
    ]
}

private struct PortfolioSearchResults: View {
    let query: String
    @State private var showsRows = false

    private var suggestions: [PortfolioSuggestion] {
        let normalized = query.lowercased()
        return PortfolioSuggestion.all.filter {
            $0.title.localizedCaseInsensitiveContains(normalized)
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(suggestions.enumerated()), id: \.element.id) { index, suggestion in
                    PortfolioSuggestionRow(suggestion: suggestion, query: query)
                        .transition(.opacity)
                        .resultReveal(isVisible: showsRows, index: index)
                }
            }
        }
        .scrollIndicators(.hidden)
        .task {
            await Task.yield()
            showsRows = true
        }
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
                Circle()
                    .fill(Color.white)
                    .overlay {
                        Circle()
                            .stroke(TeamsColor.interactive, lineWidth: 1.5)
                    }
                Image("CalendarIcon")
                    .renderingMode(.template)
                    .resizable()
                    .foregroundStyle(TeamsColor.interactive)
                    .frame(width: 14, height: 14)
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
            snippet: "Summarize the latest design decisions and open questions before the weekly review."
        ),
        MessageSearchResult(
            sender: "Lina Chung",
            time: "Wednesday",
            avatar: "LinaChung",
            source: "Vibe coding community > General",
            sourceIcon: nil,
            snippet: "Can you summarize the feedback from this thread before Monday’s review?"
        ),
        MessageSearchResult(
            sender: "Alina Lin",
            time: "Monday",
            avatar: "AlinaLin",
            source: "Studio VA",
            sourceIcon: nil,
            snippet: "I used Copilot to summarize the prototype changes and updated interaction states."
        ),
        MessageSearchResult(
            sender: "Lisa Larsson",
            time: "Monday",
            avatar: "LisaLarsson",
            source: "Studio VA > Design",
            sourceIcon: nil,
            snippet: "Please summarize the options so the team can compare the hierarchy at a glance."
        )
    ]
}

private struct MessageSearchResults: View {
    let query: String
    @State private var showsRows = false

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(MessageSearchResult.items.enumerated()), id: \.element.id) { index, item in
                    MessageSearchResultRow(item: item, query: query)
                        .resultReveal(isVisible: showsRows, index: index)
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
                .resultReveal(isVisible: showsRows, index: MessageSearchResult.items.count)
            }
        }
        .scrollIndicators(.hidden)
        .task {
            await Task.yield()
            showsRows = true
        }
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
        ChannelSearchResult(name: "SQ - Summarize", organization: "Outlook Team", artwork: .teams),
        ChannelSearchResult(name: "Summarize Copilot Card", organization: "Microsoft Design", artwork: .linkedIn),
        ChannelSearchResult(name: "Summarize research", organization: "Teams Consumer", artwork: .teams),
        ChannelSearchResult(name: "Summarize feedback", organization: "Teams Consumer", artwork: .teams),
        ChannelSearchResult(name: "Summarize live support", organization: "Outlook Mobile", artwork: .outlook),
        ChannelSearchResult(
            name: "Summarize weekly updates",
            organization: "Outlook Team",
            artwork: .initials("OT", Color(red: 247 / 255, green: 232 / 255, blue: 196 / 255), Color(red: 126 / 255, green: 92 / 255, blue: 28 / 255))
        ),
        ChannelSearchResult(
            name: "Summarize learning",
            organization: nil,
            artwork: .initials("SL", Color(red: 226 / 255, green: 47 / 255, blue: 0), Color.white)
        )
    ]
}

private struct ChannelSearchResults: View {
    let query: String
    @State private var showsRows = false

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(ChannelSearchResult.items.enumerated()), id: \.element.id) { index, item in
                    ChannelSearchResultRow(item: item, query: query)
                        .resultReveal(isVisible: showsRows, index: index)
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
                .resultReveal(isVisible: showsRows, index: ChannelSearchResult.items.count)
            }
        }
        .scrollIndicators(.hidden)
        .task {
            await Task.yield()
            showsRows = true
        }
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
    let subtitle: String?

    init(title: String, kind: Kind, subtitle: String? = nil) {
        self.title = title
        self.kind = kind
        self.subtitle = subtitle
    }

    static let people = [
        SearchResult(title: "Lisa Phillips", kind: .person("LisaPhillips"), subtitle: "Summarize Copilot Card"),
        SearchResult(title: "Lina Chung", kind: .person("LinaChung"), subtitle: "Summarize research"),
        SearchResult(title: "Alina Lin", kind: .person("AlinaLin"), subtitle: "Summarize design review"),
        SearchResult(title: "John, Lisa and 5+", kind: .group, subtitle: "Summarize project group")
    ]

    static let files = [
        SearchResult(title: "Summarize research findings.pptx", kind: .powerpoint),
        SearchResult(title: "Summarize project notes.docx", kind: .word)
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

private struct SearchResultList: View {
    let results: [SearchResult]
    let query: String

    @State private var showsRows = false

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(results.enumerated()), id: \.element.id) { index, result in
                    SearchResultRow(result: result, query: query)
                        .resultReveal(isVisible: showsRows, index: index)
                }
            }
        }
        .scrollIndicators(.hidden)
        .task {
            await Task.yield()
            showsRows = true
        }
    }
}

private struct SearchResultRow: View {
    let result: SearchResult
    let query: String

    var body: some View {
        HStack(spacing: 24) {
            leadingIcon
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 2) {
                highlightedTitle
                    .font(.system(size: 17))
                    .foregroundStyle(TeamsColor.textPrimary)

                if let subtitle = result.subtitle {
                    highlighted(subtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(TeamsColor.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if case .person = result.kind {
                Image("ContactIcon")
                    .resizable()
                    .frame(width: 24, height: 24)
            }
        }
        .padding(.horizontal, 24)
        .frame(height: result.subtitle == nil ? 48 : 58)
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
                Circle()
                    .fill(Color.white)
                    .overlay {
                        Circle()
                            .stroke(TeamsColor.interactive, lineWidth: 1.5)
                    }
                Image("CalendarIcon")
                    .renderingMode(.template)
                    .resizable()
                    .foregroundStyle(TeamsColor.interactive)
                    .frame(width: 12, height: 12)
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
        highlighted(result.title)
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

#Preview {
    ContentView(onDismiss: {})
}