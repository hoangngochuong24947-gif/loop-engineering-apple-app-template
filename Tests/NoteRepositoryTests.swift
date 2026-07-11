import Foundation
import Testing
@testable import QuickNote

struct NoteRepositoryTests {
    @Test func addingTrimsTextAndPersistsAcrossRepositoryInstances() async throws {
        let fileURL = temporaryFileURL()
        let repository = NoteRepository(fileURL: fileURL, now: { Date(timeIntervalSince1970: 100) })

        let added = try await repository.add(text: "  Remember this  ")
        let reloaded = NoteRepository(fileURL: fileURL)
        let notes = await reloaded.activeNotes()

        #expect(added.text == "Remember this")
        #expect(notes == [added])
    }

    @Test func completionCanBeToggledBothWays() async throws {
        let repository = NoteRepository(fileURL: temporaryFileURL(), now: { Date(timeIntervalSince1970: 200) })
        let note = try await repository.add(text: "Pack charger")

        try await repository.toggleCompletion(id: note.id)
        #expect(await repository.activeNotes().first?.isCompleted == true)

        try await repository.toggleCompletion(id: note.id)
        #expect(await repository.activeNotes().first?.isCompleted == false)
    }

    @Test func deletionHidesNoteAndRestoreMakesItVisibleAgain() async throws {
        let repository = NoteRepository(fileURL: temporaryFileURL())
        let note = try await repository.add(text: "Temporary")

        try await repository.delete(id: note.id)
        #expect(await repository.activeNotes().isEmpty)

        try await repository.restore(id: note.id)
        #expect(await repository.activeNotes().map(\.text) == ["Temporary"])
    }

    @Test func emptyTextIsRejected() async {
        let repository = NoteRepository(fileURL: temporaryFileURL())

        await #expect(throws: NoteError.self) {
            try await repository.add(text: "  \n ")
        }
    }

    private func temporaryFileURL() -> URL {
        FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
            .appending(path: "notes.json")
    }
}
