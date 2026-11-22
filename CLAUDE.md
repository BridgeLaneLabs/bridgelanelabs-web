# bridgelanelabs-web — notes for Claude

The bridgelanelabs.com home page. Owner: Derek Augustine (Bridge Lane Labs, Pittsburgh).
Read `README.md` for what it is and `docs/WORKFLOW.md` for how every Bridge Lane Labs project ships. Follow the workflow; don't skip stages.

## How Derek wants to work
- Derek follows along in VS Code and approves changes. **Explain what you're about to do before doing it**, in plain words.
- Small steps. One change, show it, then the next.
- **Never commit or push without asking first.** Show `git status` / the diff, then wait for a yes.
- Work on a branch and open a pull request; don't commit straight to `main` once the repo has history.
- If something is unclear, ask. Don't guess at business decisions (pricing, names, what a project is).

## Run and check
- Normal:  `docker compose up --build -d`  → http://localhost:8100 , `/health` → `{"status":"ok"}`
- Review mode (live edits + shareable link): `./review.sh` (on Windows use the compose command inside it)
- A change is "done" only when it runs from a fresh clone.

## Rules
- No secrets in git. `.env` files stay local.
- Don't edit or delete anything in `archive/` (old versions kept on purpose; it's git-ignored).
- Keep the look: black-and-white night photo, skyline logo, lanes. Photo credit to Richard "Zuppy" Zupsic stays in the footer.
- Servers have no open web ports; traffic comes through Cloudflare Tunnel.
- Server setup lives in `server/bootstrap.sh`. Change the script, not the server by hand.

## Layout
- `site/` the page (`index.html`, `assets/`)
- `app/main.py` FastAPI app serving `site/` + `/health`
- `compose.yaml`, `compose.review.yaml`, `review.sh`, `Dockerfile`
- `docs/WORKFLOW.md` the shipping process; `server/` server setup; `brand/` logos
