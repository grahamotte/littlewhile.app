# LIT-11: Add customizable focus and break timers

- Identifier: LIT-11
- ID: c380a86c-74e3-47dd-976b-d44efede1fd3
- URL: https://linear.app/gotte/issue/LIT-11/add-customizable-focus-and-break-timers
- State: Completed
- Priority: No priority
- Estimate: none
- Due date: none
- Assignee: linear@graham.lol
- Creator: linear@graham.lol
- Parent: none
- Children: none
- Labels: working
- Created: 2026-09-20T23:43:53.593Z
- Updated: 2026-09-21T00:39:55.222Z
- Completed: 2026-09-21T00:39:39.908Z

## Description

right now we just have 1 time for our pomodoro app, but this should actually be 2 times: a main focus period of time and a smaller rest time period.

Add separate controls for focus time and rest time. Keep the existing focus-time slider and add a smaller rest-time slider, defaulting to 5 minutes. Both should be fully customizable.

the min value for the focus slider is 1 min, while the min value for the rest slider is 0 min.

as for data migration, lets consider the current ones as just focus time with a break time of 0.

also themes will need to support focus vs rest timer, so here's the changes for the 2 themes we have so far:

* boring: run one circle/clock for focus, then it resets for the rest time
* mr smiles: time in the bottom is focus and then rest. during rest time the eyes should be stars

lastly, another change to support this is there there is 2 timers/alarms scheduled 1 for the focus and then another for the rest timer. we should schedule these both upfront when we start where the focus one is the focus amount and the break timer is focus + break amount, since its after.

if we pause, then cancel both alarms and reschedule them for the appropriate time when we start again.

## Comments

### linear@graham.lol — 2026-09-21T00:24:41.509Z

- ID: 7e6ede96-cd11-484e-8171-55c90a40a629
- Updated: 2026-09-21T00:24:41.490Z

Settings now have a focus slider (min 1 min) and a rest slider (min 0 min, default 5 min for new runs). Existing saved runs keep their focus time with rest 0.

Boring resets the clock ring for rest. Mr Smiles shows rest remaining at the bottom and star eyes during rest.

Focus and rest alarms (plus notification fallbacks) are both scheduled up front. Pause cancels them; resume reschedules remaining time.

PR: https://github.com/grahamotte/littlewhile.app/pull/7

## Attachments

- [Add customizable focus and rest timers](https://github.com/grahamotte/littlewhile.app/pull/7)
