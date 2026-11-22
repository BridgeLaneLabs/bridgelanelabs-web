# bridgelanelabs-web

The home page for **[bridgelanelabs.com](https://bridgelanelabs.com)**: a black-and-white night bridge, and a deck where each project is a lane.

| Lane | Project | Link |
|---|---|---|
| Fast lane | Spadesys | https://spadesys.net |
| Bus lane | Cloud Co-op | https://cloud-op.com |
| Bike lane | Dent Lines | https://dentlines.bridgelanelabs.com |
| Bowling lane | Rant Face | https://rantface.bridgelanelabs.com |

## Run it locally

Needs only [Docker Desktop](https://www.docker.com/products/docker-desktop/).

```bash
docker compose up --build -d
```

Open **http://localhost:8100**. Health check: http://localhost:8100/health → `{"status":"ok"}`

Stop it: `docker compose down`

## How it's built

| Path | What |
|---|---|
| `site/` | The page itself: `index.html` and `assets/` (photo, logo) |
| `app/main.py` | A small FastAPI app that serves `site/` and `/health` |
| `Dockerfile` | Python 3.12 slim image, runs as a non-root user, with a built-in health check |
| `compose.yaml` | Local run config, bound to `127.0.0.1` only |
| `server/bootstrap.sh` | Turns a fresh Ubuntu VM into a standard Bridge Lane Labs host |
| `brand/` | Logos and GitHub profile assets (not shipped in the image) |

## How it ships

Local (Docker) → GitHub → review link → UAT sign-off → production on the Bridge Lane Labs server, served through a Cloudflare Tunnel (no open ports).
The deploy pipeline is being set up; see the Bridge Lane Labs runbook.

## Credits

Hero photograph by Richard "Zuppy" Zupsic.
