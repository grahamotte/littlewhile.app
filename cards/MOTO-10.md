# MOTO-10: work prompt should consider kickbacks

- Identifier: MOTO-10
- ID: b76b604e-788e-4a4b-848b-4c08f9049413
- URL: https://linear.app/gotte/issue/MOTO-10/work-prompt-should-consider-kickbacks
- State: Completed
- Priority: No priority
- Estimate: none
- Due date: none
- Assignee: none
- Creator: linear@graham.lol
- Parent: none
- Children: none
- Labels: working
- Created: 2026-09-20T05:41:17.893Z
- Updated: 2026-09-20T07:16:38.659Z
- Completed: 2026-09-20T05:41:17.936Z

## Description

we have a work prompt:

```
def work_prompt(item)
  <<~PROMPT
    Do this Plane card: #{Plane.url(item)}
    1. Open a worktree.
    2. Hard set to the current origin main.
    3. Read the card and all comments.
    4. Implement the work.
    5. If you finish:
       - Commit
       - Open a GitHub PR with gh pr create using GITHUB_TOKEN
       - Link the PR to the card
       - Move the card to waiting for review
    6. If the card is blocked or the change is not possible:
       - Comment on the card explaining why
       - Move the card to groom
  PROMPT
end
```

this prompt is kinda focused on starting fresh, but there may be some situations where the agent did work and i had to give some correction, which i would do as a comment on the card.

so what we should do is have the agent leave a comment when they complete work and i will reply to that with any corrections.

additionally the prompt should be more clear, it should state these possibilities so the agent knows where it is working from.

the agent should always rebase before starting work, but there may already be existing commits

the agent is allowed to edit the existing commits or add its own

## Comments

None.

## Attachments

- [Keep existing agent work on kickbacks instead of resetting to main.](https://github.com/grahamotte/codemoto.org/pull/9)
