# MOTO-21: an errored happend in one of the forked repos so we nee dot backport this change

- Identifier: MOTO-21
- ID: 007a8898-dec4-4d0a-a47f-5df09f4fc836
- URL: https://linear.app/gotte/issue/MOTO-21/an-errored-happend-in-one-of-the-forked-repos-so-we-nee-dot-backport
- State: Completed
- Priority: No priority
- Estimate: none
- Due date: none
- Assignee: linear@graham.lol
- Creator: linear@graham.lol
- Parent: none
- Children: none
- Labels: working
- Created: 2026-09-20T09:15:43.921Z
- Updated: 2026-09-20T09:24:49.694Z
- Completed: 2026-09-20T09:23:26.230Z

## Description

![Screenshot 2026-09-20 at 2.15.08 AM.png](https://uploads.linear.app/abd0504f-0da2-4d94-87b3-24c0d24d46e0/d40118b7-576b-40d3-bb5d-9befbc86f39a/aee85e55-c0f1-4ab0-b593-f8e3c1db49df)

### Screenshot — Screenshot 2026-09-20 at 2.15.08 AM.png

OpenCode session titled **lol-6** in `/Users/graham/Code/graham.lol`. The user prompt is:

```
an error happened, can you investigate and see if its a code issue
```

The assistant is investigating an OpenCode `before_run` hook. Visible terminal output includes:

```
[before_run] $ bundle exec ruby scripts/agent/before.rb
Copied /Users/graham/Code/graham.lol/.env.development to /var/folders/pl/cs9_cyrn1wq6m5csh9t8v0_40000gn/T/opencode/graham.lol-lol-6/.env.development
Copied /Users/graham/Code/graham.lol/.env.production to /var/folders/pl/cs9_cyrn1wq6m5csh9t8v0_40000gn/T/opencode/graham.lol-lol-6/.env.production
Copied /Users/graham/Code/graham.lol/backend/db/schema.rb to /var/folders/pl/cs9_cyrn1wq6m5csh9t8v0_40000gn/T/opencode/graham.lol-lol-6/backend/db/schema.rb
```

The assistant then lists `/Users/graham/Code/graham.lol` and reports those copied env/schema files are missing from the listed directory.

Conclusion in the screenshot: `scripts/agent/before.rb` copies `.env.development`, `.env.production`, and `backend/db/schema.rb` into the OpenCode tmp workspace (`/var/folders/.../T/opencode/graham.lol-lol-6`), but the agent session is still running against the original checkout, so it cannot see the copied files.

## Comments

### linear@graham.lol — 2026-09-20T09:19:56.598Z

- ID: e78bc7da-bd6e-4096-88a7-cfdf1966b8ca
- Updated: 2026-09-20T09:19:56.498Z

Backported the graham.lol lol-6 agent fix into Code Moto.

`Agent` now sets `PWD` to the tmp workspace and passes `--dir` to `opencode run`, so files written in `before_run` are visible to the agent. Tests updated to match.

PR: https://github.com/grahamotte/codemoto.org/pull/32

## Attachments

- [Point opencode at the agent tmp workspace](https://github.com/grahamotte/codemoto.org/pull/32)
