# Flutter Visual Fidelity Handoff: Gider
**Tarih:** 2026-04-20  
**Durum:** Implementation-ready visual fidelity contract  
**Primary visual source of truth:** [gider-hi-fi.html](C:/Users/nacho/Desktop/gider/.agent/design-reference/gider-hi-fi.html)  
**Secondary supporting sources:** [ui-handoff.md](C:/Users/nacho/Desktop/gider/.agent/ui-handoff.md), [domain-freeze.md](C:/Users/nacho/Desktop/gider/.agent/domain-freeze.md), [product.md](C:/Users/nacho/Desktop/gider/.agent/product.md), [implementation_plan.md](C:/Users/nacho/Desktop/gider/.agent/implementation_plan.md)

## 1. Visual Fidelity Rules

### What Must Match Exactly
- Overall visual language must stay warm-cream + petrol-teal + green + terracotta + amber as defined in `gider-hi-fi.html`.
- Typography pairing must stay `Fraunces` for display/headline numbers and headings, `Inter` for UI/body, `JetBrains Mono` for micro labels and metadata.
- Card hierarchy must remain the core composition system: rounded cards, stacked vertically, high whitespace, typography-led emphasis.
- Component anatomy must match the hi-fi reference:
  - dominant hero card
  - compact stat cards
  - rounded floating bottom nav
  - circular gradient FAB
  - rounded bottom sheet
  - soft bordered inputs
  - pill/chip filters with full-pill geometry
- Spacing feel must remain airy and deliberate. The app must not become tighter, flatter, or denser than the hi-fi.
- Border treatment must stay subtle, warm, and low-contrast. Borders are present almost everywhere, but never harsh.
- Shadows must stay soft and layered, not Material-heavy elevation blocks.
- Screen backgrounds must keep the cream-to-tinted gradients and atmospheric radial glow direction from the hi-fi.
- Wireframe/sketch styling must not enter the final Flutter UI.

### What May Adapt Slightly
- Exact CSS blur and translucency values may be approximated in Flutter when platform composition differs.
- HTML-style text metrics may shift by 1-2 px because Flutter font rendering differs from browser rendering.
- Custom keypad visuals from the hi-fi may be approximated only if native numeric keyboard is required for usability or platform consistency.
- Long text overflow may truncate slightly earlier in Flutter, but hierarchy must remain unchanged.
- Bottom nav and FAB safe-area positioning may shift a few px to respect Android insets.

### What Must Not Be Changed
- Do not change the palette family.
- Do not flatten gradients into plain colors.
- Do not replace Fraunces with a generic sans.
- Do not modernize the app into a generic fintech dashboard.
- Do not replace rounded cards with edge-to-edge lists.
- Do not center the FAB in the nav bar.
- Do not remove borders from cards, pills, or inputs.
- Do not switch from text-first hierarchy to chart-first hierarchy.
- Do not use wireframe references as visual guidance over the hi-fi.
- Do not introduce new visual motifs, neumorphism, glassmorphism-heavy panels, purple themes, or dark-mode-first styling.

## 2. Exact Design Extraction From Hi-Fi

### Colors
Directly extracted from `:root` in `gider-hi-fi.html`:

```text
bg               #F1ECE1
bg-tint          #E6E9DF
surface          #FBF7ED
surface-2        #F6EFDF
border           #E0D7C2
border-soft      #EBE2CD

ink              #15282B
ink-soft         #4A5C60
ink-fade         #8C9699

brand            #0E6B6F
brand-strong     #094A4D
brand-soft       #CDE7E4
brand-tint       #E5F1EE

mint             #D8E9D0
mint-strong      #BCD7B0

income           #2F8A4D
income-soft      #D9ECDD

expense          #C2492A
expense-soft     #F3DBCF

amber            #E8A93A
amber-soft       #FCE7B6

highlight        #F6D66C
highlight-soft   #FBEAB2
```

### Typography
Extracted from Google Fonts import and class rules:

- Heading/display serif: `Fraunces`
- UI/body sans: `Inter`
- Mono metadata: `JetBrains Mono`

Core text scales from the hi-fi:

