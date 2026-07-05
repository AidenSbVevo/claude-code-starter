# React / Next.js Patterns

## Contents
- Project structure (Next.js App Router)
- TypeScript strict configuration
- Domain type patterns
- State management (Zustand + TanStack Query)
- Component design patterns
- Testing (Vitest + Playwright)
- Deployment (Docker + Vercel)

## Project Structure (Next.js App Router)

```
app/
├── layout.tsx                    # Root layout (providers, fonts)
├── page.tsx                      # Home page
├── globals.css                   # Tailwind + CSS variables
├── (dashboard)/                  # Route group
│   ├── layout.tsx                # Dashboard layout (sidebar + main)
│   ├── overview/page.tsx
│   ├── datasets/
│   │   ├── page.tsx              # List view
│   │   └── [id]/page.tsx         # Detail view
│   └── explorer/page.tsx
├── api/
│   └── trpc/[trpc]/route.ts
components/
├── ui/                           # shadcn/ui primitives
├── charts/                       # scatter, line, bar, etc.
├── data-table/                   # TanStack Table
├── graph/                        # network / tree viewers
├── map/                          # deck.gl / Leaflet viewers
├── layout/                       # sidebar, header, breadcrumbs
└── shared/                       # loading-states, error-boundary
lib/
├── hooks/                        # use-debounce, use-virtual-scroll
├── stores/                       # Zustand stores
├── utils/                        # cn.ts, format.ts, color.ts
├── types/                        # dataset.ts, metric.ts
└── validators/                   # Zod schemas
```

## TypeScript Configuration

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "forceConsistentCasingInFileNames": true,
    "paths": { "@/*": ["./src/*"] }
  }
}
```

## Domain Types

```typescript
// Effect-size vs significance comparison (A/B tests, statistical results)
interface ComparisonResult {
  label: string;
  effectSize: number;    // e.g. lift, coefficient, mean difference
  pValue: number;
  adjustedP: number;
  baseValue: number;
}

// A point in a 2-D embedding / projection
interface PointMetadata {
  id: string;
  x: number;             // embedding dim 1
  y: number;             // embedding dim 2
  category: string;
  cohort: string;
  batch: string;
  score: number;
  quality: number;
}

// A long-running job / run record
interface JobRecord {
  id: string;
  name: string;
  config: string | null;
  target: string;
  size: number;
  sizeUnit: 'KB' | 'MB' | 'GB';
  duration: number;
  durationUnit: 's' | 'm' | 'h';
  nItems: number;
  status: 'pending' | 'running' | 'complete' | 'failed';
}

// Branded types prevent ID mixups
type DatasetId = string & { readonly __brand: 'DatasetId' };
type UserId = string & { readonly __brand: 'UserId' };
```

## State Management

### Zustand (Global Client State)

```typescript
import { create } from 'zustand';
import { devtools } from 'zustand/middleware';
import { immer } from 'zustand/middleware/immer';

interface ViewState {
  selectedIds: Set<string>;
  filterCohort: string | null;
  colorBy: 'category' | 'cohort' | 'batch';
  highlightedIds: string[];
  toggleSelected: (id: string) => void;
  setFilter: (cohort: string | null) => void;
  setColorBy: (field: 'category' | 'cohort' | 'batch') => void;
  highlight: (ids: string[]) => void;
  reset: () => void;
}

export const useViewStore = create<ViewState>()(
  devtools(immer((set) => ({
    selectedIds: new Set<string>(),
    filterCohort: null,
    colorBy: 'category' as const,
    highlightedIds: [],
    toggleSelected: (id) => set((state) => {
      state.selectedIds.has(id)
        ? state.selectedIds.delete(id)
        : state.selectedIds.add(id);
    }),
    setFilter: (cohort) => set({ filterCohort: cohort }),
    setColorBy: (field) => set({ colorBy: field }),
    highlight: (ids) => set({ highlightedIds: ids }),
    reset: () => set({ selectedIds: new Set(), filterCohort: null, colorBy: 'category', highlightedIds: [] }),
  })), { name: 'view-store' })
);
```

### TanStack Query (Server State)

```typescript
import { useQuery, keepPreviousData } from '@tanstack/react-query';

const queryKeys = {
  datasets: {
    all: ['datasets'] as const,
    list: (filters: Record<string, unknown>) => ['datasets', 'list', filters] as const,
    detail: (id: string) => ['datasets', id] as const,
  },
  comparisons: {
    byDataset: (id: string) => ['comparisons', id] as const,
  },
};

export function useDatasets(filters?: Record<string, unknown>) {
  return useQuery({
    queryKey: queryKeys.datasets.list(filters ?? {}),
    queryFn: () => fetchDatasets(filters),
    staleTime: 5 * 60 * 1000,
    placeholderData: keepPreviousData,
  });
}
```

## Component Patterns

### Compound Component

```tsx
const RecordContext = React.createContext<JobRecord | null>(null);

export function RecordPanel({ record, children }: {
  record: JobRecord; children: React.ReactNode;
}) {
  return (
    <RecordContext.Provider value={record}>
      <div className="rounded-xl border bg-white shadow-sm p-6 space-y-4">{children}</div>
    </RecordContext.Provider>
  );
}
```

### Responsive Chart Container

```tsx
export function ChartContainer({ children, aspectRatio = 4/3, minHeight = 300 }: {
  children: (dims: { width: number; height: number }) => React.ReactNode;
  aspectRatio?: number; minHeight?: number;
}) {
  const ref = useRef<HTMLDivElement>(null);
  const [dims, setDims] = useState({ width: 600, height: 450 });
  useEffect(() => {
    if (!ref.current) return;
    const observer = new ResizeObserver(([entry]) => {
      const w = entry.contentRect.width;
      setDims({ width: w, height: Math.max(w / aspectRatio, minHeight) });
    });
    observer.observe(ref.current);
    return () => observer.disconnect();
  }, [aspectRatio, minHeight]);
  return <div ref={ref} className="w-full">{children(dims)}</div>;
}
```

## Testing

### Vitest + Testing Library

```typescript
import { render, screen } from '@testing-library/react';
import { describe, it, expect, vi } from 'vitest';

describe('SignificanceScatter', () => {
  it('renders SVG element', () => {
    const { container } = render(<SignificanceScatter data={mockData} />);
    expect(container.querySelector('svg')).toBeTruthy();
  });
  it('renders with empty data without crashing', () => {
    expect(() => render(<SignificanceScatter data={[]} />)).not.toThrow();
  });
});
```

### Playwright E2E

```typescript
test('scatter renders and is interactive', async ({ page }) => {
  await page.goto('/dashboard/datasets/ds-001');
  const svg = page.locator('svg').first();
  await expect(svg).toBeVisible();
  await point.hover();
  await expect(page.getByText(/effect size/i)).toBeVisible();
});
```

## Deployment

### Docker

```dockerfile
FROM node:20-alpine AS builder
WORKDIR /app
COPY package.json pnpm-lock.yaml ./
RUN corepack enable && pnpm install --frozen-lockfile
COPY . .
RUN pnpm build

FROM node:20-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static
EXPOSE 3000
CMD ["node", "server.js"]
```
