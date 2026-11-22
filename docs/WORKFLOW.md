# Bridge Lane Labs — how a project ships

Every project follows the same path. No step is skipped, and each one has a clear "done when".

| # | Stage | Where | Who looks | Done when |
|---|---|---|---|---|
| 1 | **Build & review locally** | Your PC, Docker | You | `docker compose up --build -d` runs from a fresh clone; the site works at its local address; `/health` returns ok |
| 2 | **Commit & push** | GitHub (BridgeLaneLabs org) | You | Work is on a branch, pushed, with a pull request describing the change |
| 3 | **Review link** (informal) | Test server via Cloudflare quick tunnel | You and the customer | Customer has poked at it; fixes are looped back through steps 1–2 |
| 4 | **UAT** (formal) | Test server, stable URL behind Cloudflare Access login | Customer | Customer signs off that it meets their requirements. The exact build they approved is tagged. |
| 5 | **Production** | Prod server via named Cloudflare Tunnel | Everyone | The approved build (same image, not rebuilt) is live on the real domain; `/health` ok |

## Rules

- **Nothing reaches a server without passing step 1.** If it doesn't run locally from a fresh clone, it doesn't ship.
- **The customer approves a build, not a description.** What passes UAT is exactly what goes to production.
- **Servers have no open web ports.** All traffic arrives through Cloudflare Tunnel.
- **Secrets never go in git.** They live in `.env` files on the machine that needs them.
- **Rollback = redeploy the previous approved image.**

## Servers

| Name | Role | Notes |
|---|---|---|
| `bll-prod-01` | Production | Oracle A1, 1 OCPU / 6 GB, 50 GB boot + 100 GB data disk, Ubuntu 24.04 |
| existing Oracle server | Test / review / UAT | Oracle A1, 1 OCPU / 6 GB, 47 GB boot |

New servers are built with `server/bootstrap.sh`.

## Addresses

| Stage | Address pattern | Example |
|---|---|---|
| Local | `http://localhost:<port>` | http://localhost:8100 |
| Review | random Cloudflare quick-tunnel link | `https://some-words.trycloudflare.com` |
| UAT | `uat-<project>.bridgelanelabs.com`, always under bridgelanelabs.com, even for projects with their own domain (one level only, for the free certificate) | `uat.bridgelanelabs.com` for the main site, `uat-dentlines.bridgelanelabs.com`, `uat-spadesys.bridgelanelabs.com` |
| Production | the real domain or `<project>.bridgelanelabs.com` | `bridgelanelabs.com`, `dentlines.bridgelanelabs.com` |

## Deploy pipeline

Build once, promote the same image. Servers pull updates; nothing pushes into a server.

| When | What happens | Where |
|---|---|---|
| Push a branch / open a PR | GitHub Actions builds the image and checks `/health`. Red = it can't merge. | GitHub |
| Merge to `main` | The image is pushed to GHCR as `ghcr.io/bridgelanelabs/<repo>:sha-<commit>` and tagged `uat` | GitHub → GHCR |
| Every minute | The test server checks for a new `uat` image, pulls it, restarts. UAT address shows it. | Test server |
| Customer signs off | You press **Promote to production** (a manual GitHub Action) for that commit. It retags the same image `prod`; there's no rebuild. | GitHub → GHCR |
| Every minute | The prod server checks for a new `prod` image, pulls it, restarts. | Prod server |
| Something's wrong | Press **Promote to production** on the previous approved commit. | GitHub |

Each project on a server has:

- a folder `/opt/bll/<project>/` holding its compose files and `.env` (`TUNNEL_TOKEN`, and `IMAGE_TAG=uat` or `prod`)
- its own Cloudflare Tunnel container in its compose file, so projects never share a router or a network
- an entry in the server's update timer (set up by `server/bootstrap.sh`)

The same files go in every repo: `.github/workflows/ci.yml`, `.github/workflows/promote.yml`, `compose.prod.yaml`, `.env.example`.

## Cloudflare setup (once per project, per environment)

1. **Tunnel:** Zero Trust → Networks → Tunnels → Create, type Cloudflared, named `<project>-uat` or `<project>-prod`. Copy the token into that server's `.env`. Never paste it into git or a chat.
2. **Public hostname** on that tunnel: the address from the table above, service `HTTP`, URL `web:8000` (the container's name and port).
3. **UAT only, add a login:** Zero Trust → Access → Applications → Self-hosted, with the UAT address. Policy: allow the emails of you and the customer.

The domain must use Cloudflare's DNS. Cloudflare provides HTTPS; servers never get certificates.

## Standard extras (every project, from day one)

- **Protect `main`:** changes arrive only by pull request, and the CI build must pass.
- **Pin versions:** exact image versions (for example cloudflared), never `latest`.
- **Alerts:** an uptime check on each production address, plus a message when a deploy fails.
- **Backups:** for any project that stores data.

## New repositories

- **Owner:** the BridgeLaneLabs org, never a personal account.
- **Name:** short, lowercase, dashes, product first: `bridgelanelabs-web`, `dentlines-app`, `spadesys-api`.
- **Description:** one line on what it is and what it's built with.
- **Visibility:** public by default; private only while a work in progress.
- **Create it empty:** no README, .gitignore or license from GitHub. The project template supplies them.
- **License:** none by default (readable, not reusable). Add MIT only for code meant to be reused, and exclude brand assets and photos.
