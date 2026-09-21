# MOTO-29: completed and canceled cleaners should use master

- Identifier: MOTO-29
- ID: 2ac28717-6afa-45fa-97db-be8f45912d1e
- URL: https://linear.app/gotte/issue/MOTO-29/completed-and-canceled-cleaners-should-use-master
- State: Completed
- Priority: No priority
- Estimate: none
- Due date: none
- Assignee: linear@graham.lol
- Creator: linear@graham.lol
- Parent: none
- Children: none
- Labels: working
- Created: 2026-09-21T05:24:28.872Z
- Updated: 2026-09-21T05:30:59.619Z
- Completed: 2026-09-21T05:30:00.533Z

## Description

we have 2 tasks that happens on manager:trigger which when a card is completed we archive the card as a .md and delete it or if it was canceled we just delete the card in linear.

this kind of task should not use a worktree, and it doesn't. the issue is that it uses a PR and a branch to commit the markdown change. this means that we leave the current head on a branch like `archive-lol-19`

this kinda sucks because it means if I am looking at code or doing stuff, i will be behind.

I think I have changed my mind on this, we should no longer archive cards like this, lets just stop doing this.

and delete the cards directory.

so in the new state of things, we dont trigger agents for completed and canceled. cards just make it in there and stay forever.

## Comments

### linear@graham.lol — 2026-09-21T05:27:45.786Z

- ID: 1f143daa-ff3f-4902-84f9-fa223a49f2c6
- Updated: 2026-09-21T05:27:45.768Z

Stopped completed and canceled manager agents. Cards in those columns stay on the board instead of being archived to markdown or deleted. Removed the `cards/` directory so archive PRs no longer leave the checkout on branches like `archive-moto-19`.

PR: https://github.com/grahamotte/codemoto.org/pull/46

## Attachments

- [Stop archiving completed and canceled Linear cards](https://github.com/grahamotte/codemoto.org/pull/46)
