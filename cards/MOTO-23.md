# MOTO-23: manager watch keeps setting the statuses out of order

- Identifier: MOTO-23
- ID: 65a8bc37-a993-4658-b879-a927a66f7c6c
- URL: https://linear.app/gotte/issue/MOTO-23/manager-watch-keeps-setting-the-statuses-out-of-order
- State: Completed
- Priority: No priority
- Estimate: none
- Due date: none
- Assignee: linear@graham.lol
- Creator: linear@graham.lol
- Parent: none
- Children: none
- Labels: working
- Created: 2026-09-20T19:08:51.783Z
- Updated: 2026-09-20T19:17:43.285Z
- Completed: 2026-09-20T19:16:55.712Z

## Description

![Screenshot 2026-09-20 at 12.07.35 PM.png](https://uploads.linear.app/abd0504f-0da2-4d94-87b3-24c0d24d46e0/ed62093b-2e03-472d-a9b6-cf9dfe5bc381/70fefc46-fa87-481c-be67-dc219ce0bc58)

in the started group, the order should always be ready, working, review, then approved. but these keep getting reordered for some reason

### Screenshot — Screenshot 2026-09-20 at 12.07.35 PM.png

Linear team settings **Workflow** page for **Code Moto**. Header: `Linear / Gotte / Code Moto / Team settings`, tab **Workflow**.

Left nav: General, Issue statuses & automations (selected), Labels, Templates, Issue types, Recurring issues, SLAs, Notifications, Members, GitHub, GitLab, Asks.

Main heading **Issue statuses & automations**. Subtitle: "How should issues in Code Moto be organized and automated?"

**Triage** is on ("Triage incoming issues before they hit your workflow"). **Backlog** is on ("Give upcoming issues a dedicated status type").

**Started** section ("The team is actively working on it") lists these statuses, in this order:

- Review (yellow)
- Ready (yellow)
- Working (yellow)
- Approved (yellow)

Each row has a drag handle, status name, colored pill, and a three-dot menu.

**Completed** shows Completed (purple). **Canceled** shows Canceled (gray) and Duplicate (gray).

The screenshot is the bug: started statuses are Review, Ready, Working, Approved instead of Ready, Working, Review, Approved.

## Comments

### linear@graham.lol — 2026-09-20T19:14:16.454Z

- ID: 32760707-ccd4-4cc7-8eb7-1aa2b301adc8
- Updated: 2026-09-20T19:14:16.434Z

Watch was rewriting Linear workflow positions to 0..n on every startup. Linear keeps per-type ranks (0, 1000, 2000, 3000), so that kept shuffling the started group.

sync_statuses now only updates position when a type is actually out of order. If Ready, Working, Review, Approved are already in that order, Linear ranks are left alone.

PR: https://github.com/grahamotte/codemoto.org/pull/35

## Attachments

- [Keep Linear started statuses in Ready, Working, Review, Approved order](https://github.com/grahamotte/codemoto.org/pull/35)
