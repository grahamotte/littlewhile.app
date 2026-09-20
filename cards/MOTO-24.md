# MOTO-24: Need a mise manger:sync task

- Identifier: MOTO-24
- ID: 2f4c6118-e623-4d3d-993e-90f65b8600d1
- URL: https://linear.app/gotte/issue/MOTO-24/need-a-mise-mangersync-task
- State: Completed
- Priority: No priority
- Estimate: none
- Due date: none
- Assignee: linear@graham.lol
- Creator: linear@graham.lol
- Parent: none
- Children: none
- Labels: working
- Created: 2026-09-20T19:16:45.789Z
- Updated: 2026-09-20T19:23:45.933Z
- Completed: 2026-09-20T19:23:12.239Z

## Description

right now mise manager:watch does some config on the project and then runs a looping watcher, i need a separate mise manager:sync task which just does the sync part and no triggers

## Comments

### linear@graham.lol — 2026-09-20T19:19:49.940Z

- ID: 1b725b4b-8032-4ec7-a183-12f84bc4cb0e
- Updated: 2026-09-20T19:19:49.922Z

Added `mise manager:sync`, which runs Linear status and tag sync without triggering work. `mise manager:watch` still syncs at startup via the same `Sync.call`. Merge guide now points at the new task. PR: https://github.com/grahamotte/codemoto.org/pull/37

## Attachments

- [Add mise manager:sync](https://github.com/grahamotte/codemoto.org/pull/37)
