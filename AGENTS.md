# AGENTS.md

## Code Moto

This repo is based on Code Moto. Code Moto is a basis/template repository that provides tools and patterns for downstream repositories. From a downstream repository, the basis repository is typically available at `../codemoto.org`. If the current repository is named `codemoto.org`, changes affect the Code Moto framework itself.

Repositories based on Code Moto may omit components or add their own. Backport broadly useful tools and changes to `codemoto.org` when practical.

The "Repo Specific" section blow contains rules specific to this repo only.

## Project Rules

1. Do not introduce bugs or regressions.
2. Before writing code, find analogous code in the repository and follow its established patterns.
3. Do not add comments to code. Preserve existing comments unless they are incorrect or obsolete.
4. Lint, type-check, and test code changes using the tasks defined in the root `mise.toml`.
5. Use root `mise` tasks instead of invoking underlying tools directly when an applicable task exists.
6. Do not create a canvas or visualization unless the user specifically requests one.
7. When opening a git worktree, copy `.env.development`, `.env.production`, and `backend/db/schema.rb` from the main checkout into the worktree before running tests or mise tasks.

## Ruby

- Use `.blank?` and `.present?` for presence checks instead of `.empty?`, `.nil?`, or truthiness checks.
- Do not use `sleep`; use an event- or state-based approach instead.
- Add trailing commas to multiline argument lists and collections.

## TypeScript

- Treat nullable values as both `null` and `undefined`; use `nullish()` in Zod schemas and check for both states.
- Use `pnpm`, not `npm`.
- Use `mise tsc` to type-check.
- Prefer Lodash utilities over custom equivalents when Lodash is already available.
- Use shadcn/ui components.
- Use Tailwind CSS for styling.

## Testing

- Never run network requests, system commands, or application sleeps in tests. Stub those boundaries every time.
- Do not stub other units in a unit test. Only stub network requests, system commands, and sleeps so the real local collaborators and full local surface are exercised together.
- Every business-logic file must have one corresponding unit test file. Source and test files are 1:1.
- Test each business-logic unit thoroughly. Configuration, generated files, framework shells, and other files without business logic do not need tests.
- After every code change, run the whole suite with `mise test`.
- Do not write integration tests.

## Linear

Work items live in Linear. Use the Linear MCP tools. Never guess a state id.

Columns, in order: `backlog`, `planned`, `ready`, `working`, `review`, `approved`, `completed`, `canceled`.

Cards being processed have the `working` tag. Remove it when you finish.

- Read a card: `get_issue` with the identifier in the URL (e.g. `MOTO-1`). Then `list_comments` with that issue's `id`.
- Comment: `save_comment` with `issueId` and `body`.
- Move a card: `save_issue` with `id` and `state` set to the column name.
- Link a PR: `save_issue` with `id` and `links: [{ url, title }]`.
- Tag a card: `save_issue` with `id` and `addedLabels` set to the tag names.
- Untag a card: `save_issue` with `id` and `removedLabels` set to the tag names.

## GitHub

Open pull requests on GitHub with `gh`, using `GITHUB_TOKEN` from the environment.

- Push the branch, then `gh pr create`.
- Merge with `gh pr merge`.

## File Structure

- `.agents/skills/` - Project-specific agent skills.
- `.env.*` - Environment configuration and secrets. Do not expose secret values.
- `apps/` - Mobile apps for iOS and Android.
- `apps/config.json` - Mobile app release configuration.
- `assets/` - Shared images and media.
- `backend/` - Ruby on Rails API server.
- `deploy/` - Backend, frontend, and mobile app deployment tooling.
- `docs/` - Project documentation in Markdown.
- `frontend/` - React website.
- `frontend/subdomains.json` - Website subdomain configuration.
- `gems/` - Shared Ruby gems.
- `manager/` - Linear issue polling and agent triggers.
- `scripts/` - General-purpose scripts.
- `mise.toml` - Project tooling and task definitions.

## Repo Specific

Little While is an iOS focus timer for setting aside a small, intentional block of time. It supports configurable timer durations and themes, persistent run history, system alarms with local-notification fallback, and a Live Activity displayed on the Lock Screen and Dynamic Island.
