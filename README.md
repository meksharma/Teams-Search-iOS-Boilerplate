# Teams Search iOS Boilerplate

A SwiftUI prototype of a Microsoft Teams mobile search flow.

## Demo recordings

- [Zero-input search](./Demos/01-zero-input-search.mp4) — opens Search from Activity and gently reveals zero-input suggestions.
- [Query and filters](./Demos/02-query-and-filters.mp4) — types a query, reveals fresh results, and narrows them with People, Messages, and Channels.

## Included flows

- Animated Teams loading screen
- Activity feed entry screen
- Zero-query search suggestions
- People, Messages, Files, and Channels results
- Native iOS keyboard and search focus behavior

## Requirements

- Xcode 27 or later
- iOS 17 or later

## Run

```bash
git clone https://github.com/meksharma/Teams-Search-iOS-Boilerplate.git
cd Teams-Search-iOS-Boilerplate
open TeamsSearchBoilerplate.xcodeproj
```

In Xcode, select an iPhone simulator and choose a scheme:

- `TeamsSearchBoilerplate`: interactive loader, Activity, and search flow.
- `TeamsSearchPortfolioIntro`: looping portfolio intro with automated search typing.

Edit the Swift files in `TeamsSearchBoilerplate/`, then commit and push changes normally with Git.

The reference interaction recording is included as `real video of search.mp4`.
