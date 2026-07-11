import AppIntents

struct AddNoteIntent: AppIntent {
    static let title: LocalizedStringResource = "Add Quick Note"
    static let description = IntentDescription("Saves a note privately on this device.")
    static let openAppWhenRun = false

    @Parameter(title: "Note")
    var text: String

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let note = try await NoteRepository.shared.add(text: text)
        return .result(dialog: "Saved \"\(note.text)\".")
    }
}

struct QuickNoteShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddNoteIntent(),
            phrases: [
                "Add a note in \(.applicationName)",
                "Save a quick note with \(.applicationName)"
            ],
            shortTitle: "Add Note",
            systemImageName: "square.and.pencil"
        )
    }
}
