# MyPortfolio Mobile - Karyn Isabelle Dexter

Name: Karyn Isabelle Dexter

NPM: 2506656860

Class: PBP A

## About This Project

The Flutter mobile client for my personal portfolio. The Django website lives in a separate repository (`myportofolio`), which already exposes a REST API at `/api/v1/` (Tutorial 7 / Tugas 6). In later tutorials this app will read from that API; for now it has a static menu page:

- **Profile cards** - three `InfoCard`s at the top showing my NPM, full name, and class.
- **Action buttons** - three `ItemCard`s in a 3-column grid, each with its own background color:

| Button | Icon | Color | Purpose (later) |
|---|---|---|---|
| Lihat Education | `Icons.school` | Blue | Show my Education timeline |
| Tambah Education | `Icons.add_circle` | Green | Add an Education entry |
| Logout | `Icons.logout` | Red | Log out of the app |

Tapping a button shows a SnackBar with the message `Kamu telah menekan tombol [button name]!`. Any SnackBar already on screen is hidden first, so they never pile up.

### Code structure

```
lib/
├── main.dart   # Entry point: MyApp (MaterialApp + indigo theme)
└── menu.dart   # MyHomePage (StatelessWidget), InfoCard, ItemHomepage model, ItemCard
test/
└── widget_test.dart
```

Each button's name, icon, and color live together in the `ItemHomepage` model, so `ItemCard` just reads `item.color` and does not need an `if-else` to pick a color.

## Running the Project

1. Install the Flutter SDK (macOS: `brew install --cask flutter`) and check the setup with `flutter doctor`.
2. Clone this repository and enter the folder:
   ```
   git clone https://github.com/karyndextuy/myportofolio_mobile.git
   cd myportofolio_mobile
   ```
3. Get the dependencies:
   ```
   flutter pub get
   ```
4. Run the app in Chrome (or `flutter run` for an emulator or a connected device):
   ```
   flutter run -d chrome
   ```

### Checking the code

```
flutter analyze   # No issues found!
flutter test      # 3 widget tests
```

## Weekly Progress

### Tutorial 8
- Created the Flutter project, moved the home page out of `main.dart` into `lib/menu.dart`, and turned `MyHomePage` into a `StatelessWidget`.
- Set the theme to `ColorScheme.fromSeed(seedColor: Colors.indigo, secondary: Colors.amber[700])`.
- Built the reusable `InfoCard` and `ItemCard` widgets, the `ItemHomepage` model, and the SnackBar feedback.
- Replaced the default counter test, which no longer matched the app, with a test for the new page.

### Tugas 7
- Replaced the sample data (Burhan) with my own NPM, name, and class.
- Changed the buttons to match my Education section from Tugas 3-6: Lihat Education, Tambah Education, and Logout.
- Added a `color` field to `ItemHomepage` and used it as the `Material` background in `ItemCard`, so every button has its own color (blue, green, red).
- Wrote three widget tests: the InfoCards show my data, each button has a different color, and each button shows the right SnackBar message (with only one SnackBar on screen at a time).

## Reflection Questions

### Tugas 7

1. **Widget tree.** In Flutter the whole UI is made of widgets nested inside each other, and that nesting forms a tree. The root of my app is `MyApp`, which returns a `MaterialApp`; its `home` is `MyHomePage`, which returns a `Scaffold`; the `Scaffold`'s `body` is a `Padding` holding a `Column`, and so on down to the `Text` and `Icon` leaves. A parent decides where its children go and how big they may be. It passes size limits (constraints) down to them, each child picks its size within those limits and reports it back, and the parent then places it. For example, `Row` with `MainAxisAlignment.spaceEvenly` spreads the three `InfoCard`s across the width, and `GridView.count(crossAxisCount: 3)` gives each `ItemCard` one third of the row. Data also flows down the tree: `MyHomePage` passes `npm`, `nama`, and `kelas` into each `InfoCard`, and passes each `ItemHomepage` into an `ItemCard`. A child can look up values that an ancestor provides through its `BuildContext` (for example `Theme.of(context)` or `ScaffoldMessenger.of(context)`).

