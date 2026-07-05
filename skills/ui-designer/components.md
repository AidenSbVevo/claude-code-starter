# Component Specs, Tables & States

## Component Spec Template

When designing components, spec them completely so the frontend engineer can implement without guessing.

```
## Component: [Name]

### Purpose
[What it does, who scans it, what's most important at a glance]

### Visual Priority (top → bottom)
1. [Most important element]
2. [Second most important]
3. [Supporting info]

### Layout
[ASCII diagram showing the component]

### Specifications
- Container: [border, radius, padding, background]
- Title: [font-size, font-weight, color, margin]
- Body: [font-size, color, line-height]
- Actions: [button style, placement]

### States
- Default: [description]
- Hover: [what changes — border, shadow, background]
- Selected: [accent border, background tint]
- Disabled: [opacity 0.5, no pointer events]
- Loading: [skeleton matching real content dimensions]
- Error: [red-tinted border, icon + message + retry]
- Empty: [icon + primary message + secondary + action]

### Responsive
[Breakpoint behavior — stack, hide, resize]
```

## Interaction Design Template

```
## Interaction: [Name]

### Trigger
[Click, hover, keyboard shortcut, scroll, data change]

### Behavior
[What happens — animation, state change, data fetch]

### Animation
[Duration, easing, CSS property]

### Reset
[How to return to initial state]

### Edge Cases
[What happens with 0 items, 10k items, error, slow network]
```

## Data-Dense Table Design

Tables are the backbone of data-dense interfaces. Design with extreme care.

### Header
- Background: `--surface-sunken` (light gray)
- Font: xs (12px), font-medium, uppercase, letter-spacing +0.05em
- Position: sticky top
- Sort: chevron indicator (▲▼), highlight sorted column

### Rows
- Font: sm (13px)
- Height: 36px (dense) / 44px (comfortable)
- Separation: `border-bottom: 1px solid var(--border-default)`, NOT alternating backgrounds
- Hover: subtle tint (e.g., `rgba(0,0,0,0.02)` light, `rgba(255,255,255,0.02)` dark)

### Column Types

| Type | Alignment | Font | Format |
|---|---|---|---|
| Names / labels | Left | Regular weight | Clickable link |
| Numbers | Right | Mono, tabular-nums | Consistent decimals |
| Small ratios / rates | Right | Mono | Compact/exponential notation for tiny values |
| Categories | Left | Regular + colored dot (6px) | Never full-cell background |
| Status | Left | Regular + colored badge | Subtle background tint |
| Actions | Right | — | Icon buttons, no text |

### Pagination Strategy

| Rows | Strategy |
|---|---|
| < 100 | Show all, no pagination |
| 100 – 10k | Virtual scrolling (TanStack Virtual) |
| > 10k | Server-side pagination + virtual scroll |

### Identifier & Code Convention
- Render IDs, keys, and codes in the mono font: `ORD-4821`, `usr_9f3a`
- Clickable → navigate to a detail view or external resource
- Pick one treatment (mono, or italic for names) and keep it consistent app-wide
- In HTML: `<code class="entity-id">ORD-4821</code>`

## Loading States

Skeleton screens, not spinners. Match real content dimensions.

```
┌──────────────────────────────┐
│  ████████░░░░  ████░░░░░░░  │  ← Skeleton header
│  ────────────────────────── │
│  ██████████████████████████ │  ← Skeleton row
│  ██████████████░░░░░░░░░░░ │
│  ████████████████████░░░░░ │
│  ██████████░░░░░░░░░░░░░░░ │
└──────────────────────────────┘
```

- Pulse animation: `opacity 0.5 → 1.0`, 1.5s cycle
- Progressive loading: show partial results with progress bar for large datasets
- Chart skeletons: match chart dimensions with gray placeholder

## Empty States

Never show a blank rectangle.

```
┌──────────────────────────────┐
│                              │
│         📊 (icon)            │
│                              │
│    No results found          │  ← Primary message (lg, medium)
│    Try adjusting your        │  ← Secondary (sm, muted)
│    filters or creating       │
│    a new record.             │
│                              │
│    [ Clear Filters ]         │  ← Action button
│                              │
└──────────────────────────────┘
```

- Icon: relevant to the content type (not generic)
- Primary message: what's empty (lg, font-medium)
- Secondary: why + what to do (sm, text-muted)
- Action: button to resolve (clear filters, create new, import data)

## Error States

### Inline Error (chart/panel failure)
```
┌──────────────────────────────┐
│  ⚠ Failed to load chart.    │  ← Red-tinted border
│  Server returned 500.        │
│                              │
│  [ Retry ]  [ Show Details ] │
└──────────────────────────────┘
```

- Red-tinted left border or full border
- Icon + message + retry button
- "Show Details" expands stack trace for developers

### Toast Notification (non-blocking)
- Position: top-right, stacked
- Auto-dismiss: 5s for success, persistent for errors
- Max 3 visible, queue the rest

## Animation Budget

| Category | Duration | Easing |
|---|---|---|
| Micro-feedback (hover, toggle) | 100ms | ease-out |
| State change (expand, tab switch) | 200ms | ease-in-out |
| Entrance (modal, dropdown) | 200-300ms | ease-out |
| Exit (close, hide) | 150-200ms | ease-in |
| Layout shift (resize, sidebar) | 300ms | ease-in-out |
| Data transition (chart update) | 300-500ms | ease-in-out |

### Do NOT Animate
- Large data table redraws
- WebGL/Canvas chart updates
- Typing in search inputs
- Any animation >1x per second
- vis.js network during container CSS transitions

## KPI / Metric Card

```
┌────────────────────┐
│  Active Users      │  ← Label: xs, uppercase, muted
│  12,847            │  ← Value: xl, font-semibold, tabular-nums
│  ▲ 23% vs last wk  │  ← Delta: sm, green/red based on direction
└────────────────────┘
```

- Border: 1px solid `--border-default`
- Padding: md (12-16px)
- Background: `--surface-base`
- Width: equal distribution in flex container
- Hover: subtle shadow (xs)
