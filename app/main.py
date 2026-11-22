"""Bridge Lane Labs web: serves the lanes landing page plus a health check."""
from pathlib import Path

from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles

SITE_DIR = Path(__file__).resolve().parent.parent / "site"

app = FastAPI(title="Bridge Lane Labs", docs_url=None, redoc_url=None, openapi_url=None)


@app.get("/health")
def health() -> dict:
    """Used by Docker, the server and the deploy pipeline to confirm the app is up."""
    return {"status": "ok"}


# Everything else is the static site (index.html, assets/).
app.mount("/", StaticFiles(directory=SITE_DIR, html=True), name="site")
