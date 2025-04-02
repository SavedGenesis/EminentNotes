import SwiftUI

struct NoteListView: View {
    // Access the Core Data context
    @Environment(\.managedObjectContext) private var viewContext
    
    // Access the shared view model
    @EnvironmentObject var viewModel: NoteListViewModel
    
    // State for the search bar
    @State private var searchText = ""
    @State private var showingDeleteAlert = false
    @State private var noteToDelete: Note? = nil
    
    var body: some View {
        Group {
            if viewModel.notes.isEmpty && searchText.isEmpty {
                ContentUnavailableView {
                    Label("No Notes", systemImage: "note.text")
                } description: {
                    Text("Create a new note to get started")
                } actions: {
                    Button("Create Note") {
                        viewModel.createAndSelectNewNote()
                    }
                }
            } else if viewModel.notes.isEmpty && !searchText.isEmpty {
                ContentUnavailableView {
                    Label("No Results", systemImage: "magnifyingglass")
                } description: {
                    Text("No notes match your search")
                }
            } else {
                List {
                    // Display pinned notes at the top
                    if !viewModel.notes.filter({ $0.isPinned }).isEmpty {
                        Section(header: Text("Pinned")) {
                            ForEach(viewModel.notes.filter { $0.isPinned }) { note in
                                NavigationLink(value: note) {
                                    NoteRow(note: note)
                                }
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        noteToDelete = note
                                        showingDeleteAlert = true
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    
                                    Button {
                                        note.isPinned.toggle()
                                        try? viewContext.save()
                                        viewModel.fetchNotes()
                                    } label: {
                                        Label("Unpin", systemImage: "pin.slash")
                                    }
                                    .tint(.blue)
                                }
                            }
                        }
                    }
                    
                    // Display other notes
                    Section(header: Text("Notes")) {
                        ForEach(viewModel.notes.filter { !$0.isPinned }) { note in
                            NavigationLink(value: note) {
                                NoteRow(note: note)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    noteToDelete = note
                                    showingDeleteAlert = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                
                                Button {
                                    note.isPinned.toggle()
                                    try? viewContext.save()
                                    viewModel.fetchNotes()
                                } label: {
                                    Label("Pin", systemImage: "pin")
                                }
                                .tint(.blue)
                            }
                        }
                    }
                }
                #if os(iOS)
                .listStyle(InsetGroupedListStyle())
                #else
                .listStyle(DefaultListStyle())
                #endif
            }
        }
        .searchable(text: $searchText)
        .onChange(of: searchText) { oldValue, newValue in
            viewModel.searchText = newValue
        }
        .navigationTitle("Notes")
        .toolbar {
            #if os(iOS)
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    viewModel.createAndSelectNewNote()
                }) {
                    Label("New Note", systemImage: "square.and.pencil")
                }
            }
            #else
            ToolbarItem(placement: .automatic) {
                Button(action: {
                    viewModel.createAndSelectNewNote()
                }) {
                    Label("New Note", systemImage: "square.and.pencil")
                }
            }
            #endif
        }
        .alert("Delete Note", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let note = noteToDelete {
                    viewModel.deleteNote(note)
                }
            }
        } message: {
            Text("Are you sure you want to delete this note? This action cannot be undone.")
        }
        .onAppear {
            // Set the context when the view appears
            viewModel.setContext(viewContext)
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
                
                // Display folder if any
                if let folder = note.folder {
                    HStack(spacing: 4) {
                        Image(systemName: "folder")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(folder.name ?? "")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Display tags if any
                if let tags = note.tags, tags.count > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "tag")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(tags.count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        NoteListView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .environmentObject(NoteListViewModel())
    }
}
