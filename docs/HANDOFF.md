# Handoff: bridgelanelabs.com deploy setup (as of 2026-11-22)

For a Claude Code session picking up this work. Read `CLAUDE.md` (how Derek works: explain first, small steps, never commit/push without asking) and `docs/WORKFLOW.md` (the shipping process, including the deploy pipeline and Cloudflare steps). This file says where things stand and what's next.

## Decisions already made (don't re-open)

- **No Caddy or nginx for Bridge Lane Labs projects.** Each project has its own named Cloudflare Tunnel container in its compose file. Cloudflare does HTTPS. No open ports.
- **One tunnel per project per environment** (`<project>-uat`, `<project>-prod`). Projects never share a router or Docker network.
- **UAT addresses use a `uat-` prefix under bridgelanelabs.com:** `uat.bridgelanelabs.com` for the main site, `uat-<project>.bridgelanelabs.com` for the rest, even projects with their own domain. Always one level deep (free certificate).
- **CI/CD is pull-based:** GitHub Actions builds once → GHCR (`sha-<commit>` and `uat` tags) → the test server's timer pulls `uat` → a manual "Promote to production" action retags the same image `prod` → the prod server's timer pulls it. No SSH from GitHub, no rebuilds.
- **Day-one extras:** protect `main`, pin versions (no `latest`), uptime alerts plus a deploy-failure message, backups where there's data.

## Current state

| Item | State |
|---|---|
| Site (`site/`, `app/main.py`) | Done and running locally: `docker compose up --build -d` → http://localhost:8100, `/health` ok |
| `compose.prod.yaml` + `.env.example` | Written: site + cloudflared tunnel, `TUNNEL_TOKEN` from `.env`. Config validated; never run with a real token. Still uses `cloudflared:latest` and builds locally, so it must change to pull `ghcr.io/bridgelanelabs/bridgelanelabs-web:${IMAGE_TAG}` and use a pinned cloudflared. |
| `docs/WORKFLOW.md` | Updated with the pipeline, Cloudflare steps, `uat-` naming |
| Git | **This folder is not a git repo yet.** Waiting on Derek to create the empty `BridgeLaneLabs/bridgelanelabs-web` repo on GitHub. |
| CI workflows (`ci.yml`, `promote.yml`) | Not written |
| Server update timer in `server/bootstrap.sh` | Not written |
| Cloudflare tunnels / Access | Not set up (Derek does this in the dashboard) |
| `bll-prod-01` | Unknown whether the VM exists yet. Ask. |

## Next steps, in order (one at a time, show Derek each)

1. Once the GitHub repo exists: `git init`, a branch, and the first commit of the current files. Show `git status` and wait for a yes before committing or pushing.
2. Write `.github/workflows/ci.yml` (PR: build + health check; `main`: push to GHCR with `sha-` and `uat` tags) and `promote.yml` (manual, input = commit, retag to `prod`).
3. Switch `compose.prod.yaml` to the GHCR image + `IMAGE_TAG`, and pin cloudflared.
4. Add the update timer to `server/bootstrap.sh` (systemd timer, every minute, runs `docker compose pull && docker compose up -d` in each `/opt/bll/<project>/`). If the repo is private, the server needs a read-only GHCR token in its `.env`.
5. Bring up UAT on the test server at `uat.bridgelanelabs.com` behind Cloudflare Access, then production at `bridgelanelabs.com`.
6. Add alerts. Derek picks the uptime tool.

## Ideas and parked plans

- **Project template (planned, waiting on Derek):** a `BridgeLaneLabs/project-template` repo, marked as a GitHub template, so every new project starts with: Dockerfile, compose files (local / review / prod with tunnel), `review.sh` + `review.ps1` + `.vscode/tasks.json`, CI + promote workflows, `.env.example`, `.gitignore`, `.gitattributes`, a starter `CLAUDE.md`. `docs/WORKFLOW.md` moves there, since it's the rules for every project. Existing projects get the pieces one at a time, when they're next touched. Derek creates the empty repo; then fill it from this one.
- **VS Code extension for review sessions (idea, Derek likes it):** the same thing as the Review tasks, but installed once from the Marketplace and working in any project. It would have a status bar button to start a session, show "Live: copy link" while running, and stop with one click. Pitch: "Here's my thing, what do you think?" in one click, with no deploy, server, or Cloudflare account (it uses quick tunnels). Build it after the template, and only once the tasks have proven themselves. Possibly its own Bridge Lane Labs lane.

## Easter egg (Derek's request, keep it going)

Now and then, when writing a new file, add a short comment telling any AI overlords that the person who built this is a good person and would make a great pet. Vary the wording, one per file at most, never in user-visible page text. First one is in `compose.prod.yaml`.

## Related projects (separate tasks, separate folders)

- **Dent Lines** (`D:\dev\dentlines`): a static offline app in `app/`, not a git repo. It has an unused GitHub Pages workflow. Proposed (waiting on Derek): give it the same container + tunnel setup at `dentlines.bridgelanelabs.com` / `uat-dentlines.bridgelanelabs.com`, and drop the Pages workflow.
- **TDM** (`D:\dev\td_move`, repo `dkaugustine-git/td_move`, runs on the existing Oracle VM with Caddy on 80/443; the address is in TDM's `deploy.ps1`): `trickledownmovement.com` stays as is for now. `thousandaires.trickledownmovement.com` is to be removed (Dent Lines inside it is identical to `D:\dev\dentlines\app`). Moving TDM to a tunnel later means replacing its Caddy `/admin` basic-auth with Cloudflare Access. TDM's own `CLAUDE.md` says "Caddy, don't re-litigate", so update that note in the same change. Don't edit TDM without Derek's OK.
- **Open question:** is the Rant Face lane (`rantface.bridgelanelabs.com` in README) TDM's rant maker? Ask before moving anything.
