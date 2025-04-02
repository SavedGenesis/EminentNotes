import SwiftUI

struct ContentView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var noteListViewModel: NoteListViewModel
    @EnvironmentObject var folderViewModel: FolderViewModel
    
    var body: some View {
        #if os(iOS)
        // On iPhone, use a tab-based navigation for smaller screens
        if horizontalSizeClass == .compact {
            ContentTabView()
        } else {
            // On iPad, use a split view
            ContentSplitView()
        }
        #else
        // On macOS, always use a split view
        ContentSplitView()
        #endif
        .onAppear {
            // Initialize viewModels with the proper context
            noteListViewModel.setContext(viewContext)
            folderViewModel.setContext(viewContext)
        }
    }
}

struct ContentTabView: View {
    @State private var selectedTab = 0
    @EnvironmentObject var noteListViewModel: NoteListViewModel
    @EnvironmentObject var folderViewModel: FolderViewModel
    @State private var showNewNote = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                NoteListView()
                    .navigationDestination(for: Note.self) { note in
                        NoteEditorContainer(note: note)
                    }
                    .navigationDestination(isPresented: $showNewNote) {
                        if let newNote = noteListViewModel.selectedNote {
                            NoteEditorContainer(note: newNote)
                        }
                    }
            }
            .tabItem {
                Label("Notes", systemImage: "note.text")
            }
            .tag(0)
            
            NavigationStack {
                FolderView()
                    .navigationDestination(for: Note.self) { note in
                        NoteEditorContainer(note: note)
                    }
                    .navigationDestination(isPresented: $showNewNote) {
                        if let newNote = noteListViewModel.selectedNote {
                            NoteEditorContainer(note: newNote)
                        }
                    }
            }
            .tabItem {
                Label("Folders", systemImage: "folder")
            }
            .tag(1)
        }
        .onChange(of: noteListViewModel.selectedNote) { oldValue, newValue in
            if newValue != nil && oldValue == nil {
                showNewNote = true
            }
        }
    }
}

struct ContentSplitView: View {
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
            DetailView()
        }
    }
}

struct DetailView: View {
    @EnvironmentObject var noteListViewModel: NoteListViewModel
    
    var body: some View {
        if let note = noteListViewModel.selectedNote {
            NoteEditorContainer(note: note)
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

struct NoteEditorContainer: View {
    @EnvironmentObject var noteListViewModel: NoteListViewModel
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = NoteEditorViewModel()
    let note: Note?
    
    var body: some View {
        NoteEditorView(viewModel: viewModel)
            .onAppear {
                viewModel.configure(note: note, context: viewContext) {
                    // When the note is saved, update the list
                    noteListViewModel.fetchNotes()
                }
            }
            .onDisappear {
                if viewModel.hasUnsavedChanges {
                    // If there are unsaved changes, save the note when leaving
                    viewModel.saveNote()
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
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(NoteListViewModel())
        .environmentObject(FolderViewModel())
}
