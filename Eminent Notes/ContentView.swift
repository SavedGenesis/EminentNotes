import SwiftUI

struct MainContentView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var noteListViewModel: NoteListViewModel
    @EnvironmentObject var folderViewModel: FolderViewModel
    
    var body: some View {
        ZStack {
            #if os(iOS)
            // On iPhone, use a tab-based navigation for smaller screens
            if horizontalSizeClass == .compact {
                EminentNotesTabView()
            } else {
                // On iPad, use a split view
                MainSplitView()
            }
            #else
            // On macOS, always use a split view
            MainSplitView()
            #endif
        }
        .task {
            // Initialize viewModels with the proper context
            noteListViewModel.setContext(viewContext)
            folderViewModel.setContext(viewContext)
        }
    }
}

struct EminentNotesTabView: View {
    @State private var selectedTab = 0
    @EnvironmentObject var noteListViewModel: NoteListViewModel
    @EnvironmentObject var folderViewModel: FolderViewModel
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                NoteListView()
                    .navigationDestination(for: Note.self) { note in
                        EditorContainerView(note: note)
                    }
            }
            .tabItem {
                Label("Notes", systemImage: "note.text")
            }
            .tag(0)
            
            NavigationStack {
                FolderView()
                    .navigationDestination(for: Note.self) { note in
                        EditorContainerView(note: note)
                    }
            }
            .tabItem {
                Label("Folders", systemImage: "folder")
            }
            .tag(1)
        }
    }
}

struct MainSplitView: View {
    @State private var selectedSidebarItem: String? = "notes"
    @EnvironmentObject var noteListViewModel: NoteListViewModel
    @EnvironmentObject var folderViewModel: FolderViewModel
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedSidebarItem) {
                Label("All Notes", systemImage: "note.text")
                    .tag("notes")
                
                Label("Folders", systemImage: "folder")
                    .tag("folders")
            }
            .navigationTitle("Eminent Notes")
        } content: {
            if selectedSidebarItem == "notes" {
                NoteListView()
            } else if selectedSidebarItem == "folders" {
                FolderView()
            }
        } detail: {
            NoteDetailView()
        }
    }
}

struct NoteDetailView: View {
    @EnvironmentObject var noteListViewModel: NoteListViewModel
    
    var body: some View {
        if let note = noteListViewModel.selectedNote {
            EditorContainerView(note: note)
        } else {
            ContentUnavailableView {
                Label("No Note Selected", systemImage: "note.text")
            } description: {
                Text("Select a note or create a new one")
            } actions: {
                Button("Create Note") {
                    let newNote = noteListViewModel.createNote()
                    if let note = newNote {
                        noteListViewModel.selectedNote = note
                    }
                }
            }
        }
    }
}

struct EditorContainerView: View {
    @EnvironmentObject var noteListViewModel: NoteListViewModel
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = NoteEditorViewModel()
    let note: Note?
    
    var body: some View {
        NoteEditorView(viewModel: viewModel)
            .task {
                viewModel.configure(note: note, context: viewContext) {
                    // When the note is saved, update the list
                    noteListViewModel.fetchNotes()
                }
            }
            #if os(iOS)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        viewModel.saveNote()
                        dismiss()
                    }
                }
            }
            #endif
    }
}

#Preview {
    MainContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(NoteListViewModel())
        .environmentObject(FolderViewModel())
}
