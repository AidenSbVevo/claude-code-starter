# Advanced Visualization Patterns

Heavy, specialized viewers. All share the same lifecycle discipline: dynamic `import()` to keep them out of the initial bundle, initialize into a ref, and dispose on unmount to avoid GPU/memory leaks. Wrap each in an error boundary with a skeleton fallback.

## Contents
- Three.js — 3D / WebGL scenes
- Vega-Lite — declarative chart grammar
- Cytoscape.js — network / graph diagrams
- deck.gl — geospatial & large point clouds

## Three.js — 3D / WebGL Scenes

For custom 3D scenes, model viewers, and GPU-rendered geometry. Prefer `@react-three/fiber` for declarative scenes; drop to the imperative API when you need fine control over the render loop or disposal.

```tsx
'use client';
import { useRef, useEffect } from 'react';

export function SceneViewer({ modelUrl, width = '100%', height = 500 }: {
  modelUrl: string; width?: string | number; height?: number;
}) {
  const containerRef = useRef<HTMLDivElement>(null);
  const disposeRef = useRef<(() => void) | null>(null);

  useEffect(() => {
    if (!containerRef.current) return;
    let cancelled = false;

    // Dynamic import — Three.js + loaders are large
    (async () => {
      const THREE = await import('three');
      const { GLTFLoader } = await import('three/examples/jsm/loaders/GLTFLoader');
      if (cancelled || !containerRef.current) return;

      const el = containerRef.current;
      const renderer = new THREE.WebGLRenderer({ antialias: true });
      renderer.setPixelRatio(window.devicePixelRatio);
      renderer.setSize(el.clientWidth, el.clientHeight);
      el.appendChild(renderer.domElement);

      const scene = new THREE.Scene();
      const camera = new THREE.PerspectiveCamera(50, el.clientWidth / el.clientHeight, 0.1, 1000);
      camera.position.set(0, 0, 5);
      scene.add(new THREE.AmbientLight(0xffffff, 0.8));

      const loader = new GLTFLoader();
      loader.load(modelUrl, (gltf) => !cancelled && scene.add(gltf.scene));

      let raf = 0;
      const tick = () => { renderer.render(scene, camera); raf = requestAnimationFrame(tick); };
      tick();

      disposeRef.current = () => {
        cancelAnimationFrame(raf);
        renderer.dispose();
        el.removeChild(renderer.domElement);
      };
    })();

    return () => { cancelled = true; disposeRef.current?.(); };
  }, [modelUrl]);

  return <div ref={containerRef} style={{ width, height, position: 'relative' }} />;
}
```

**Key patterns:**
- Always dynamic `import()` — Three.js plus loaders/controls is heavy
- Call `renderer.dispose()` and free geometries/materials on unmount
- Drive the loop with `requestAnimationFrame`; cancel it on cleanup
- Resize with a `ResizeObserver` → update camera aspect + `renderer.setSize`
- For most apps, `@react-three/fiber` + `@react-three/drei` removes this boilerplate

## Vega-Lite — Declarative Chart Grammar

When charts should be data-driven and serializable (dashboards where users build views, or specs stored as config), a JSON grammar beats hand-written render code.

```tsx
import { VegaLite } from 'react-vega';

const spec = {
  title: 'Value over time',
  width: 800,
  height: 200,
  data: { url: '/api/data/series.csv', format: { type: 'csv' } },
  mark: 'area',
  encoding: {
    x: { field: 'timestamp', type: 'temporal' },
    y: { field: 'value', type: 'quantitative' },
    color: { field: 'series', type: 'nominal' },
  },
} as const;

export function DeclarativeChart() {
  return <VegaLite spec={spec} actions={false} />;
}
```

**Key patterns:**
- One JSON spec drives everything — easy to store, template, or generate
- Marks: `area`, `line`, `bar`, `point`, `rect` (heatmap), `arc`
- Link views with shared `selection` params for synchronized zoom/pan/filter
- Layer/overlay by nesting specs in `layer: [...]`
- Responsive: set `width: 'container'` and size the parent

## Cytoscape.js — Network / Graph Diagrams

Dependency graphs, knowledge graphs, org charts, state machines, call graphs.

