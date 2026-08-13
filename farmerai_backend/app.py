import os
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
    port = int(os.getenv("PORT", 7860))
    demo.launch(server_name="0.0.0.0", server_port=port)