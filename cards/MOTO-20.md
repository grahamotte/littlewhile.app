# MOTO-20: Tag in-flight Linear cards as working so the manager does not enqueue a second runner

- Identifier: MOTO-20
- ID: aa2eb463-ac04-4bc3-98ab-e675994ea92b
- URL: https://linear.app/gotte/issue/MOTO-20/tag-in-flight-linear-cards-as-working-so-the-manager-does-not-enqueue
- State: Completed
- Priority: No priority
- Estimate: none
- Due date: none
- Assignee: none
- Creator: linear@graham.lol
- Parent: none
- Children: none
- Labels: working
- Created: 2026-09-20T07:09:47.659Z
- Updated: 2026-09-20T07:11:34.944Z
- Completed: 2026-09-20T07:09:47.682Z

## Description

The manager could enqueue another agent for a card already being processed if that work took longer than the 60s poll. Add a working tag immediately before starting an agent, skip tagged cards when picking work, and have agents remove the tag when they finish.

## Comments

None.

## Attachments

- [PR #16](https://github.com/grahamotte/codemoto.org/pull/16)
