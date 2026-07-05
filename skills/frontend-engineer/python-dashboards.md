# Python Dashboard Patterns

## Contents
- Dash (Plotly) — callback-based dashboards
- Streamlit — rapid data exploration
- Gradio — ML model demos

## Dash (Plotly)

### Core Architecture

```python
from dash import Dash, html, dcc, Input, Output, State, callback_context, no_update
import dash_bootstrap_components as dbc

app = Dash(__name__, external_stylesheets=[dbc.themes.DARKLY])
app.layout = html.Div([
    dcc.Store(id="app-state", data={}),
    dcc.Interval(id="poll-interval", interval=10_000),
    html.Div(id="main-container"),
])
```

### Layout Patterns

- Nested `html.Div` with `className` for CSS styling
- `dcc.Store` for client-side state (JSON-serializable)
- `dcc.Interval` for polling/auto-refresh
- `dbc.Row` / `dbc.Col` for grid layouts, or pure CSS flex

### Callbacks

```python
@app.callback(
    Output("result", "children"),
    Input("submit-btn", "n_clicks"),
    State("input-field", "value"),
    prevent_initial_call=True,
)
def handle_submit(n_clicks, value):
    if not n_clicks:
        return no_update
    return f"Result: {value}"
```

### Clientside Callbacks (Performance-Critical)

```python
app.clientside_callback(
    """
    function(selectedId) {
        // DOM manipulation without server round-trip
        document.querySelectorAll('.item').forEach(el => {
            el.classList.toggle('selected', el.id === selectedId);
        });
        return window.dash_clientside.no_update;
    }
    """,
    Output("dummy", "children"),
    Input("selected-id", "data"),
)
```

### CSS Theming (assets/style.css)

```css
:root {
    --bg-0: #0c0a09;
    --bg-1: #1c1917;
    --text-1: #f5f5f4;
    --accent: #818cf8;
    --green: #10b981;
    --red: #f87171;
}
[data-theme="light"] {
    --bg-0: #fafaf9;
    --bg-1: #ffffff;
    --text-1: #1c1917;
}
```

### Flask Routes (Serving Custom Content)

```python
@app.server.route("/reports/<node_id>")
def serve_report(node_id):
    report_path = get_report_path(node_id)
    if not report_path:
        abort(404)
    return send_file(report_path, mimetype="text/html")
```

### Common Patterns

- **Pattern-matching callbacks**: `Input({"type": "item", "index": ALL}, "n_clicks")`
- **Real-time filtering**: `debounce=False` on search inputs
- **Flex layout scroll**: wrapper div needs `flex: 1 1 0%; min-height: 0; overflow: hidden`
- **vis.js integration**: inject via `assets/tree.js`, communicate via hidden `dcc.Input`
- **vis.js + CSS transitions**: disable `autoResize` during container transitions, re-enable after

### Deployment

```bash
gunicorn app:server -b 0.0.0.0:8050 -w 4
# or for development:
python -m my_dashboard --data-dir /path/to/data --port 8050
```

---

## Streamlit

### Quick Dashboard

```python
import streamlit as st
import pandas as pd
import plotly.express as px

st.set_page_config(page_title="Data Explorer", layout="wide")
st.title("Data Explorer")

with st.sidebar:
    uploaded = st.file_uploader("Upload data", type=["csv", "parquet"])
    color_by = st.selectbox("Color by", ["category", "cohort", "batch"])

if uploaded:
    df = pd.read_parquet(uploaded) if uploaded.name.endswith("parquet") else pd.read_csv(uploaded)
    col1, col2 = st.columns([2, 1])
    with col1:
        fig = px.scatter(df, x="dim1", y="dim2", color=color_by)
        fig.update_layout(template="plotly_white")
        st.plotly_chart(fig, use_container_width=True)
    with col2:
        st.metric("Total rows", f"{len(df):,}")
```

### Key Patterns

- `st.cache_data` for data loading, `st.cache_resource` for models
- `st.session_state` for persistent state across reruns
- `st.components.v1.html()` for custom HTML/JS
- `st.tabs()` for multi-section layouts

---

## Gradio

### ML Model Interface

```python
import gradio as gr

def predict(features_csv, config_text):
    data = np.loadtxt(features_csv.name, delimiter=",")
    with torch.inference_mode():
        result = model(torch.tensor(data).unsqueeze(0))
    return {"prediction": result.tolist()}

demo = gr.Interface(
    fn=predict,
    inputs=[gr.File(label="Feature matrix"), gr.Textbox(label="Config")],
    outputs=gr.JSON(label="Result"),
    title="Model Predictor",
)
demo.launch()
```

### Complex Layouts

```python
with gr.Blocks() as demo:
    with gr.Tab("Predict"):
        input_file = gr.File()
        output_json = gr.JSON()
        btn = gr.Button("Run")
        btn.click(predict, inputs=[input_file], outputs=[output_json])
    with gr.Tab("Explore"):
        gr.Plot(value=fig)
```