```tsx
'use client';
import { useRef, useEffect } from 'react';
import cytoscape from 'cytoscape';

export function NetworkGraph({ elements, onNodeClick }: {
  elements: cytoscape.ElementDefinition[];
  onNodeClick?: (id: string, data: any) => void;
}) {
  const containerRef = useRef<HTMLDivElement>(null);
  const cyRef = useRef<cytoscape.Core | null>(null);

  useEffect(() => {
    if (!containerRef.current) return;

    const cy = cytoscape({
      container: containerRef.current,
      elements,
      style: [
        {
          selector: 'node',
          style: {
            label: 'data(label)',
            'background-color': 'data(color)',
            width: 'data(size)',
            height: 'data(size)',
            'font-size': '10px',
            'text-valign': 'center',
            'text-halign': 'center',
          },
        },
        {
          selector: 'edge',
          style: {
            width: 'data(weight)',
            'line-color': '#d1d5db',
            'target-arrow-color': '#d1d5db',
            'target-arrow-shape': 'triangle',
            'curve-style': 'bezier',
            opacity: 0.6,
          },
        },
        {
          selector: 'node:selected',
          style: { 'border-width': 3, 'border-color': '#2563eb' },
        },
      ],
      layout: { name: 'cose', animate: true, animationDuration: 500 },
    });

    cy.on('tap', 'node', (evt) => {
      onNodeClick?.(evt.target.id(), evt.target.data());
    });

    cyRef.current = cy;
    return () => cy.destroy();
  }, [elements]);

  return <div ref={containerRef} style={{ width: '100%', height: 500 }} />;
}
```

**Key patterns:**
- Layout algorithms: `cose` (force-directed), `dagre` (hierarchical), `concentric`, `breadthfirst`
- `dagre` requires `cytoscape-dagre` extension: `cytoscape.use(dagre)`
- Fit to view: `cy.fit(padding)` after layout completes
- Batch updates: `cy.batch(() => { ... })` for performance
- Export: `cy.png()` or `cy.jpg()` for screenshots

## deck.gl — Geospatial & Large Point Clouds

Millions of points on a map, or any large 2-D/3-D scatter. Use `MapView` with a basemap for geographic data, `OrthographicView` for abstract 2-D layouts.

```tsx
'use client';
import { DeckGL } from '@deck.gl/react';
import { ScatterplotLayer } from '@deck.gl/layers';
import { OrthographicView } from '@deck.gl/core';

export function LargeScatter({ data, colorBy }: {
  data: { x: number; y: number; label: string; value: number; category: string }[];
  colorBy: 'category' | 'value';
}) {
  const colorMap: Record<string, [number, number, number]> = {
    'Category A': [230, 159, 0],
    'Category B': [86, 180, 233],
    'Category C': [0, 158, 115],
    'Category D': [213, 94, 0],
  };

  const layer = new ScatterplotLayer({
    id: 'points',
    data,
    getPosition: (d) => [d.x, d.y],
    getRadius: 3,
    getFillColor: (d) =>
      colorBy === 'category'
        ? colorMap[d.category] ?? [153, 153, 153]
        : [37, 99, 235, Math.floor(d.value * 255)],
    radiusMinPixels: 1,
    radiusMaxPixels: 8,
    pickable: true,
    autoHighlight: true,
    highlightColor: [255, 200, 0, 200],
  });

  return (
    <DeckGL
      views={new OrthographicView()}
      initialViewState={{ target: [0, 0, 0], zoom: 1 }}
      layers={[layer]}
      controller={true}
      getTooltip={({ object }) =>
        object && `${object.label}: ${object.value.toFixed(2)}\n${object.category}`
      }
    />
  );
}
```

**Key patterns:**
- `OrthographicView` for abstract 2-D layouts, `MapView` for geographic coordinates
- `ScatterplotLayer` for points, `HeatmapLayer` for density, `HexagonLayer` for aggregation
- `pickable: true` enables hover/click — adds overhead, disable for >500k points
- GPU filtering: `DataFilterExtension` for real-time subsetting without re-uploading data
- Multi-layer: stack a `BitmapLayer` background under the point layer
- Lasso selection: `@deck.gl-community/editable-layers` or a custom `PolygonLayer`

## Performance Notes

| Library | Bundle Size | Points | Dynamic Import? |
|---|---|---|---|
| Three.js | ~600KB | N/A | Yes, always |
| Vega-Lite | ~1MB | <100k | Yes, recommended |
| Cytoscape | ~300KB | <10k nodes | Optional |
| deck.gl | ~500KB | 50k-5M | Yes, recommended |

All should be wrapped in error boundaries and loaded with skeleton states.
