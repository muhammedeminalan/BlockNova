import Foundation

struct ComboEffectPresentation: Identifiable, Equatable {
    enum Level: Hashable {
        case line
        case double
        case mega
    }

    let id: UUID
    let level: Level
    let points: Int
    let styleVariant: Int
    let streak: Int
    let customTitle: String?

    init(
        id: UUID = UUID(),
        level: Level,
        points: Int,
        styleVariant: Int = 0,
        streak: Int = 1,
        customTitle: String? = nil
    ) {
        self.id = id
        self.level = level
        self.points = points
        self.styleVariant = styleVariant
        self.streak = max(1, streak)
        self.customTitle = customTitle
    }

    var title: String {
        if let customTitle {
            return customTitle
        }
        switch level {
        case .line: return "LINE!"
        case .double: return "DOUBLE!"
        case .mega: return "MEGA COMBO!"
        }
    }

    static func level(for lineCount: Int) -> Level {
        switch lineCount {
        case 1: return .line
        case 2: return .double
        default: return .mega
        }
    }

    var streakText: String? {
        guard streak >= 2 else { return nil }
        return "x\(streak) STREAK"
    }
}
