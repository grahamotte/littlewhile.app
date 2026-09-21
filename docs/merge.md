# Merge guide

Use this for existing downstream repositories that still have Codeberg remotes and a `kanban/` board. Code Moto now uses GitHub as `origin`, Linear instead of kanban, and a `manager/` that starts agents from Linear cards.

This first merge is not a normal `$merge`. Do the remote and Linear setup below before relying on `mise merge` or `$merge-all`. Later merges follow `.agents/skills/merge/SKILL.md`.

## Before the merge

Work on `master` with a clean tree. Record `git rev-parse HEAD` as the recovery point.

### Git remotes

Codeberg is gone. Typical downstream remotes today:

| Remote | Typical current URL | Action |
| --- | --- | --- |
| `codeberg` | `ssh://git@codeberg.org/grahamotte/<app>.git` | Remove |
| `github` | `git@github.com:grahamotte/<app>.git` | Remove after `origin` is GitHub |
| `origin_backup` | GitHub | Remove if redundant with `origin` |
| `origin` | Missing, or still Codeberg | Set to the app's GitHub repo |
| `upstream` | Codeberg `codemoto.org` | Set to `git@github.com:grahamotte/codemoto.org.git` |
| `deployment` | DigitalOcean bare repo | Keep |

```sh
git remote remove codeberg
git remote remove github
git remote remove origin_backup

git remote add origin git@github.com:grahamotte/<app>.git
# or: git remote set-url origin git@github.com:grahamotte/<app>.git

git remote add upstream git@github.com:grahamotte/codemoto.org.git
# or: git remote set-url upstream git@github.com:grahamotte/codemoto.org.git
```

`origin` must be the app's GitHub repo. The manager fetches `origin`, and agents open PRs with `gh pr create`.

Do not run the **old** `mise merge` until this merge lands. That task still rewrites `upstream` to Codeberg. Merge GitHub Code Moto by hand this once:

```sh
git checkout master
git fetch upstream master
git merge --no-edit --no-ff upstream/master
```

After this merge, `mise merge` points `upstream` at GitHub and is safe.

### Environment

Update `.env.default` and the gitignored `.env.development` and `.env.production`. Merge does not edit the gitignored files.

Remove:

- `CODEBERG_REPO`
- `CODEBERG_TOKEN`
- `OPENCODE_TOKEN` (renamed)
- `PLANE_TOKEN`, `PLANE_WORKSPACE`, `PLANE_PROJECT` if present

Set:

```
GITHUB_REPO="git@github.com:grahamotte/<app>.git"
GITHUB_TOKEN=...
OPENROUTER_TOKEN=...
LINEAR_TOKEN=...
LINEAR_WORKSPACE=gotte
LINEAR_TEAM=<APP_KEY>
AGENT_RUNNER=openchamber
AGENT_MODEL=xai/grok-4.6
AGENT_VARIANT=high
```

`GITHUB_REPO` is this app, not `codemoto.org`. `LINEAR_TEAM` is this app's Linear team key, not `MOTO`. `LINEAR_WORKSPACE` is the Linear org `urlKey`.

## During the merge

Preserve downstream intent. Keep `AGENTS.md` **Repo Specific** and any extra skills that belong to the app.

Expect conflicts in `AGENTS.md`, `mise.toml`, `.env.default`, and skill directories. Incoming Code Moto replaces kanban instructions with Linear and GitHub sections, adds `manager/`, and copies env files plus `backend/db/schema.rb` into card worktrees.

After resolving conflicts, run `mise dependencies` then `mise test`.

## After the merge

### Skills

- Delete leftover `.agents/skills/commit/` (removed; commit when asked).
- Delete leftover `.agents/skills/debug/` (renamed to `prod-debug`; invoke with `$prod-debug`).
- Keep app-specific skills.

### Linear

Create a Linear team for the app. Put its key in `LINEAR_TEAM`. Configure Linear MCP for agents; use column names, never guessed state ids.

Columns, in order: `backlog`, `planned`, `ready`, `working`, `review`, `approved`, `completed`, `canceled`.

Run `mise manager:sync` to sync those workflow names and colors, and to create the default tags (`working`, `variant: …`, `model: …`). Run it only against the team this repo should own.

### Kanban cards

Create Linear issues from current kanban cards, then delete `kanban/`.

| Kanban column | Linear state |
| --- | --- |
| `1 - Problems to Solve` | `planned` |
| `2 - In Progress` | `ready` if the manager should pick it up, otherwise `working` |
| `3 - In Review` | `review` |
| `4 - Done` | Skip. Already shipped. |
| `5 - Won't Do` | Skip. |

Copy the card title, user value, problem description, notes, and prompts into the Linear description.

### Manager

OpenChamber must be listening on `http://127.0.0.1:57123`. `GITHUB_TOKEN` must work with `gh`. `origin` must be GitHub.

```sh
mise manager:sync
mise manager:watch
```

`ready` starts an agent in `../<repo>-<identifier>` after copying `.env.development`, `.env.production`, and `backend/db/schema.rb`. `approved` merges the GitHub PR. `completed` and `canceled` stay on the board; the manager does not start agents for them.

## Verify

1. `git remote -v` shows GitHub `origin` and `upstream`, no Codeberg remotes, and an unchanged `deployment` remote if the app has one.
2. `gh` can create a PR against `origin`.
3. `mise test` passes.
4. One Linear smoke card can move through the board without using team `MOTO`.

Later updates: `$merge` in the app, or `$merge-all` from `codemoto.org`. Never rebase, `mise rebase`, or force-push a downstream merge.
