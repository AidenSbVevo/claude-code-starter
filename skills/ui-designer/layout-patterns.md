# Layout Patterns

## Canonical Analytics Dashboard

```
┌─────────────────────────────────────────────────────┐
│  ▪ Logo    Search (⌘K)         ◯ User   ⚙ Settings │  ← Header: 48px
├────────┬────────────────────────────────────────────┤
│        │  Breadcrumb: Reports > Weekly Summary      │
│ NAV    │  ┌─────────┐ ┌─────────┐ ┌─────────┐      │  ← KPI strip
│        │  │ Metric  │ │ Metric  │ │ Metric  │      │
│ Over.  │  └─────────┘ └─────────┘ └─────────┘      │
│ Report │  ┌─────────────────┬───────────────┐       │
│ Users  │  │  Primary viz    │  Side panel   │       │  ← Main content
│ Billng │  │  (chart, map,   │  (controls,   │       │
│        │  │   heatmap)      │   metadata)   │       │
│        │  ├─────────────────┴───────────────┤       │
│        │  │  Data table (virtual scroll)    │       │  ← Detail table
│        │  └─────────────────────────────────┘       │
└────────┴────────────────────────────────────────────┘
```

**Rules:**
- Header: 48px fixed
- Sidebar: 240px expanded / 56px collapsed (icons only)
- Content: max-width 1440px, centered
- KPI strip: 3-5 metric cards, equal width
- Primary + side panel: 60/40 or 70/30 split
- Data table below primary viz, full width

## Split View (Linked Exploration)

```
┌────────────────────┬────────────────────┐
│   Scatter / Map    │   Detail Chart     │
│   (click points)   │   (click bars)     │
├────────────────────┴────────────────────┤
│   Synced Data Table (highlights match)  │
└─────────────────────────────────────────┘
```

**Key interaction:** Clicking a point in the scatter highlights the matching row and bar. Lasso/box selection in one view filters the other. Linked brushing is the primary pattern.

## Master-Detail (Browsing)

```
┌──────────────┬──────────────────────────┐
│  Item list   │  Detail panel            │
│  (sorted,    │  (full metadata,         │
│   filtered,  │   embedded charts,       │
│   searchable)│   action buttons)        │
│              │                          │
│  ► Item A    │  Slide-in from right     │
│    Item B    │  or fixed side panel     │
│    Item C    │                          │
└──────────────┴──────────────────────────┘
```

Click an item → detail slides in without navigation. Use slide-over panels, not modals.

## Three-Panel (Explorer Pattern)

```
┌────────┬──────────────────┬─────────────┐
│ Node   │  Tree / Network  │  Inspector  │
│ List   │  Visualization   │  Panel      │
│ (side) │  (centre)        │  (detail)   │
│        │                  │             │
│ filter │  vis.js / D3     │  metadata   │
│ search │  interactive     │  charts     │
│ sort   │                  │  actions    │
└────────┴──────────────────┴─────────────┘
```

**Transitions:** Centre panel collapses when inspector opens. Use CSS transitions (350ms ease-in-out). Disable vis.js `autoResize` during transitions, re-enable after 450ms.

## Command Palette (⌘K) — Mandatory for Power Users

```
┌─────────────────────────────────────┐
│  🔍 Search records, actions...      │
├─────────────────────────────────────┤
│  Recent                             │
│    Weekly Summary — Report          │
│    ORD-4821 — Order                 │
│  ─────────────────────────────────  │
│  Actions                            │
│    Toggle dark mode                 │
│    Export data                       │
│    Clear filters                    │
└─────────────────────────────────────┘
```

Features: keyboard navigation (↑↓ Enter Esc), recent searches, fuzzy matching, categorized results, shortcut hints.

## Responsive Strategy

Desktop-first for data-dense tools (power users work on large monitors).

| Breakpoint | Strategy |
|---|---|
| 3xl (1920px+) | Max-width content, sidebar pinned, all panels visible |
| xl (1280px) | Full layout with sidebar |
| lg (1024px) | Sidebar collapses to icons |
| md (768px) | Sidebar → bottom tabs or hidden |
| sm (640px) | Single column, stacked panels |

### Rules
- Charts: minimum width 400px, scroll horizontally below that
- Tables: scroll horizontally with pinned first column
- Split views: stack vertically below lg
- Dense/comfortable mode toggle available to user
- Command palette works at all breakpoints

## Panel Transitions

### Expand/Collapse Pattern
```css
.panel {
  transition: flex 0.35s ease-in-out, width 0.35s ease-in-out, opacity 0.35s ease-in-out;
}
.panel.collapsed {
  flex: 0 0 0px;
  width: 0;
  opacity: 0;
  overflow: hidden;
}
```

### Slide-Over Panel
```css
.slide-over {
  position: fixed;
  right: 0;
  top: 0;
  height: 100vh;
  width: 480px;
  transform: translateX(100%);
  transition: transform 0.3s ease-out;
  z-index: 50;
}
.slide-over.open {
  transform: translateX(0);
}
```

### Backdrop
```css
.backdrop {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.3);
  opacity: 0;
  transition: opacity 0.2s ease;
  z-index: 40;
}
.backdrop.visible {
  opacity: 1;
}
```
