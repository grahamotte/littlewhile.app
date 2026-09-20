# MOTO-17: better worktree support

- Identifier: MOTO-17
- ID: 634800a4-9e99-4e06-8c3f-c89f5655f3e2
- URL: https://linear.app/gotte/issue/MOTO-17/better-worktree-support
- State: Completed
- Priority: No priority
- Estimate: none
- Due date: none
- Assignee: none
- Creator: linear@graham.lol
- Parent: MOTO-16 (optimize agent initial run)
- Children: none
- Labels: working
- Created: 2026-09-20T05:53:43.745Z
- Updated: 2026-09-20T07:13:36.385Z
- Completed: 2026-09-20T06:10:26.882Z

## Description

![Screenshot 2026-09-19 at 10.50.03 PM.png](https://uploads.linear.app/abd0504f-0da2-4d94-87b3-24c0d24d46e0/4d425447-7419-46dd-9ba2-28ba27e99524/96abc4c4-c526-4fb8-b904-23c540706ef2)

![Screenshot 2026-09-19 at 10.50.53 PM.png](https://uploads.linear.app/abd0504f-0da2-4d94-87b3-24c0d24d46e0/58965028-9429-4b64-9897-1c721deb1675/e3d5c1bb-77a5-4468-b414-fc40147a9791)

(Backend tests hung (missing schema.rb in the worktree). Manager tests already passed in ~0.5s.)

this error happens running the tests and they hang forever.

we also commonly dont copy over the .env files so there's a whole loop where the agent tries to run something, it fails, and then they need to debug and copy - we should just do this upfront

### Screenshot 1 — Screenshot 2026-09-19 at 10.50.03 PM.png

OpenCode session on `moto-16` in `/Users/graham/Code/codemoto.org`. The assistant is running `mise test`. The terminal shows:

```
[test] $ bundle exec rails db:test:prepare
bin/rails aborted!
ActiveRecord::EnvironmentMismatchError: You are attempting to modify a database that was last run in `development` environment. (ActiveRecord::EnvironmentMismatchError)
You are running in `test` environment. If you are sure you want to continue, run `bin/rails db:environment:set RAILS_ENV=test`
```

Tasks reported: `lint` success, `tsc` success, `test` running. A `debug` subagent is spawned to inspect the hanging test.

### Screenshot 2 — Screenshot 2026-09-19 at 10.50.53 PM.png

Continuation of the same session. The `debug` subagent reports:

- `mise test` is stuck on backend `rails db:test:prepare`.
- Manager tests already passed in ~0.5s.
- Failure is `ActiveRecord::EnvironmentMismatchError`: the test DB was last marked `development`, while the command is running in `test`.
- Suggested fix: `bin/rails db:environment:set RAILS_ENV=test`.
- The hang is `db:test:prepare` waiting on that abort rather than the test suite itself.

The assistant then inspects `backend/db/schema.rb` and `backend/config/database.yml`. `schema.rb` is gitignored (`/backend/db/schema.rb`). `database.yml` uses `codemoto_development` / `codemoto_test` SQLite files.

Conclusion in the screenshot: backend tests hang because `schema.rb` is missing in the worktree, so Rails tries to rebuild the test DB from a development-tagged database. Manager tests already passed.

## Comments

### linear@graham.lol — 2026-09-20T06:06:24.924Z

- ID: 2ef2e175-9f19-4926-a9f8-b0ac591536d5
- Updated: 2026-09-20T06:06:24.907Z

Opened a worktree, rebased onto origin/master, and landed this in https://github.com/grahamotte/codemoto.org/pull/11.

The manager now creates the card worktree before the agent starts, copies `.env*` (except `.env.default`) and `backend/db/schema.rb` from the main checkout, and starts the session in that directory. That avoids the missing-schema hang on `mise test` and the copy-env-after-failure loop. Kickbacks reuse the existing worktree and refresh those files. Merge agents run from the card worktree when it already exists.

## Attachments

- [Copy env files and schema.rb into card worktrees](https://github.com/grahamotte/codemoto.org/pull/11)
