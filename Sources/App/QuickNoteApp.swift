import SwiftUI

@main
struct QuickNoteApp: App {
    @State private var model = NotesModel(repository: .shared)

    var body: some Scene {
        WindowGroup {
            NotesScreen(model: model)
        }
    }
}
