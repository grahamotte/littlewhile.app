# MOTO-9: Merge guide

- Identifier: MOTO-9
- ID: f894be7f-8670-4c1b-93fe-49f730342145
- URL: https://linear.app/gotte/issue/MOTO-9/merge-guide
- State: Completed
- Priority: No priority
- Estimate: none
- Due date: none
- Assignee: none
- Creator: linear@graham.lol
- Parent: none
- Children: none
- Labels: working
- Created: 2026-09-20T05:41:17.631Z
- Updated: 2026-09-20T08:26:46.377Z
- Completed: 2026-09-20T08:26:03.397Z

## Description

i have several repo i need to run a merge in, however we have made a bunch of changes - can you create a doc which is a bit of a merge guide to the changes. two things i know will need to happen in each repo which branches off of codemoto: 1) cleanup the git remotes because we got rid of codeberg and 2) create linear cards from any current kanban cards and delete the kanban dir. im sure there are more things. investigate and create the doc

## Comments

### linear@graham.lol — 2026-09-20T08:18:44.247Z

- ID: e84503e1-c621-47c3-8a8d-1a8563ecbe37
- Updated: 2026-09-20T08:22:31.345Z

Added `docs/merge.md` for the first Code Moto cutover on existing downstream repos.

The guide covers:
- Cleaning Codeberg remotes and making GitHub `origin` / `upstream`
- Merging GitHub Code Moto by hand once (old `mise merge` still rewrites `upstream` to Codeberg)
- Env updates (drop Codeberg/OpenCode, add Linear/OpenRouter; `LINEAR_TEAM` is per app, not `MOTO`)
- Kanban → Linear mapping, then delete `kanban/`
- Drop leftover `commit` and `debug` skills; keep `prod-debug`
- Manager setup and what not to keep from Code Moto (`cards/MOTO-*`, `workflow-ok*`)

PR: https://github.com/grahamotte/codemoto.org/pull/30

### linear@graham.lol — 2026-09-20T08:22:31.311Z

- ID: d7c1c48f-c90a-41a9-9f8f-463d1eb7c9ec
- Updated: 2026-09-20T08:22:31.281Z

> * `cards/MOTO-*.md` — Code Moto's archived Linear issues

I would not try to delete these as more will just come, so lets leave them

> * `docs/workflow-ok.md`, `docs/workflow-ok-2.md`, `docs/workflow-ok-3.md` — manager workflow checks

lets just delete these files so forked repos dont have to deal with them

### linear@graham.lol — 2026-09-20T08:24:11.655Z

- ID: 15448365-25d5-4f1b-9b6a-1387c173b42c
- Updated: 2026-09-20T08:24:11.638Z

Addressed review comments on the merge guide.

- Incoming `cards/MOTO-*.md` stay; the guide no longer tells forks to drop them.
- Deleted `docs/workflow-ok.md`, `docs/workflow-ok-2.md`, and `docs/workflow-ok-3.md` so downstream merges do not pick them up.

PR: https://github.com/grahamotte/codemoto.org/pull/30

## Attachments

- [Add a merge guide for downstream Code Moto cutover](https://github.com/grahamotte/codemoto.org/pull/30)
