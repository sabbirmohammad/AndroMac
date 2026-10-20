import Foundation

public enum KeyActionType: String, Codable, CaseIterable, Sendable {
    case tapCoordinate = "Tap Coordinate"
    case swipeDirection = "Swipe / D-Pad"
    case androidKeycode = "Keycode Event"
}

public struct KeyMapping: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var key: String
    public var actionType: KeyActionType
    public var xPercent: Double
    public var yPercent: Double
    public var swipeEndX: Double
    public var swipeEndY: Double
    public var androidKeycode: Int
    public var label: String

    public init(
        id: UUID = UUID(),
        key: String,
        actionType: KeyActionType,
        xPercent: Double = 0.5,
        yPercent: Double = 0.5,
        swipeEndX: Double = 0.5,
        swipeEndY: Double = 0.4,
        androidKeycode: Int = 0,
        label: String
    ) {
        self.id = id
        self.key = key
        self.actionType = actionType
        self.xPercent = xPercent
        self.yPercent = yPercent
        self.swipeEndX = swipeEndX
        self.swipeEndY = swipeEndY
        self.androidKeycode = androidKeycode
        self.label = label
    }
}

public struct KeymapProfile: Identifiable, Codable, Hashable, Sendable {
    public var id: String { name }
    public var name: String
    public var description: String
    public var mappings: [KeyMapping]

    public init(name: String, description: String, mappings: [KeyMapping]) {
        self.name = name
        self.description = description
        self.mappings = mappings
    }

    public static let presets: [KeymapProfile] = [
        KeymapProfile(
            name: "Action & FPS (WASD + Space)",
            description: "Standard WASD movement controls with Space jump and skill buttons",
            mappings: [
                KeyMapping(key: "W", actionType: .swipeDirection, xPercent: 0.20, yPercent: 0.75, swipeEndX: 0.20, swipeEndY: 0.65, label: "Forward"),
                KeyMapping(key: "S", actionType: .swipeDirection, xPercent: 0.20, yPercent: 0.75, swipeEndX: 0.20, swipeEndY: 0.85, label: "Backward"),
                KeyMapping(key: "A", actionType: .swipeDirection, xPercent: 0.20, yPercent: 0.75, swipeEndX: 0.15, swipeEndY: 0.75, label: "Left"),
                KeyMapping(key: "D", actionType: .swipeDirection, xPercent: 0.20, yPercent: 0.75, swipeEndX: 0.25, swipeEndY: 0.75, label: "Right"),
                KeyMapping(key: "Space", actionType: .tapCoordinate, xPercent: 0.85, yPercent: 0.75, label: "Jump / Fire"),
                KeyMapping(key: "Q", actionType: .tapCoordinate, xPercent: 0.80, yPercent: 0.60, label: "Skill 1"),
                KeyMapping(key: "E", actionType: .tapCoordinate, xPercent: 0.90, yPercent: 0.60, label: "Skill 2"),
                KeyMapping(key: "R", actionType: .tapCoordinate, xPercent: 0.85, yPercent: 0.88, label: "Reload / Ultimate")
            ]
        ),
        KeymapProfile(
            name: "D-Pad & Navigation",
            description: "Direct Android D-Pad keyevents for retro gaming and UI navigation",
            mappings: [
                KeyMapping(key: "↑", actionType: .androidKeycode, androidKeycode: 19, label: "DPad Up"),
                KeyMapping(key: "↓", actionType: .androidKeycode, androidKeycode: 20, label: "DPad Down"),
                KeyMapping(key: "←", actionType: .androidKeycode, androidKeycode: 21, label: "DPad Left"),
                KeyMapping(key: "→", actionType: .androidKeycode, androidKeycode: 22, label: "DPad Right"),
                KeyMapping(key: "Return", actionType: .androidKeycode, androidKeycode: 23, label: "Select / Center"),
                KeyMapping(key: "Escape", actionType: .androidKeycode, androidKeycode: 4, label: "Back")
            ]
        )
    ]
}
