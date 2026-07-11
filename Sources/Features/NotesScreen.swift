import SwiftUI

struct NotesScreen: View {
    @Bindable var model: NotesModel
    @State private var isAddingNote = false

    var body: some View {
        NavigationStack {
            Group {
                if model.notes.isEmpty {
                    ContentUnavailableView(
                        "No Notes Yet",
                        systemImage: "note.text",
                        description: Text("Capture something you want to remember.")
                    )
                } else {
                    List(model.notes) { note in
                        NoteRow(note: note) {
                            Task { await model.toggleCompletion(note) }
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                Task { await model.delete(note) }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            .accessibilityHint("Removes the note and offers an undo action")
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Quick Note")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isAddingNote = true
                    } label: {
                        Label("Add Note", systemImage: "square.and.pencil")
                    }
                    .accessibilityIdentifier("add-note")
                }
            }
            .safeAreaInset(edge: .bottom) {
                if let deleted = model.lastDeletedNote {
                    UndoBar(note: deleted) {
                        Task { await model.undoDelete() }
                    }
                }
            }
            .sheet(isPresented: $isAddingNote) {
                AddNoteSheet { text in
                    let added = await model.add(text: text)
                    if added { isAddingNote = false }
                }
            }
            .alert("Couldn’t Update Notes", isPresented: errorBinding) {
                Button("OK") { model.errorMessage = nil }
            } message: {
                Text(model.errorMessage ?? "Please try again.")
            }
            .task { await model.load() }
        }
        .tint(.blue)
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { model.errorMessage != nil },
            set: { if !$0 { model.errorMessage = nil } }
        )
    }
}

private struct NoteRow: View {
    let note: Note
    let toggle: () -> Void

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Button(action: toggle) {
                Image(systemName: note.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(note.isCompleted ? Color.green : Color.secondary)
            }
            .buttonStyle(.plain)
            .frame(minWidth: 44, minHeight: 44)
            .accessibilityLabel(note.isCompleted ? "Mark incomplete" : "Mark complete")

            Text(note.text)
                .foregroundStyle(note.isCompleted ? .secondary : .primary)
                .strikethrough(note.isCompleted)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(note.text), \(note.isCompleted ? "completed" : "not completed")")
    }
}

private struct UndoBar: View {
    let note: Note
    let undo: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text("Deleted \"\(note.text)\"")
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button("Undo", action: undo)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.bar)
        .accessibilityElement(children: .contain)
    }
}

private struct AddNoteSheet: View {
    let save: (String) async -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("What do you want to remember?", text: $text, axis: .vertical)
                    .lineLimit(3...8)
                    .accessibilityLabel("Note text")
            }
            .navigationTitle("New Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { Task { await save(text) } }
                        .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

#Preview {
    NotesScreen(model: NotesModel(repository: NoteRepository(fileURL: URL(filePath: "/tmp/quick-note-preview.json"))))
}
