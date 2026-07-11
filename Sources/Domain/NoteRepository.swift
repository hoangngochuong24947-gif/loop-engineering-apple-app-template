import Foundation

actor NoteRepository {
    static let shared = NoteRepository(fileURL: NoteRepository.defaultFileURL)

    private let fileURL: URL
    private let now: @Sendable () -> Date
    private var notes: [Note]

    init(fileURL: URL, now: @escaping @Sendable () -> Date = Date.init) {
        self.fileURL = fileURL
        self.now = now
        self.notes = (try? Self.load(from: fileURL)) ?? []
    }

    func activeNotes() -> [Note] {
        notes
            .filter { !$0.isDeleted }
            .sorted { lhs, rhs in
                if lhs.isCompleted != rhs.isCompleted { return !lhs.isCompleted }
                return lhs.createdAt > rhs.createdAt
            }
    }

    @discardableResult
    func add(text: String) throws -> Note {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw NoteError.emptyText }
        let note = Note(id: UUID(), text: trimmed, createdAt: now(), completedAt: nil, deletedAt: nil)
        notes.append(note)
        try persist()
        return note
    }

    func toggleCompletion(id: UUID) throws {
        guard let index = notes.firstIndex(where: { $0.id == id && !$0.isDeleted }) else {
            throw NoteError.notFound
        }
        notes[index].completedAt = notes[index].completedAt == nil ? now() : nil
        try persist()
    }

    func delete(id: UUID) throws {
        guard let index = notes.firstIndex(where: { $0.id == id && !$0.isDeleted }) else {
            throw NoteError.notFound
        }
        notes[index].deletedAt = now()
        try persist()
    }

    func restore(id: UUID) throws {
        guard let index = notes.firstIndex(where: { $0.id == id && $0.isDeleted }) else {
            throw NoteError.notFound
        }
        notes[index].deletedAt = nil
        try persist()
    }

    private func persist() throws {
        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try JSONEncoder().encode(notes)
        try data.write(to: fileURL, options: .atomic)
    }

    private static func load(from fileURL: URL) throws -> [Note] {
        try JSONDecoder().decode([Note].self, from: Data(contentsOf: fileURL))
    }

    private static var defaultFileURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return base.appending(path: "QuickNote", directoryHint: .isDirectory)
            .appending(path: "notes.json")
    }
}

enum NoteError: LocalizedError {
    case emptyText
    case notFound

    var errorDescription: String? {
        switch self {
        case .emptyText: "A note needs some text."
        case .notFound: "That note is no longer available."
        }
    }
}
