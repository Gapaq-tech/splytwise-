# Splytwise UI Rules

This document is the UI contract for Splytwise. Anyone changing a screen, widget, theme, dialog, or navigation surface must follow these rules.

## 1. Visual Direction

Splytwise is a calm, trustworthy personal banking and money-management app.

The interface should feel:

- Clear and practical
- Quiet and trustworthy
- Easy to scan on a phone
- Focused on balances, decisions, and transactions
- Consistent with the existing bottom navigation

Do not introduce decorative visual complexity, marketing-style layouts, or unrelated design languages.

## 2. Color Palette

Use only these visible UI colors:

- **Black:** primary text, icons, dividers, and strong values
- **White:** page backgrounds, fields, and primary surfaces
- **Cream:** secondary surfaces, selected controls, quiet panels
- **Gold:** primary action, selection state, focus state, and important financial emphasis

Use the existing tokens in `lib/theme/tokens.dart` whenever possible:

- `SplytPalette.gold`
- `SplytPalette.goldSoft`
- `SplytPalette.cream`
- `SplytPalette.line`

Avoid adding or reintroducing teal, mint, coral, purple, blue, green, or bright category colors to user-facing screens. Existing data may contain old category colors, but new UI should not display them as dominant styling.

Do not use color alone to communicate meaning. Pair important states with text or an icon.

## 3. Typography and Numbers

Use the existing app typography, but keep financial numbers simple and readable.

- Do not use oversized, decorative, or heavily stylized money numbers.
- Do not use negative letter spacing for account values.
- Use black for primary account numbers on light surfaces.
- Use moderate weights such as `FontWeight.w600` or `FontWeight.w700`.
- Keep labels smaller and quieter than values.
- Use sentence case for normal labels.
- Use uppercase labels only for short banking metadata such as `AVAILABLE BALANCE`.

Currency values must use `formatPesewas()` from `lib/utils/format.dart`. Do not manually format money in widgets.

The Ghana currency display must remain ASCII-safe as `GHS ` unless a tested font and rendering strategy is introduced. Do not reintroduce the `GH₵` glyph without verifying it on a real device.

## 4. Layout and Spacing

Every screen must respect device safe areas, especially near the status bar and bottom navigation.

- Leave visible breathing room below the status bar.
- Do not place titles or buttons directly against the top edge.
- Keep primary content inside a horizontal margin of roughly 20 to 24 logical pixels.
- Prefer one clear visual hierarchy over many stacked cards.
- Avoid large empty gaps between fields and the primary action.
- Avoid nested cards and unnecessary rounded containers.
- Use `Expanded` carefully and test on a short phone viewport.
- A fixed header may remain fixed while a content list scrolls.
- If a page is intended to fit one screen, do not use an internal scroll view to hide overflow problems.

Any scrollable page must keep its title and primary controls usable and must not make users scroll past basic information unnecessarily.

## 5. Banking Surfaces

Balance sections should look like account summaries, not promotional cards.

- Use a white or cream surface.
- Use a thin cream or gold border.
- Show the account label, amount, and supporting values in that order.
- Provide a clear show/hide balance control when sensitive values are displayed.
- Hidden balances must use stable asterisks such as `********`, not unsupported glyphs or boxes.
- If a display-only balance is negative and the product rule says it should be clamped, show the selected currency followed by `0.00`. Keep warning state separate from the displayed amount.

## 6. Header and Navigation

The bottom navigation is the primary visual reference for spacing and hierarchy.

- Keep navigation items evenly distributed.
- Keep the center gold `+` action visually dominant.
- The center `+` must open the income/expense choice menu; it must not silently choose one transaction type.
- Keep profile controls on the left side of a page header.
- Keep notification controls on the right side.
- Center the page title or greeting between those controls when appropriate.
- Do not group profile and notification actions together on one side.
- Use tooltips for unfamiliar icon-only controls.

## 7. Forms

Forms must be readable before the user focuses a field.

