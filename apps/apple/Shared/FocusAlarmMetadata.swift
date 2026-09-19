import Foundation
#if os(iOS) && !targetEnvironment(macCatalyst)
import AlarmKit

@available(iOS 26.0, *)
nonisolated struct FocusAlarmMetadata: AlarmMetadata {
    var runID: UUID
}
#endif
