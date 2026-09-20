# MOTO-14: archive cards from approved and cancelled

- Identifier: MOTO-14
- ID: e85aa6a4-ce4f-4228-a349-fe485cbad4d2
- URL: https://linear.app/gotte/issue/MOTO-14/archive-cards-from-approved-and-cancelled
- State: Completed
- Priority: No priority
- Estimate: none
- Due date: none
- Assignee: none
- Creator: linear@graham.lol
- Parent: none
- Children: none
- Labels: working
- Created: 2026-09-20T05:41:19.211Z
- Updated: 2026-09-20T07:14:36.908Z
- Completed: 2026-09-20T06:26:42.279Z

## Description

when cards enter into the last 2 columns: approved and cancelled we should 'archive'/delete them. here is how this should work.
this is 2 more branches for the manager trigger which spawn off agents to do the archival
for cards in approved, read all the info in the card and create a markdown file in cards/MOTO-15 for example. and that markdown should contain all of the prompts and comments and data from that card. if there are any assets like an image, then describe and or transcribe the image. put all of this in the markdown file for archival. create a PR with this new markdown file and merge it. additionally check for any worktrees left for this card and delete them. lastly delete the card.
for cards cancelled, just cleanup any worktrees and then delete the card.

also, this is more procedural, but each run of trigger, lets kickoff at most 1 pagent per step. so say if there is a bunch of cards in read or approved, just start working on one per trigger so that we space out the agents a little bit

## Comments

### linear@graham.lol — 2026-09-20T06:22:28.799Z

- ID: f00fe0c5-4fec-4fdd-8287-83362cafea97
- Updated: 2026-09-20T06:22:28.782Z

Added two manager trigger branches and limited each run to one agent per step.

- Completed cards: archive agent writes `cards/<id>.md` (prompts, comments, data, image descriptions), opens and merges a PR, removes leftover worktrees, and deletes the Linear card.
- Canceled cards: cleanup agent removes leftover worktrees and deletes the Linear card.
- Ready/approved merge behavior is unchanged; archive runs after merge moves a card to completed.

PR: https://github.com/grahamotte/codemoto.org/pull/13

## Attachments

- [Archive completed and canceled Linear cards](https://github.com/grahamotte/codemoto.org/pull/13)
