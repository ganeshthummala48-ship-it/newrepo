import uvicorn
import gradio as gr
from main import app as fastapi_app

# ── Gradio landing page (served at /ui) ──────────────────────────────────────
demo = gr.Interface(
    fn=lambda: "🌾 FarmerAI Backend API is live!",
    inputs=None,
    outputs="text",
    title="FarmerAI Backend API",
    description=(
        "FastAPI backend powering the FarmerAI mobile app.\n\n"
        "**Available endpoints** (explore via `/docs`):\n"
        "- `POST /detect-disease` — Plant disease detection (image upload)\n"
        "- `POST /recommend-crop` — ML crop recommendation\n"
        "- `POST /ask_ai` — Agricultural AI assistant (Cohere)\n"
        "- `GET  /health` — Health check\n"
    ),
)

# Mount Gradio UI onto our FastAPI app at /ui
# All original FastAPI routes remain at the root level
app = gr.mount_gradio_app(fastapi_app, demo, path="/ui")

# Start the combined server.
# NOTE: We use uvicorn.run() directly — do NOT call demo.launch().
# Calling demo.launch() here would start a second server and cause a port conflict.
# HF Spaces proxies whatever is running on port 7860.
if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=7860)
else:
    # When HF imports this module (sdk: gradio), we still need to start the server.
    # HF runs app.py as a script (not an import), so __main__ is always triggered.
    # This branch is a safety fallback for any edge-case import scenarios.
    import threading
    _server_thread = threading.Thread(
        target=lambda: uvicorn.run(app, host="0.0.0.0", port=7860),
        daemon=True
    )
    _server_thread.start()