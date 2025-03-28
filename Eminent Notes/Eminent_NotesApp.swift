import SwiftUI

@main
struct Eminent_NotesApp: App {
    // Environment objects that provide data to all views
    @StateObject private var noteListViewModel = NoteListViewModel()
    @StateObject private var folderViewModel = FolderViewModel()
    
    // Inject Core Data persistence controller
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(noteListViewModel)
                .environmentObject(folderViewModel)
        }
        
        #if os(macOS)
        // macOS-specific menu commands
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Note") {
                    let newNote = noteListViewModel.createNote(folder: folderViewModel.currentFolder)
                    if let note = newNote {
                        noteListViewModel.selectedNote = note
                    }
                }
                .keyboardShortcut("n", modifiers: .command)
                
                Button("New Folder") {
                    // Show new folder dialog
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])
            }
        }
        #endif
    }
}
