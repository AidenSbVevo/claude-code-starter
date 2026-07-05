# Design System — Tokens & Theming

## Color System

### Neutral Scale (warm stone, not pure gray)
```
50: #F5F5F4    100: #E7E5E4    200: #D6D3D1    300: #A8A29E
400: #78716C   500: #57534E    600: #44403C     700: #292524
800: #1C1917   900: #0C0A09
```

### Primary (interactive)
```
Blue: #3B82F6 → #2563EB (hover) → #1D4ED8 (active)
```

### Semantic (same meaning everywhere — non-negotiable)
```
Error / Danger:    #DC2626 (red-600)
Warning:           #F59E0B (amber-500)
Success:           #16A34A (green-600)
Info / Primary:    #2563EB (blue-600)
Neutral / Muted:   #D1D5DB (gray-300)
```

### Diverging (signed values — deltas, gains/losses, above/below baseline)
```
Positive:  #DC2626 (red)    Negative:  #2563EB (blue)    Zero / null:  #D1D5DB
```
A two-hue diverging scale (not a rainbow) is the correct encoding for any value that is signed around a midpoint. Pick the sign→hue mapping once and keep it fixed across every chart.

### Categorical (Okabe-Ito, colorblind-safe)
```
#E69F00 (orange)    #56B4E9 (sky)       #009E73 (teal)
#D55E00 (vermilion) #CC79A7 (pink)      #0072B2 (blue)
#F0E442 (yellow)    #999999 (gray)
```

Use for categories, series, segments, cohorts. Never use rainbow.

### Tailwind Extension
```typescript
colors: {
  data:   { pos: '#dc2626', neg: '#2563eb', zero: '#d1d5db', highlight: '#f59e0b' },
  series: { a: '#E69F00', b: '#56B4E9', c: '#009E73', d: '#D55E00', e: '#CC79A7' },
}
```

### CSS Variables (for vanilla CSS / non-Tailwind stacks)
```css
:root {
  --color-pos: #dc2626;
  --color-neg: #2563eb;
  --color-zero: #d1d5db;
  --color-highlight: #f59e0b;
  --color-success: #16a34a;
  --color-primary: #3b82f6;
  --color-primary-hover: #2563eb;
}
```

## Typography

### Font Pairings

| Context | Display | Body | Mono | Aesthetic |
|---|---|---|---|---|
| Refined minimal | Instrument Sans | Inter | JetBrains Mono | Linear-like |
| Technical authority | DM Sans | IBM Plex Sans | IBM Plex Mono | Bloomberg-like |
| Warm editorial | Source Sans 3 | Source Sans 3 | Source Code Pro | Docs / long-form |
| Modern geometric | Geist | Geist | Geist Mono | Vercel-like |

### Rules
- Never use more than 4 font sizes on a single view
- Emphasize inline entities (names, keys, tags) with one consistent treatment — pick italic OR mono and apply it everywhere
- Numbers in data views use `tabular-nums` / `font-variant-numeric: tabular-nums`
- Line height for dense UI: 1.3–1.4
- Letter-spacing for uppercase labels: +0.05em
- Mono font for: metrics, counts, IDs and codes, timestamps, code

### Scale
```
xs:   11px  — footnotes, tertiary labels
sm:   13px  — table cells, metadata, secondary text
base: 14px  — body text, primary content
lg:   16px  — section headers, card titles
xl:   20px  — page titles
2xl:  24px  — dashboard header (rarely used)
```

## Spacing

4px base unit. Two modes:

| Token | Dense (4px) | Comfortable (8px) |
|---|---|---|
| xs | 4px | 4px |
| sm | 8px | 8px |
| md | 12px | 16px |
| lg | 16px | 24px |
| xl | 24px | 32px |
| 2xl | 32px | 48px |

Dense mode for: data tables, control panels, sidebars.
Comfortable mode for: marketing pages, onboarding, settings.

## Border Radius

```
sm:   4px  — buttons, inputs, badges
md:   6px  — cards, panels
lg:   8px  — modals, dropdowns
full: 9999px — avatars, status dots ONLY
```

Never use `rounded-full` on cards or buttons. It looks childish.

## Shadows

Reserve for interactive/floating elements. Not every card needs a shadow.

```
xs:  0 1px 2px rgba(0,0,0,0.04)
sm:  0 1px 3px rgba(0,0,0,0.06), 0 1px 2px rgba(0,0,0,0.04)
md:  0 4px 6px rgba(0,0,0,0.05), 0 2px 4px rgba(0,0,0,0.04)
lg:  0 10px 15px rgba(0,0,0,0.05), 0 4px 6px rgba(0,0,0,0.03)
```

Use shadow for: dropdowns, popovers, modals, floating toolbars.
Don't use shadow for: static cards, panels, list items.

## Dark Mode

Dark mode is NOT "invert everything." It requires intentional design.

### Surface Hierarchy (reverses from light mode)
```
Darkest = base background → lighter = elevated
```

### Token Mapping
```css
[data-theme="dark"] {
  --surface-base: #1C1917;
  --surface-sunken: #0C0A09;
  --surface-raised: #292524;
  --text-primary: #F5F5F4;
  --text-secondary: #A8A29E;
  --text-tertiary: #78716C;
  --border-default: #292524;
  --border-strong: #44403C;
  --color-pos: #EF4444;   /* slightly brighter red */
  --color-neg: #60A5FA;   /* slightly brighter blue */
}
```

### Rules
- Text: off-white (#E7E5E4 or #F5F5F4), never pure white #FFF
- Colors: desaturate 10-15% on dark backgrounds
- Semantic colors: stay recognizable with brightness adjustments
- Charts: grid lines become subtle light (#292524), backgrounds #1C1917
- Borders: lighter-on-dark (#292524 default, #44403C emphasis)

## Icon System

- Use Lucide icons (MIT, tree-shakeable, consistent)
- Size: 16px in dense UI, 20px in comfortable, 24px standalone
- Stroke width: 1.5px (default)
- Color: match text color of surrounding context
- Don't use icons without text labels except in well-established patterns (close, menu, settings)
