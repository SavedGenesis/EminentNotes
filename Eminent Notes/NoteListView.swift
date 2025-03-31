import SwiftUI

struct NoteListView: View {
    
    // Access the Core Data context
    @Environment(\.managedObjectContext) private var viewContext
    
    @EnvironmentObject var viewModel: NoteListViewModel
        
        // State for the search bar
        @State private var searchText = ""
        @State private var showingEditor = false
    
    var body: some View {
        List {
            // Display pinned notes at the top
            if !viewModel.notes.filter({ $0.isPinned }).isEmpty {
                Section(header: Text("Pinned")) {
                    ForEach(viewModel.notes.filter { $0.isPinned }) { note in
                        NoteRow(note: note)
                            .onTapGesture {
                                viewModel.selectedNote = note
                            }
                    }
                }
            }
            
            // Display other notes
            Section(header: Text("Notes")) {
                ForEach(viewModel.notes.filter { !$0.isPinned }) { note in
                    NoteRow(note: note)
                        .onTapGesture {
                            viewModel.selectedNote = note
                        }
                }
                .onDelete(perform: deleteNotes)
            }
        }
        #if os(iOS)
        .listStyle(InsetGroupedListStyle())
        #else
        .listStyle(DefaultListStyle())
        #endif
        .searchable(text: $searchText)
        .onChange(of: searchText) { oldValue, newValue in
            viewModel.searchText = newValue
        }
        .navigationTitle("Notes")
        .toolbar {
            #if os(iOS)
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    withAnimation {
                        let newNote = viewModel.createNote()
                        if let note = newNote {
                            viewModel.selectedNote = note
                        }
                    }
                }) {
                    Label("Add Note", systemImage: "plus")
                }
            }
            #else
            ToolbarItem(placement: .automatic) {
                Button(action: {
                    withAnimation {
                        let newNote = viewModel.createNote()
                        if let note = newNote {
                            viewModel.selectedNote = note
                        }
                    }
                }) {
                    Label("Add Note", systemImage: "plus")
                }
            }
            #endif
        }
    }
    
    // Handle note deletion
    private func deleteNotes(offsets: IndexSet) {
        withAnimation {
            offsets.map { viewModel.notes.filter { !$0.isPinned }[$0] }
                .forEach(viewModel.deleteNote)
        }
    }
}

// Component for displaying a note in the list
struct NoteRow: View {
    let note: Note
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(note.title ?? "Untitled")
                .font(.headline)
                .lineLimit(1)
            
            if let content = note.content, !content.isEmpty {
                Text(content)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            HStack {
                if let date = note.modificationDate {
                    Text(date, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Display tags if any
                if let tags = note.tags, tags.count > 0 {
                    Image(systemName: "tag")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NoteListView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(NoteListViewModel())
}
