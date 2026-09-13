# Little While

The iPhone app lives in `apps/apple/App`. It works locally without an account or backend connection. Use `mise simulate iphone` to build and open it, and `mise test` to run all repository tests, including the Swift unit tests.

## Runs

`RunStore` owns a newest-first array of `FocusRun` values. Its first entry is always the current run; all other entries appear in History. A new installation starts with a ready 25-minute Standard run. Settings accepts whole minutes from 1 to 120 and stores the goal as seconds.

Set freezes and archives the previous run, then creates a ready run. Play records `startedAt` on the first start. Pause checkpoints fractional elapsed seconds. `resumedAt` records the latest running interval, allowing the timer to catch up after backgrounding or relaunch without relying on background execution. Completion stops at the goal. Start over preserves the old entry and creates a ready run with identical settings. It is available by holding the Play/Pause control, or through its VoiceOver action. The completed timer's control also creates a fresh run.

Runs are JSON encoded in UserDefaults under `littlewhile.runs.v1`. Unknown theme identifiers are retained. Recovery skips malformed records and repairs invalid bounds while retaining healthy history. History deletion cannot remove the current run.

On iOS 26 and later, the first Play requests permission for a true system alarm. AlarmKit schedules a one-time alarm at the run's deadline, so it can sound while the app is closed and through Silent mode or Focus. Pause cancels the alarm; resume schedules the remaining time. Returning to the app preserves an alarm that is already ringing, while Set or Start over cancels the previous run's alarm. Dismissing the alarm also clears that run's Live Activity.

If AlarmKit is unavailable, access is denied, or scheduling fails, the app falls back to its local completion notification. That fallback requires notification permission and respects the device's sound and Focus settings. A successfully scheduled system alarm suppresses the fallback to avoid duplicate sounds. Denying permissions leaves the timer usable. There are no automatic break cycles.

## Live Activity

Starting or resuming a run creates a Live Activity when allowed by iOS. It shows remaining time, progress, and status on the Lock Screen and in the Dynamic Island. Touch and hold the Dynamic Island for the expanded status; tap the activity to open the app. The view is neutral and does not change with the selected timer theme.

`TimerActivityWidget` is the embedded WidgetKit extension. It shares only `TimerActivityAttributes` with the app, and its clock and progress use system date-based rendering, so no background polling or per-second updates are needed. Pause freezes the displayed duration. The deadline marks the content stale, allowing the widget to show completion even while the app is suspended. The app ends the activity when it observes completion, and the alarm's Stop intent removes it when the alarm is dismissed.

`TimerCompanion` coordinates the Live Activity, AlarmKit, and fallback notification. All three OS boundaries have deterministic unit tests, including changes arriving during pending permission requests and scheduling. Relaunch reconciles existing activities; it does not recreate one the person dismissed. An explicit Play or resume can create a new activity.

## Adding a theme

1. Add a SwiftUI screen that takes `TimerSnapshot`. The snapshot is immutable and contains the run identity, goal, elapsed and remaining seconds, progress, and ready/running/paused/complete state.
2. Add a square preview view owned by the theme.
3. Register a `TimerTheme` in `TimerThemes.all` with a stable string ID, display name, subtitle, preferred control color scheme, preview, and screen factory.

The screen owns its entire visual hierarchy and background. Only the three controls are overlaid by `AppView`, in the top safe area. Keep critical content clear of the top 74 points. Themes may have their own playful interactions and local state, but receive no timer mutation callbacks. The Standard theme's clock, captions, and layout are all inside `StandardTimerView`; future themes need not share any of that structure.

The app resolves missing themes to Standard for rendering while preserving the saved identifier. Settings and History use the system appearance independently of the timer theme. Settings discovers previews directly from the registry, so adding a theme requires no changes to its layout.

## Platform behavior

The app supports iOS 18 and later. Shared controls use Apple's Liquid Glass APIs on iOS 26 and later, including iOS 27, with material controls on older versions. The Standard theme has a fixed light palette; system sheets still adapt to light and dark appearance. Timer updates are once per second, with no continuous animation or background polling.
