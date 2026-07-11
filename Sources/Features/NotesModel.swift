import Foundation
import Observation

@MainActor
@Observable
final class NotesModel {
    private let repository: NoteRepository
    var notes: [Note] = []
    var errorMessage: String?
    var lastDeletedNote: Note?

    init(repository: NoteRepository) {
        self.repository = repository
    }

    func load() async {
        notes = await repository.activeNotes()
    }

    func add(text: String) async -> Bool {
        do {
            try await repository.add(text: text)
            await load()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func toggleCompletion(_ note: Note) async {
        await perform { try await repository.toggleCompletion(id: note.id) }
    }

    func delete(_ note: Note) async {
        do {
            try await repository.delete(id: note.id)
            lastDeletedNote = note
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func undoDelete() async {
        guard let note = lastDeletedNote else { return }
        do {
            try await repository.restore(id: note.id)
            lastDeletedNote = nil
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func perform(_ operation: () async throws -> Void) async {
        do {
            try await operation()
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
