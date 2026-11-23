# MyPortfolio Mobile - Karyn Isabelle Dexter

Name: Karyn Isabelle Dexter

NPM: 2506656860

Class: PBP A

## About This Project

The Flutter mobile client for my personal portfolio. The Django website lives in a separate repository (`myportofolio`), which already exposes a REST API at `/api/v1/` (Tutorial 7 / Tugas 6). In later tutorials this app will read from that API; for now the data entered in the forms is only shown in a dialog and is not saved yet.

- **Menu page** - three `InfoCard`s at the top showing my NPM, full name, and class, followed by five `ItemCard` action buttons in a 3-column grid. The page scrolls, so nothing is cut off on short screens.
- **Drawer** - a left drawer (`LeftDrawer`) shared by every page, with **Home**, **Add Project**, and **Add Education**.
- **Add Project form** (Tutorial 9) - project name, description, category dropdown, technologies, and link.
- **Add Education form** (Tugas 8) - the form for my own Education section, with the same fields and rules as the `Education` model in the Django project.

| Button | Icon | Color | What it does |
|---|---|---|---|
| Lihat Proyek | `Icons.folder` | Indigo | SnackBar only (list page comes later) |
| Tambah Proyek | `Icons.create_new_folder` | Orange | Opens the Add Project form (`Navigator.push`) |
| Lihat Education | `Icons.school` | Blue | SnackBar only (list page comes later) |
| Tambah Education | `Icons.add_circle` | Green | Opens the Add Education form (`Navigator.push`) |
| Logout | `Icons.logout` | Red | SnackBar only (login comes later) |

Tapping a button shows a SnackBar with the message `Kamu telah menekan tombol [button name]!`. Any SnackBar already on screen is hidden first, so they never pile up.

### Add Education form

| Field | Input | Rule (same as the Django model/form) |
|---|---|---|
| Institusi | `TextFormField` | Required, not only spaces, max 255 characters |
| Deskripsi | `TextFormField` (3 lines) | Optional, max 255 characters |
| Tanggal Mulai | `showDatePicker()` | Required |
| Tanggal Selesai | `showDatePicker()` + clear button | Optional (empty = still ongoing), not before Tanggal Mulai |
| URL Sertifikat/Ijazah | `TextFormField` with URL keyboard | Optional; if filled, must be a full `http://` or `https://` URL with a real domain, max 200 characters |

Pressing **Simpan** runs `FormState.validate()`. Invalid fields show their error under the field; only when every field passes does an `AlertDialog` show a summary of everything entered. **OK** closes the dialog and clears the form.

### Code structure

```
lib/
├── main.dart                 # Entry point: MyApp (MaterialApp + indigo theme)
├── screens/
│   ├── menu.dart             # MyHomePage, InfoCard, ItemHomepage model
│   ├── project_form.dart     # ProjectFormPage (Tutorial 9)
│   └── education_form.dart   # EducationFormPage (Tugas 8)
└── widgets/
    ├── left_drawer.dart      # LeftDrawer, used by all three pages
    └── project_card.dart     # ItemCard (SnackBar + navigation)
test/
├── widget_test.dart          # Menu, drawer, Add Project form
└── education_form_test.dart  # Add Education form and its navigation
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
flutter test      # all widget tests in test/
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

### Tutorial 9
- Added the `LeftDrawer` (Home and Add Project, using `Navigator.pushReplacement`) and the Add Project form (`ProjectFormPage`) with validation and a summary `AlertDialog`.
- Added the Lihat Proyek and Tambah Proyek buttons; Tambah Proyek opens the form with `Navigator.push`, so Back returns to the menu.
- Refactored into `lib/screens/` (pages) and `lib/widgets/` (drawer and `ItemCard`).
- Wrapped the menu body in a `SingleChildScrollView`: with five buttons, a wide but short window (e.g. Chrome on a laptop) cut off the bottom of the page by 196 pixels.

### Tugas 8
- Added `EducationFormPage` (`lib/screens/education_form.dart`) for my Education section, with the fields and rules of the Django `Education` model (see the table above).
- The Tambah Education card now opens it with `Navigator.push`, and the drawer has a new **Add Education** option. Home and Add Project are unchanged, and all three pages use the same drawer.
- Added `test/education_form_test.dart`: opening the form from the card and from the drawer, Back and Home returning to the menu, rejected input (empty, spaces only, too long, bad URL, end date before start date), the summary dialog, resetting after OK, and a 360 x 640 phone screen with the keyboard open.

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

### Tugas 8

1. **`push()`, `pushReplacement()`, and `pop()`.** The `Navigator` keeps pages (routes) in a stack. `push()` puts a new page on top and keeps the current one under it. `pushReplacement()` removes the current page and puts the new one in its place, so the old page cannot be returned to. `pop()` removes the top page and shows the one under it again; I use it to close the summary dialog, because a dialog is also a route. The Tambah Education and Tambah Proyek cards use `Navigator.push()`, so the menu stays under the form and the device or browser Back button returns to it. The drawer options use `Navigator.pushReplacement()`. When I press **Home** in the drawer while on the Education form, the form is replaced by a new `MyHomePage`, so the form disappears and I am back on the main page. One side effect: if the form was opened from the card, the old menu is still under it, so the stack becomes "menu, menu" and pressing Back after Home shows the old menu again.

2. **`Scaffold`, `AppBar`, and `Drawer`.** Every page is a `Scaffold` with the same three parts: an `appBar` for the title, a `drawer` for navigation, and a `body` for the content. Because the layout is the same, the user always finds the title at the top and the menu behind the same hamburger icon. The drawer is one widget, `LeftDrawer` in `lib/widgets/left_drawer.dart`, and all three pages use `drawer: const LeftDrawer()`. Adding the Add Education option therefore only took one change, and it appeared on every page. Indigo is my theme color across pages: the app theme is `ColorScheme.fromSeed(seedColor: Colors.indigo)`, which the menu's `AppBar` reads through `Theme.of(context).colorScheme.primary`; the drawer header, both form `AppBar`s, and both Save/Simpan buttons use `Colors.indigo` as well.

3. **Form layout.** The form is a single column with one field per row at full width. The order is the order a person thinks about the entry: where (Institusi), what (Deskripsi), when (Tanggal Mulai, Tanggal Selesai), and proof (URL), with **Simpan** at the end. Each field has a label, a hint, and an outlined border, and "(opsional)" in the label tells the user what can be skipped. Spacing widgets keep it readable: every field sits in `Padding(EdgeInsets.all(8))`, so fields never touch each other or the screen edge. The scroll widget keeps it usable: the whole form is inside a `SingleChildScrollView`. On a small phone, or when the keyboard takes up half of the screen (the `Scaffold` shrinks its body when the keyboard opens), the fields that do not fit can be scrolled to instead of overflowing, so **Simpan** can always be reached. A test checks this on a 360 x 640 screen with a 300-pixel keyboard. On wide screens such as Chrome, a `ConstrainedBox` limits the form to 600 pixels so the fields do not stretch across the whole window.

4. **`GlobalKey<FormState>`, `validator`, and `validate()`.** The `GlobalKey<FormState>` is attached to the `Form`, which lets the Simpan button's `onPressed` reach the form's state from outside the fields through `_formKey.currentState`. Each field has a `validator` function that receives the field's value and returns an error message, or `null` if the value is fine. When **Simpan** is pressed, `_formKey.currentState!.validate()` runs every validator, shows each error under its field, and returns `true` only if all of them returned `null`. Only then does `showDialog()` open the summary. A value that is rejected is the certificate URL `drive.google.com/file`: it has no `https://`, so it is not a full URL that the Django `URLField` would accept, and the field shows "Masukkan URL lengkap yang diawali http:// atau https://.". Choosing the input type or keyboard is not enough. `TextInputType.url` only changes the on-screen keyboard layout (for example, it adds `/` and `.com` keys); it does not stop the user from typing or pasting anything, and on Chrome a physical keyboard ignores it completely. In the same way, the date picker guarantees a valid date, but it cannot stop the user from changing Tanggal Mulai to a day after Tanggal Selesai, and `maxLength` limits the length but still accepts a name made only of spaces. Only the validators check those rules.