```text
h1        26px  Fraunces 500  letter-spacing -0.02em
h2        20px  Fraunces 500  letter-spacing -0.015em
eye       10px  JetBrains Mono 500  uppercase  letter-spacing 0.14em
lbl       12px  Inter 500
num-xxl   56px  Fraunces 500  letter-spacing -0.035em
num-xl    42px  Fraunces 500  letter-spacing -0.03em
num-lg    28px  Fraunces 500  letter-spacing -0.02em
num-md    20px  Fraunces 500  letter-spacing -0.015em
num-sm    16px  Fraunces 500
num-xs    13px  Inter 600
delta     12px  Inter 600
```

### Corner Radii
Extracted from CSS tokens and component-specific rules:

```text
radius-sm   10px
radius      14px
radius-lg   20px
radius-xl   28px

phone shell          44px outer / 34px inner
bottom nav           22px
sheet                26px 26px 24px 24px
fab                  50% circle
icon avatar default  12px
icon avatar small    10px
keypad key           12px
button               16px
```

### Shadows
Directly extracted:

```text
shadow-sm  0 1px 2px rgba(9,40,43,0.05), 0 1px 1px rgba(9,40,43,0.03)
shadow-md  0 6px 14px rgba(9,40,43,0.07), 0 2px 4px rgba(9,40,43,0.05)
shadow-lg  0 20px 40px rgba(9,40,43,0.10), 0 6px 14px rgba(9,40,43,0.06)
```

Usage:
- Default card: `shadow-sm`
- Elevated card or nav: `shadow-md`
- Sheet and heavy floating elements: `shadow-lg`
- FAB uses its own stronger brand-tinted shadow

### Spacing Rhythm
From visible CSS paddings/margins and card anatomy:

```text
4px   micro gap
6px   inline chips, bar label spacing
8px   close spacing inside cards
10px  component micro-sections
12px  common vertical rhythm
14px  compact card padding / row breathing
16px  standard section padding on mobile screen interiors
18px  screen side padding inside phone frame
20px  larger card outer breathing
24px  hero/internal major spacing
28px  sheet side padding / large radius feel
32px  desktop demo shell padding, not mobile content padding
```

The important rule is not a numeric grid system alone, but the rhythm:
- dense inside chips and pills
- medium inside list rows and compact cards
- generous around hero cards and section transitions

### Component Anatomy

#### Card
- Warm off-white surface by default
- 1px warm border
- 20px dominant radius
- Soft shadow
- Uses typography and spacing to create hierarchy, not big iconography
- Variants:
  - default surface
  - teal gradient
  - mint gradient
  - amber/highlight gradient
  - semantic soft tinted cards for income/expense/warning states

#### Input
- Rounded rectangle, 14px radius
- Warm translucent fill
- Visible low-contrast border
- Focus ring uses petrol teal with soft outer glow
- Labels are quiet, not bold

#### Button
- Height and density are generous
- Default corner radius 16px
- Primary uses solid petrol teal
- Income/expense action buttons use semantic gradients when the hi-fi does
- Ghost button remains bordered and airy

#### Pill
- Full pill radius
- Small typography
- Light border or soft-tinted semantic fill
- Used for state, summary delta, status

#### Chip
- Full pill radius
- Slightly larger than pill
- Soft translucent background with border
- Selected state is solid ink or solid brand

#### Icon Container
- Rounded square or circle
- Always filled with a tint, never bare outline-only icons floating on plain background
- Includes subtle border tint in most variants
- Default size 38x38, small 32x32

#### Bottom Nav
- Floating rounded container, not a flat system nav strip
- Semi-translucent cream surface
- Blur/tint effect
- 4 equal items
- Active item gets solid ink-filled pill treatment

#### FAB
- 56x56 circle
- Gradient from `#0E6B6F` to `#094A4D`
- Stronger shadow than cards
- Lives above nav, bottom-right

#### Bottom Sheet
- Large rounded top corners
- Visible handle
- Warm surface
- Heavy but soft upward shadow
- Internal spacing must stay roomy

### Gradient Usage
Extracted examples:

