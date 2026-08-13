import gradio as gr
from main import app as fastapi_app

# Create a clean Gradio interface for the Hugging Face Space landing page
demo = gr.Interface(
    fn=lambda: "🌾 FarmerAI Backend Server is live and operational!",
    inputs=[],
    outputs="text",
    title="FarmerAI Backend API",
    description="FastAPI Backend for FarmerAI delivering ML inference (crop recommendation, disease prediction, fruit classification, weed detection) and AI chat services."
)

# Mount FastAPI application onto Gradio
app = gr.mount_gradio_app(fastapi_app, demo, path="/ui")