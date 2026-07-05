# Data Visualization Patterns

## Contents
- Recharts (simple charts)
- D3 (custom, full control)
- Canvas 2D (1k-50k points)
- Plotly (Python)
- vis.js (network / tree graphs)
- Performance patterns (Web Workers, streaming)

## Tier 1: Recharts (Simple, Fast)

```tsx
'use client';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip,
         ResponsiveContainer, ReferenceLine } from 'recharts';

export function MetricLineChart({ data, threshold }: {
  data: { input: number; value: number }[]; threshold?: number;
}) {
  // Log-scale the x-axis when inputs span orders of magnitude
  const logData = data.map(d => ({ ...d, logInput: Math.log10(d.input) }));
  return (
    <ResponsiveContainer width="100%" height={300}>
      <LineChart data={logData}>
        <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
        <XAxis dataKey="logInput" tickFormatter={v => Math.pow(10, v).toFixed(2)} />
        <YAxis domain={[0, 120]} />
        <Tooltip />
        <Line type="monotone" dataKey="value" stroke="#2563eb" strokeWidth={2} />
        {threshold && <ReferenceLine x={Math.log10(threshold)} stroke="#dc2626" strokeDasharray="5 5" />}
      </LineChart>
    </ResponsiveContainer>
  );
}
```

## Tier 2: D3 (Custom, Full Control)

### Effect-Size vs Significance Scatter

A general pattern for statistical comparisons (A/B tests, feature importance): effect size on the x-axis, `-log10(p)` on the y-axis, with threshold lines splitting significant positive/negative from non-significant.

```tsx
'use client';
import { useRef, useEffect, useMemo } from 'react';
import * as d3 from 'd3';

export function SignificanceScatter({ data, effectThreshold = 1, pThreshold = 0.05,
  onPointClick, highlighted = [], width = 600, height = 450 }: SignificanceScatterProps) {
  const svgRef = useRef<SVGSVGElement>(null);
  const margin = { top: 20, right: 20, bottom: 50, left: 60 };

  const plotData = useMemo(() =>
    data.map(d => ({
      ...d,
      negLog10P: -Math.log10(Math.max(d.adjustedP, 1e-300)),
      category: d.adjustedP < pThreshold && d.effectSize > effectThreshold ? 'positive'
              : d.adjustedP < pThreshold && d.effectSize < -effectThreshold ? 'negative' : 'ns',
    })), [data, effectThreshold, pThreshold]);

  useEffect(() => {
    if (!svgRef.current) return;
    const svg = d3.select(svgRef.current);
    svg.selectAll('*').remove();
    // ... scales, axes, points, labels, threshold lines
    // Color map: { positive: '#dc2626', negative: '#2563eb', ns: '#d1d5db' }
    // Highlighted points: larger radius, label offset
  }, [plotData, highlighted, onPointClick]);

  return <svg ref={svgRef} width={width} height={height} />;
}
```

**Key D3 patterns:**
- `useRef` for SVG element, `useMemo` for data transforms and scales
- `selectAll('*').remove()` at start of effect for clean redraw
- Draw `ns` points behind significant ones (paint order = z-order)
- Tooltip via separate `div` with absolute positioning

## Tier 3: Canvas 2D (1k-50k Points)

### 2-D Embedding Scatter

```tsx
export function EmbeddingCanvas({ data, colorBy, width = 700, height = 600 }: EmbeddingCanvasProps) {
  const canvasRef = useRef<HTMLCanvasElement>(null);

  // Batch rendering by color for performance
  useEffect(() => {
    const ctx = canvasRef.current?.getContext('2d');
    if (!ctx) return;
    const dpr = window.devicePixelRatio || 1;
    canvas.width = width * dpr;
    canvas.height = height * dpr;
    ctx.scale(dpr, dpr);

    // Group points by color, render each group in one beginPath/fill cycle
    const groups = new Map<string, number[]>();
    for (const [color, indices] of groups) {
      ctx.fillStyle = color;
      ctx.globalAlpha = 0.6;
      ctx.beginPath();
      for (const i of indices) {
        ctx.moveTo(sx(data[i].x) + r, sy(data[i].y));
        ctx.arc(sx(data[i].x), sy(data[i].y), r, 0, Math.PI * 2);
      }
      ctx.fill();
    }
  }, [data, colorBy]);
}
```

## Plotly (Python)

```python
import plotly.express as px
import plotly.graph_objects as go

# Quick 2-D embedding scatter
fig = px.scatter(df, x="dim1", y="dim2", color="category",
                 opacity=0.6, template="plotly_white")

# Effect-size vs significance scatter with thresholds
fig = go.Figure()
fig.add_trace(go.Scatter(x=df.effect_size, y=-np.log10(df.adjusted_p), mode='markers',
    marker=dict(color=df.color, size=3, opacity=0.5)))
fig.add_hline(y=-np.log10(0.05), line_dash="dash", line_color="gray")
fig.add_vline(x=1, line_dash="dash", line_color="gray")
fig.add_vline(x=-1, line_dash="dash", line_color="gray")
```

## vis.js (Network / Tree Graphs)

### Integration with Dash

```javascript
// assets/tree.js — vis.js Network for hierarchical tree/DAG visualization
var network = new vis.Network(container, { nodes, edges }, {
  layout: {
    hierarchical: { direction: "UD", sortMethod: "directed", levelSeparation: 80 }
  },
  physics: {
    hierarchicalRepulsion: { springLength: 80, nodeDistance: 100 },
    stabilization: { iterations: 100, fit: true },
  },
});

// CRITICAL: disable autoResize during CSS transitions
network.setOptions({ autoResize: false });
// Re-enable + fit after transition completes
setTimeout(() => {
  network.setOptions({ autoResize: true });
  network.redraw();
  network.fit({ animation: { duration: 400 } });
}, 450);
```

**Key vis.js patterns:**
- `stabilizationIterationsDone` → disable physics, fit to view
- Single click → update Dash hidden input via `dash_clientside.set_props`
- Hash-based guard to prevent unnecessary re-initialization
- `MutationObserver` to detect Dash layout re-renders

## Performance: Web Workers

```typescript
// data-processor.worker.ts
self.onmessage = (event) => {
  const { type, data, params } = event.data;
  switch (type) {
    case 'filter': {
      const arr = new Float64Array(data);
      const filtered = arr.filter(v => v > params.threshold);
      self.postMessage({ type: 'result', data: filtered.buffer }, [filtered.buffer]);
      break;
    }
  }
};
```

## Performance: Virtual Scrolling

```tsx
import { useVirtualizer } from '@tanstack/react-virtual';

const virtualizer = useVirtualizer({
  count: data.length,
  getScrollElement: () => parentRef.current,
  estimateSize: () => 36,  // row height
  overscan: 20,
});
```

## Performance: Streaming Data

```typescript
export function useStreamingData<T>(fetchFn, chunkSize = 10000) {
  // Load data in chunks, updating state progressively
  // Show partial results as they arrive
  // Use `await new Promise(r => setTimeout(r, 0))` between chunks for UI updates
}
```
