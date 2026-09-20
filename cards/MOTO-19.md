# MOTO-19: Stop the manager from reshuffling Linear workflow statuses

- Identifier: MOTO-19
- ID: 95c3e305-e692-44f1-b602-6c7646186a76
- URL: https://linear.app/gotte/issue/MOTO-19/stop-the-manager-from-reshuffling-linear-workflow-statuses
- State: Completed
- Priority: No priority
- Estimate: none
- Due date: none
- Assignee: none
- Creator: linear@graham.lol
- Parent: none
- Children: none
- Labels: none
- Created: 2026-09-20T06:28:31.544Z
- Updated: 2026-09-20T06:28:31.544Z
- Completed: 2026-09-20T06:28:31.593Z

## Description

The manager watcher rewrote Linear workflow state positions on every poll using per-type indexes. That collided with Linear global ranks and kept moving Approved after Ready. Sync statuses once at watch startup and assign positions from the STATUSES order.

## Comments

None.

## Attachments

- [PR #14](https://github.com/grahamotte/codemoto.org/pull/14)