## AI Usage

### Tools
I used Claude to assist with the development of Tutorial 8 and Tugas 7.

### How I Used AI
I provided the tutorial and assignment instructions as references and used AI assistance to help translate the requirements into code implementations. The AI was also used to review the project structure, suggest necessary changes, and help identify issues during testing.

### AI Contributions
- **Tutorial 8:** Assisted with setting up the Flutter project, implementing `main.dart` and `menu.dart`, and updating the default widget test.
- **Tugas 7:** Assisted with implementing the `color` attribute in `ItemHomepage`, updating the homepage button list and `ItemCard`, writing documentation comments, creating widget tests, and drafting the README.

### Verification and Adjustments
I reviewed the generated changes and used `flutter analyze` and `flutter test` to check the implementation. During this process, several adjustments were made:
- Replaced the default counter test because it was no longer relevant to the updated application.
- Adjusted the SnackBar widget test to use `pumpAndSettle()` to account for the closing animation before displaying the next SnackBar.

### Tutorial 9 & Tugas 8
For Tugas 8, it read the `Education` model and `EducationForm` in my Django repository, so the mobile form uses the same fields, labels, length limits, and the same error message for the date order ("Tanggal selesai tidak boleh sebelum tanggal mulai.").

**AI contributions:**
- **Tutorial 9:** the drawer, the Add Project form, the navigation from the Tambah Proyek card, moving files into `screens/` and `widgets/`, and the updated widget tests.
- **Tugas 8:** `EducationFormPage` (date pickers, URL check, summary dialog), the new card navigation and drawer option, `test/education_form_test.dart`, and first drafts of the Tugas 8 reflection answers.

**What had to be caught or corrected:**
- **Overflowing menu.** After adding Lihat Proyek and Tambah Proyek, the menu overflowed by 196 pixels on a wide, short screen, because the page was a plain `Column` that cannot scroll. The tests caught it, and the body was wrapped in a `SingleChildScrollView`.
- **A wrong bug report.** The AI first claimed that `FormState.reset()` leaves the old text in the form's variables and added extra code to clear them. When it removed that code to check, the test still passed: in this Flutter version, `TextFormField.reset()` calls `onChanged('')` itself. The extra code was removed again. Lesson: check a suspected bug before fixing it. For the Education form the manual clearing *is* needed, but only for the two dates, which are kept in the page's state rather than in text fields.
- **Test font vs. real font.** The drawer header overflowed only in tests, because the Flutter test font draws every letter as a square as wide as the font size. The tests use a smaller text scale for that check instead of changing the tutorial's drawer.
- **`material_ui` import.** Tutorial 9 says to run `flutter pub add material_ui` on Flutter 3.47. The AI's attempt to run it was blocked on my machine, so the project still imports `package:flutter/material.dart`, which works without warnings on Flutter 3.47.

