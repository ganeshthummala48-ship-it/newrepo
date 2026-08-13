import os
import uvicorn
import gradio as gr
from main import app as fastapi_app

# Create a Gradio landing page interface
demo = gr.Interface(
    fn=lambda: "🌾 FarmerAI Backend Server is live and operational!",
    inputs=[],
    outputs="text",
    title="FarmerAI Backend API",
    description="FastAPI Backend for FarmerAI delivering ML inference (crop recommendation, disease prediction, fruit classification, weed detection) and AI chat services."
)

# Mount FastAPI application onto Gradio
app = gr.mount_gradio_app(fastapi_app, demo, path="/ui")

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 7860))
    uvicorn.run(app, host="0.0.0.0", port=port)