```text
screen.cream     linear-gradient(180deg, #FBF7ED 0%, #F4ECD9 100%)
screen.mint      linear-gradient(180deg, #EAF3E8 0%, #DCE9D5 100%)
screen.tealmint  linear-gradient(180deg, #E9F2EF 0%, #D4E6E1 100%)
screen.warm      linear-gradient(180deg, #FAF2E0 0%, #F0E4C5 100%)

card.teal        linear-gradient(160deg, #0F6B6F 0%, #094A4D 100%)
card.highlight   linear-gradient(160deg, #FADDAF 0%, #F6C77A 55%, #E8A93A 100%)
card.mint        linear-gradient(160deg, #E3EFDD 0%, #D4E6CC 100%)

bar.brand        linear-gradient(90deg, #0E6B6F, #2AA79B)
bar.income       linear-gradient(90deg, #2F8A4D, #4EB36D)
bar.expense      linear-gradient(90deg, #C2492A, #E07150)
bar.amber        linear-gradient(90deg, #E8A93A, #F6D66C)

fab              linear-gradient(145deg, #0E6B6F, #094A4D)
```

Rule:
- Gradients are essential to the hi-fi feel.
- Do not collapse these into flat colors unless the element is tiny and the visual result is unchanged.

### Glass / Blur Usage
Present in:
- top bar
- section jump nav in the HTML prototype
- floating bottom nav
- dimmed layer over background in modal-like scenes

Flutter translation:
- use subtle translucent cream background plus blur where possible
- never turn these areas into fully opaque white slabs unless blur is technically impossible

### Border Treatment
- Border is almost always present.
- Border color is warm and soft, never neutral gray.
- Border is part of the design language, not a fallback.
- Dashed border is only used in specific create/new tiles, not globally.

### Icon Container Treatment
- Filled background tint
- Matching semantic tint when needed
- Light border tint
- Rounded corners stay soft and slightly oversized
- Icons remain thin-stroked and restrained

### Structure Rules

#### Chip / Pill / Button / Input / Card / FAB / Bottom Nav
- `Chip`: filter/select toggle, translucent, small-medium
- `Pill`: status, delta, semantic state, slightly smaller
- `Button`: action-first, more height and stronger fill
- `Input`: framed and warm, never underlined/minimal
- `Card`: primary layout block
- `FAB`: circular, gradient, shadowed
- `BottomNav`: floating container with active pill state

## 3. Screen-by-Screen Fidelity Notes

### Dashboard
**Chosen hi-fi variant:** `01 Dashboard · Variant A · Net-first hero`

#### What Must Visually Match
- Dominant amber/yellow hero card with the largest number on the screen
- Header composition: small mono date line + large Fraunces title
- Two compact stat cards underneath for income and expenses
- Separate cash/card breakdown card
- Upcoming section below primary summary
- Bottom nav + FAB structure exactly in spirit and proportion

#### What May Flex Slightly In Flutter
- Notification bell/avatar treatment may be simplified if auth avatar is not ready
- Sparkline may be approximated with a simpler inline bar or small chart
- Exact top chrome positioning may shift by safe-area rules

#### Overflow Rules
- Hero value must scale down before wrapping
- Subtitle and delta text may truncate to one line
- Upcoming list max 3-5 rows on dashboard, never allowed to push hero card off initial screen composition

#### Exact Hierarchy Priority
1. Net hero number
2. Income and expenses cards
3. Cash/card split
4. Upcoming payments
5. Recent/supporting secondary information

### Entry Forms
**Chosen hi-fi variants:**
- Expense form: `02 Entry · Variant A · Classic form`
- Income form: `02 Entry · Variant C · Income twin`
- Amount emphasis reference only: `02 Entry · Variant B · Amount-first`

#### What Must Visually Match
- Large amount block near the top
- Soft stacked cards for field groups
- Semantic tinting:
  - expense soft terracotta
  - income soft green
- Sticky bottom save button
- Calm, familiar, card-based form anatomy

#### What May Flex Slightly In Flutter
- Native keyboard replaces custom keypad as primary implementation
- Category/payment chips may wrap slightly differently
- Attachment field can use native picker affordance while keeping visual card style

#### Overflow Rules
- Chips wrap to multiple lines inside their card
- Long vendor/note strings truncate in summary rows but expand in editable field state
- Save CTA must never be pushed off-screen by keyboard; form scrolls instead

#### Exact Hierarchy Priority
1. Amount
2. Category
3. Payment method
4. Platform for income or vendor for expense
5. Date
6. Note / attachment
7. Sticky save CTA

### Transactions
**Chosen hi-fi variant:** `03 Transactions · Variant A · By day`

