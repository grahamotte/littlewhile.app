# MOTO-22: triggerall mise task

- Identifier: MOTO-22
- ID: ce3d0a40-1de5-443c-97a4-b21c449d56e8
- URL: https://linear.app/gotte/issue/MOTO-22/triggerall-mise-task
- State: Completed
- Priority: No priority
- Estimate: none
- Due date: none
- Assignee: linear@graham.lol
- Creator: linear@graham.lol
- Parent: none
- Children: none
- Labels: working
- Created: 2026-09-20T19:04:36.177Z
- Updated: 2026-09-20T19:18:43.751Z
- Completed: 2026-09-20T19:17:50.267Z

## Description

we have a mise manager:trigger, can you also add a special mise manager:triggerall ? what this does is finds all repos forked off on codemoto in the parent directory (or rather that have a mise manager:trigger task), including the current [codemoto.org](<http://codemoto.org>) one, and for all of those we cd into the directory and run mise manager:trigger -- so is like a single trigger all codemoto apps command

## Comments

### linear@graham.lol — 2026-09-20T19:09:51.467Z

- ID: c743b023-0187-4b45-bcbc-60939ae8831e
- Updated: 2026-09-20T19:09:51.246Z

Added `mise manager:triggerall`. It scans sibling directories of the current checkout, keeps git repos whose `mise.toml` defines `manager:trigger` (including this Code Moto repo), skips git worktrees, and runs `mise manager:trigger` in each. PR: https://github.com/grahamotte/codemoto.org/pull/34

## Attachments

- [Add manager:triggerall mise task](https://github.com/grahamotte/codemoto.org/pull/34)