- Use explicit visible labels above fields when the screen uses a light background.
- Use black text for entered values and labels.
- Use black-muted text for hints and supporting copy.
- Use gold for focused field borders or underlines.
- Always make the selected currency visible in amount fields.
- Keep date rows readable with black text and black icons.
- Use gold for the primary submit or continue button.
- Use clear action labels such as `Continue`, `Log expense`, `Confirm split`, or `Add bucket`.
- Avoid vague labels such as `Allocate this` when the next action can be named directly.
- Keep the primary action close enough to the form that the relationship is obvious.

Do not rely on inherited Material theme colors for form contrast. Set important field colors explicitly.

## 8. Chips, Rows, and Lists

Prefer simple rows over large decorative cards.

- Use white rows with thin cream borders or cream secondary rows.
- Keep row heights compact but comfortable for touch.
- Use the actual category icon from the stored category data.
- The Free money bucket must always use the wallet icon.
- Use a gold or cream selected state with black text.
- Include a chevron when tapping a row opens details.
- Keep category names readable and consistently capitalized in display text.
- Do not silently rewrite stored user data just to change capitalization.

For spending or goal progress, use a restrained gold progress indicator rather than neon category colors.

## 9. Dialogs and Bottom Sheets

Dialogs and bottom sheets must follow the same palette as the screen behind them.

- Use white or cream surfaces.
- Use black titles and labels.
- Use gold for the primary action.
- Use a clear Cancel action.
- Keep text controllers owned and disposed by the dialog widget itself.
- Do not create a controller in the parent and dispose it immediately after `showDialog` returns when the dialog contains an active text field.
- Test Cancel specifically, including with the keyboard open.

The add-bucket dialog should be labeled `Add money bucket` and should return safely without framework assertions when Cancel is pressed.

## 10. Activity and Alerts

Activity should be scannable and readable.

- Use dark text for titles.
- Use black-muted text for dates and subtitles.
- Use simple income and expense icons.
- Use dividers instead of heavy cards when possible.
- Low-money conditions should appear as a compact notification-style row with an icon and explanatory text.
- Do not show a large red warning panel for a routine account warning.

## 11. Screen Responsibilities

Keep each destination focused:

- **Home:** balance, key metrics, spending summary, and essential actions
- **Budget:** fixed header plus a scrollable Money buckets list; Goals may be a separate section below
- **Bucket detail:** account summary, Activity, then collapsed customization
- **Expense:** amount, purpose, date, bucket selection, and submit action
- **Income:** amount, source, date, then allocation
- **History:** chronological transaction review
- **Goals:** goal progress and goal actions

Tapping a money bucket must open bucket details. It must not open the expense form.

## 12. Data and Display Rules

- Preserve existing providers, routes, and database behavior unless the task explicitly requires a data change.
- Display-only clamping must not mutate stored balances.
- Free money may be shown as `GHS 0.00` when the display rule requires it, while the warning can still explain that the real balance is below zero.
- Keep category-specific icons where data supports them.
- Do not add new currencies casually. Currency comes from profile settings.

## 13. Accessibility and Device Checks

Before considering a UI change complete:

- Test on a narrow phone viewport.
- Verify no text is clipped or invisible.
- Verify no bottom or right overflow occurs.
- Verify the keyboard does not hide important fields or actions.
- Verify icon-only controls have tooltips and adequate touch targets.
- Verify focused, selected, empty, loading, error, and negative-balance states.
- Verify dialogs can be cancelled safely.

## 14. Required Validation

For UI changes, run at least:

```bash
flutter analyze <touched-files>
flutter test
```

If the change affects a real device layout, also run the app on a phone and inspect:

- Status-bar spacing
- Bottom navigation spacing
- Keyboard behavior
- Currency rendering
- Text contrast
- Dialog Cancel behavior
- Short-screen overflow

Do not report a UI change as complete if analyzer errors, test failures, overflow warnings, invisible text, or framework red screens remain.
