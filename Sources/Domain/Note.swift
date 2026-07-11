import Foundation

struct Note: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    var text: String
    let createdAt: Date
    var completedAt: Date?
    var deletedAt: Date?

    var isCompleted: Bool { completedAt != nil }
    var isDeleted: Bool { deletedAt != nil }
}