#### What Must Visually Match
- Grouping by day with soft highlighted day header strips
- Search/filter utilities in the top action area
- Transaction rows with tinted icon container, center text block, right-aligned amount
- Floating nav and FAB remain visible

#### What May Flex Slightly In Flutter
- Search and filter affordances may be split into a search field plus chip row instead of icon-only triggers
- Swipe actions may become long-press/trailing actions to fit Flutter and Android ergonomics

#### Overflow Rules
- Title single line ellipsis
- Meta single line ellipsis
- Amount never wraps
- Day groups can grow indefinitely; list scroll owns overflow

#### Exact Hierarchy Priority
1. Day group header
2. Transaction title
3. Amount
4. Meta line
5. Filters and search

### Reports
**Chosen hi-fi variant:** `04 Reports · Variant A · P&L statement`

#### What Must Visually Match
- Editorial statement feel
- Month context at top
- Strong summary block with income, expenses, and net
- Category breakdown shown as text-first rows with bars below
- Less dashboard feel, more calm reporting surface

#### What May Flex Slightly In Flutter
- Month picker can be a lightweight chevron navigator
- Bars may use Flutter progress bars rather than CSS bars, but colors/shape must stay consistent

#### Overflow Rules
- Category labels truncate before amount
- Breakdown list can scroll below the summary section
- Net number scales down before wrapping

#### Exact Hierarchy Priority
1. Month context
2. Statement summary
3. Net result
4. Category breakdown
5. Secondary comparison affordances

### Recurring
**Chosen hi-fi variants:**
- List screen: `05 Recurring · Variant A · Next-up list`
- Mark paid flow: `05 Recurring · Variant B · Mark-paid flow`

#### What Must Visually Match
- Next-up list with strong status tinting:
  - late = expense soft
  - soon = amber soft
  - later = neutral surface
- Large amount on the right
- Paid CTA attached to the row visually
- Confirmation bottom sheet with roomy spacing and clear summary

#### What May Flex Slightly In Flutter
- Paid CTA may be button or pill button depending on state management convenience
- Dimmed backdrop blur may be approximated with dark translucent overlay

#### Overflow Rules
- Recurring list row title truncates to one line
- Due meta to one line
- Amount fixed width/right aligned
- Bottom sheet scrolls if vertical space is tight

#### Exact Hierarchy Priority
1. Status chip
2. Recurring title
3. Amount
4. Due metadata
5. Pay action

### Categories
**Chosen hi-fi variant:** `06 Categories · Variant A · List with usage`

#### What Must Visually Match
- Settings-adjacent list tone
- Rows with drag-handle visual, icon tile, title, usage/count meta, trailing chevron
- Segmented or chip-based type switch between expense and income
- Soft utility list, not playful icon dashboard

#### What May Flex Slightly In Flutter
- Drag handle may be visual-only in MVP if reorder is not yet implemented
- If counts are not ready, meta line can show transaction count only, but structure must stay the same

#### Overflow Rules
- Category title one line
- Meta one line ellipsis
- Type switch stays pinned near top if screen is long

#### Exact Hierarchy Priority
1. Type switch
2. Category rows
3. Usage/count meta
4. Add new action

### Settings
**Chosen hi-fi variant:** `07 Settings · Variant A · Quiet drawer`

#### What Must Visually Match
- Profile card at top
- Grouped rows beneath
- Quiet, drawer-like structure
- Soft sections and dividers
- Destructive sign-out row separated from neutral items

#### What May Flex Slightly In Flutter
- Profile initials/avatar may be generated dynamically
- Some readonly fields can be chips instead of inline trailing values if space gets tight

#### Overflow Rules
- Row titles single line
- Trailing values single line
- Screen can scroll vertically; no internal nested scroll regions

#### Exact Hierarchy Priority
1. Profile card
2. Preferences group
3. Data group
4. Security/sign-out

### Add Sheet
**Chosen hi-fi variant:** `08 Add sheet · Variant A · Clean list`

#### What Must Visually Match
- Three-option clean sheet
- Handle + eyebrow label + question-style title
- Three semantic rows:
  - income
  - expense
  - recurring
- Each row with tinted icon container and chevron
- Clear cancel action

#### What May Flex Slightly In Flutter
- Cancel may be text button or ghost button depending on sheet implementation
- Row height may increase slightly due to Flutter text metrics