2. **Widgets used in this project.**
   - `MaterialApp` - the root of the app; sets the title, theme, and the first page (`home`).
   - `Scaffold` - the basic page layout with slots for the `appBar` and `body`; it also shows the SnackBars.
   - `AppBar` - the bar at the top showing the "MyPortfolio" title in the theme's primary color.
   - `Text` - shows text (title, card labels, welcome message, button names, SnackBar message).
   - `Padding` - adds space around its child (the page body, the welcome text, and inside the cards).
   - `Column` - stacks its children vertically (page sections, title/content in `InfoCard`, icon/text in `ItemCard`).
   - `Row` - places the three `InfoCard`s side by side.
   - `Center` - centers its child (the welcome section and the content of each `ItemCard`).
   - `SizedBox` - fixed empty space between widgets.
   - `Card` - the raised card with a shadow (`elevation: 2.0`) used by `InfoCard`.
   - `Container` - sets the width and padding of the card content.
   - `GridView.count` - lays out the `ItemCard`s in a grid with 3 columns; `shrinkWrap: true` makes it only as tall as its content so it fits inside the `Column`.
   - `Material` - gives each `ItemCard` its background color and rounded corners, and is the surface `InkWell` draws its ripple on.
   - `InkWell` - makes the card tappable and shows the ripple effect; its `onTap` shows the SnackBar.
   - `Icon` - shows each button's icon.
   - `SnackBar` - the short message at the bottom after a button is tapped, shown through `ScaffoldMessenger` (which `MaterialApp` creates).
   - My own widgets: `MyApp` (StatelessWidget that builds `MaterialApp`), `MyHomePage` (the menu page), `InfoCard` (one profile card), and `ItemCard` (one action button). `ItemHomepage` is not a widget; it is the plain data model for a button.
   - `MediaQuery` and `Theme` are not drawn on screen, but I read from them: `MediaQuery.of(context).size.width` sets the `InfoCard` width, and `Theme.of(context).colorScheme.primary` colors the `AppBar`.

3. **MaterialApp.** `MaterialApp` sets up what a Material Design app needs: the app title, the `ThemeData` (my indigo color scheme with Material 3) that every widget below it can read with `Theme.of(context)`, navigation through a `Navigator` (starting with the `home` page), text direction and localization, and a `ScaffoldMessenger` that SnackBars are shown through. It is usually the root widget because widgets like `Scaffold`, `AppBar`, `Card`, and `InkWell` expect these things to exist above them in the tree. Putting `MaterialApp` at the top makes the theme and navigation available to every page, so each page does not have to set them up again.

4. **StatelessWidget vs StatefulWidget.** A `StatelessWidget` only depends on its constructor arguments and what it reads from its `BuildContext`; it has no data of its own that changes, and it rebuilds only when its parent rebuilds it with new values. A `StatefulWidget` is paired with a `State` object that lives longer than the widget itself and holds data that can change; calling `setState()` tells Flutter to run `build` again with the new values (like the `_counter` in the default demo app). Use a `StatelessWidget` when the screen only shows what it is given - my menu page, `InfoCard`, and `ItemCard` always show the same data, and showing a SnackBar does not change any data inside them, so all of them are stateless. Use a `StatefulWidget` when the widget itself has to remember something that changes while it is on screen, such as a counter, a form's input, a selected tab, or data loaded from the Django API.

5. **BuildContext.** A `BuildContext` is a widget's position in the widget tree. Flutter passes it into every `build(BuildContext context)` method. Through it a widget can look up things that its ancestors provide. In my code:
   - `Theme.of(context).colorScheme.primary` reads the color scheme set in `MaterialApp`, for the `AppBar` color.
   - `MediaQuery.of(context).size.width` reads the screen width to size each `InfoCard`.
   - `ScaffoldMessenger.of(context)` finds the nearest `ScaffoldMessenger` above the `ItemCard` so the SnackBar can be shown.

   It matters because the lookup starts from that position: `.of(context)` searches upward from the widget, so it only finds what really is above it. That is why a context taken from above `MaterialApp` cannot find the theme or a `ScaffoldMessenger`.

6. **Hot reload vs hot restart.** Hot reload (`r` in the terminal, or saving in VS Code) sends the changed code into the running Dart VM and rebuilds the widget tree, but keeps the current state - for example a counter keeps its value - so UI changes show up within about a second. Hot restart (`R`) also loads the new code, but throws away all state and runs `main()` again, so the app starts from its first screen. Hot reload is not enough when the change is in code that already ran and will not run again: changes to `main()` or `initState()`, new values for global variables or `static` fields, changing a widget from `StatelessWidget` to `StatefulWidget` (or back), or changing an `enum` or a class's generic type parameters. Those need a hot restart. A full restart (stopping and running `flutter run` again) is needed when the change is outside the Dart code: native Android/iOS files, adding a package with native code in `pubspec.yaml`, or new assets and fonts.

## AI Usage

### Tools
I used Claude Code to assist with the development of Tutorial 8 and Tugas 7.

### How I Used AI
I provided the tutorial and assignment instructions as references and used AI assistance to help translate the requirements into code implementations. The AI was also used to review the project structure, suggest necessary changes, and help identify issues during testing.

### AI Contributions
- **Tutorial 8:** Assisted with setting up the Flutter project, implementing `main.dart` and `menu.dart`, and updating the default widget test.
- **Tugas 7:** Assisted with implementing the `color` attribute in `ItemHomepage`, updating the homepage button list and `ItemCard`, writing documentation comments, creating widget tests, and drafting the README.

### Verification and Adjustments
I reviewed the generated changes and used `flutter analyze` and `flutter test` to check the implementation. During this process, several adjustments were made:
- Replaced the default counter test because it was no longer relevant to the updated application.
- Adjusted the SnackBar widget test to use `pumpAndSettle()` to account for the closing animation before displaying the next SnackBar.

