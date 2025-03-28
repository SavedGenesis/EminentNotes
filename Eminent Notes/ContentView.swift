import SwiftUI

struct ContentView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @StateObject private var folderViewModel = FolderViewModel()
    @EnvironmentObject var noteListViewModel: NoteListViewModel
    
    var body: some View {
        #if os(iOS)
        // On iPhone, use a tab-based navigation for smaller screens
        if horizontalSizeClass == .compact {
            ContentTabView()
                .environmentObject(folderViewModel)
        } else {
            // On iPad, use a split view
            ContentSplitView()
                .environmentObject(folderViewModel)
        }
        #else
        // On macOS, always use a split view
        ContentSplitView()
            .environmentObject(folderViewModel)
        #endif
    }
}

struct ContentTabView: View {
    @State private var selectedTab = 0
    @EnvironmentObject var noteListViewModel: NoteListViewModel
    @EnvironmentObject var folderViewModel: FolderViewModel
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                NoteListView()
                    .navigationDestination(for: Note.self) { note in
                        NoteEditorContainer(note: note)
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
            }
            .tabItem {
                Label("Folders", systemImage: "folder")
            }
            .tag(1)
        }
    }
}

struct ContentSplitView: View {
    @State private var selectedSidebarItem: String? = "notes"
    @EnvironmentObject var noteListViewModel: NoteListViewModel
    @EnvironmentObject var folderViewModel: FolderViewModel
    @Environment(\.managedObjectContext) private var viewContext
    
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
            if let note = noteListViewModel.selectedNote {
                NoteEditorContainer(note: note)
            } else {
                Text("Select a note or create a new one")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct NoteEditorContainer: View {
    @EnvironmentObject var noteListViewModel: NoteListViewModel
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel = NoteEditorViewModel()
    let note: Note?
    
    var body: some View {
        NoteEditorView(viewModel: viewModel)
            .onAppear {
                viewModel.configure(note: note, context: viewContext) {
                    noteListViewModel.fetchNotes()
                }
            }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(NoteListViewModel())
}