#### Overflow Rules
- Titles one line
- Meta one line or max two lines
- Sheet height stays content-wrapped, not full screen unless accessibility text scaling forces it

#### Exact Hierarchy Priority
1. Title/question
2. Income row
3. Expense row
4. Recurring row
5. Cancel action

## 4. Flutter Implementation Constraints

### Effects That May Need Approximation

#### Backdrop Blur
HTML uses `backdrop-filter: blur(...)`.
Flutter approximation:
- prefer `BackdropFilter` with low sigma blur
- if performance or clipping becomes unstable, use translucent cream overlay without removing softness

#### Radial Atmosphere Background
HTML uses layered `radial-gradient`.
Flutter approximation:
- stack two or three blurred positioned gradient circles behind a cream base
- do not replace with plain scaffold background only

#### Text Rendering
Browser text metrics differ from Flutter.
Approximation rule:
- preserve font families, relative scale, and visual dominance
- allow 1-2 px font-size correction only when needed to prevent overflow

#### CSS Box Shadows
Multiple shadow layers may render slightly differently.
Approximation rule:
- use two-layer `BoxShadow` stacks
- avoid heavy Material elevation presets that look too gray/cool

#### CSS Gradient Precision
Flutter gradients may not exactly match CSS interpolation.
Approximation rule:
- use exact stop colors from hi-fi
- keep direction and tonal logic identical

#### Floating Bottom Nav Blur + Opacity
If blur with clipping becomes too expensive:
- keep nav as semi-translucent cream panel with subtle shadow
- do not change it to a flat opaque white bar

#### Custom Keypad
Hi-fi includes a keypad variant.
Flutter constraint:
- native numeric keyboard is more practical for Android
- if native keyboard is used, preserve the amount-first composition and avoid redesigning the whole screen

## 5. Codex Continuation Handoff

### Build Order
1. Freeze tokens in `app_tokens.dart`
2. Replace current theme values with exact hi-fi palette and type ramp
3. Build shared primitives:
   - `AppCard`
   - `AppButton`
   - `AppInput`
   - `AppChip`
   - `AppPill`
   - `IconTile`
   - `FloatingBottomNav`
   - `AddActionSheet`
4. Rebuild dashboard to chosen hi-fi variant A exactly
5. Rebuild transactions to chosen hi-fi variant A
6. Rebuild reports to chosen hi-fi variant A
7. Rebuild recurring list A and paid sheet B
8. Rebuild categories to chosen hi-fi variant A
9. Rebuild settings to chosen hi-fi variant A
10. Build entry forms using expense A + income C

### Reusable Components
- `HiFiScreenBackground`
- `HiFiCard`
- `HiFiHeroCard`
- `HiFiStatCard`
- `HiFiListRow`
- `HiFiStatusPill`
- `HiFiFilterChip`
- `HiFiInputField`
- `HiFiBottomSheet`
- `HiFiBottomNav`
- `HiFiFab`
- `HiFiIconContainer`

### Immutable Visual Decisions
- Palette values in section 2 are locked.
- Fraunces + Inter + JetBrains Mono are locked.
- Dashboard chosen variant is locked to `A`.
- Transactions chosen variant is locked to `A`.
- Reports chosen variant is locked to `A`.
- Recurring uses `A` for list and `B` for paid flow.
- Categories chosen variant is locked to `A`.
- Settings chosen variant is locked to `A`.
- Add sheet chosen variant is locked to `A`.
- Entry forms use `A` for expense and `C` for income.

### Forbidden Deviations
- No reinterpretation.
- No restyling to match generic Flutter examples.
- No replacing gradients with flat colors because it is easier.
- No changing component shape language.
- No turning all screens into one theme template.
- No introducing new card anatomy, nav anatomy, or FAB placement.
- No borrowing visual decisions from wireframes over the hi-fi.
- No “improving” readability by stripping decorative but structural visual layers.

## Tradeoff Logging Rule
If any visual tradeoff is required because of Flutter or Android constraints, document it in the implementation PR or commit notes using this format:

```text
Tradeoff:
Original hi-fi behavior:
Flutter limitation:
Approximation used:
Why visual result is still acceptable:
```

This file is the Flutter visual fidelity contract. If implementation and this file conflict, this file and `gider-hi-fi.html` win over personal taste.
