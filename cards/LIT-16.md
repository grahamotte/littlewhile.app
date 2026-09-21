# LIT-16: Merge

- Identifier: LIT-16
- ID: 030e595e-3cd3-4f50-afc4-103b5a7e16b8
- URL: https://linear.app/gotte/issue/LIT-16/merge
- State: Completed
- Priority: No priority
- Estimate: none
- Due date: none
- Assignee: linear@graham.lol
- Creator: linear@graham.lol
- Parent: none
- Children: none
- Labels: working
- Created: 2026-09-21T05:32:29.707Z
- Updated: 2026-09-21T05:36:26.631Z
- Completed: 2026-09-21T05:36:22.606Z

## Description

Run the merge skill, so that we are up to date with the [../codemoto.org](<http://codemoto.org>) repo. 

After you have merged from codemoto, create a PR and merge it so that master is up to date. 

Add a comment with the recovery point when you get it, then add another comment when the merge is done with any informative details of the merge. 

You can then move this card directly to completed and skip the review and approved steps.

## Comments

### linear@graham.lol — 2026-09-21T05:34:47.786Z

- ID: 5a29f780-8e1f-4443-848a-ef7741c4bbab
- Updated: 2026-09-21T05:34:47.765Z

Merge recovery point: `a1babdf3d33cf300d24f4ed54a8ca9a11fde5785`

### linear@graham.lol — 2026-09-21T05:36:22.085Z

- ID: 7a1ee043-1fcb-4828-9bbc-4ea1b9756fdc
- Updated: 2026-09-21T05:36:22.064Z

Merged upstream Code Moto (`bcd90a3`) into `lit-16` (recovery point `a1babdf`). No conflicts.

Brought in Linear model/variant tags, `manager:syncall`, Linear sync colors/default tags, stop archiving completed/canceled cards, and the MOTO-29 archive. Repo-specific AGENTS.md kept. `mise test` passed.

PR: https://github.com/grahamotte/littlewhile.app/pull/11

Merged into master. `origin/master` is `434013e` (Code Moto `bcd90a3`). Master is up to date.

## Attachments

- [Merge latest Code Moto](https://github.com/grahamotte/littlewhile.app/pull/11)
