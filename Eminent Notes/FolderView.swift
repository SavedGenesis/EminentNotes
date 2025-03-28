import SwiftUI

struct FolderView: View {
    @EnvironmentObject var folderViewModel: FolderViewModel
    @EnvironmentObject var noteListViewModel: NoteListViewModel
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var showingNewFolderSheet = false
    @State private var newFolderName = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Folder navigation breadcrumb
            if !folderViewModel.folderPath.isEmpty {
                BreadcrumbView(folderViewModel: folderViewModel)
            }
            
            // Main list content
            FolderContentList(
                folderViewModel: folderViewModel,
                noteListViewModel: noteListViewModel,
                showingNewFolderSheet: $showingNewFolderSheet,
                newFolderName: $newFolderName
            )
        }
        .navigationTitle(folderViewModel.currentFolder?.name ?? "Folders")
        .toolbar {
            ToolbarItem(placement: toolbarPlacement()) {
                Button {
                    showingNewFolderSheet = true
                } label: {
                    Label("New Folder", systemImage: "folder.badge.plus")
                }
            }
            
            ToolbarItem(placement: toolbarPlacement()) {
                Button {
                    let newNote = noteListViewModel.createNote(folder: folderViewModel.currentFolder)
                    if let note = newNote {
                        noteListViewModel.selectedNote = note
                    }
                } label: {
                    Label("New Note", systemImage: "square.and.pencil")
                }
            }
        }
        .sheet(isPresented: $showingNewFolderSheet) {
            NewFolderSheet(
                folderViewModel: folderViewModel,
                showingSheet: $showingNewFolderSheet,
                newFolderName: $newFolderName
            )
        }
        .onAppear {
            folderViewModel.setContext(viewContext)
        }
    }
    
    // Helper method to determine proper toolbar placement
    private func toolbarPlacement() -> ToolbarItemPlacement {
        #if os(macOS)
        return .automatic
        #else
        return .navigationBarTrailing
        #endif
    }
}

// Break up the view into smaller components
struct BreadcrumbView: View {
    @ObservedObject var folderViewModel: FolderViewModel
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                Button {
                    folderViewModel.navigateToFolder(nil)
                } label: {
                    Text("Root")
                        .font(.caption)
                }
                
                ForEach(folderViewModel.folderPath) { folder in
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Button {
                        folderViewModel.navigateToFolder(folder)
                    } label: {
                        Text(folder.name ?? "Untitled")
                            .font(.caption)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.1))
    }
}

struct FolderContentList: View {
    @ObservedObject var folderViewModel: FolderViewModel
    @ObservedObject var noteListViewModel: NoteListViewModel
    @Binding var showingNewFolderSheet: Bool
    @Binding var newFolderName: String
    
    var body: some View {
        List {
            // Folders section
            Section(header: Text("Folders")) {
                FolderListSection(
                    folderViewModel: folderViewModel,
                    newFolderName: $newFolderName
                )
            }
            
            // Notes section
            Section(header: Text("Notes")) {
                NotesListSection(
                    folderViewModel: folderViewModel,
                    noteListViewModel: noteListViewModel
                )
            }
        }
        #if os(iOS)
        .listStyle(InsetGroupedListStyle())
        #else
        .listStyle(DefaultListStyle())
        #endif
    }
}

struct FolderListSection: View {
    @ObservedObject var folderViewModel: FolderViewModel
    @Binding var newFolderName: String
    
    var body: some View {
        let folders = folderViewModel.currentFolder?.childrenArray ?? folderViewModel.rootFolders
        
        if folders.isEmpty {
            Text("No folders")
                .foregroundColor(.secondary)
                .font(.caption)
        } else {
            ForEach(folders) { folder in
                Button {
                    folderViewModel.navigateToFolder(folder)
                } label: {
                    HStack {
                        Image(systemName: "folder")
                            .foregroundColor(.accentColor)
                        Text(folder.name ?? "Untitled")
                        Spacer()
                        
                        if !folder.childrenArray.isEmpty || (folder.notes?.count ?? 0) > 0 {
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .contextMenu {
                    Button("Rename", action: {
                        newFolderName = folder.name ?? ""
                        // Add rename functionality
                    })
                    
                    Button("Delete", role: .destructive) {
                        folderViewModel.deleteFolder(folder)
                    }
                }
            }
            .onDelete { indexSet in
                let foldersToDelete = indexSet.map { folders[$0] }
                for folder in foldersToDelete {
                    folderViewModel.deleteFolder(folder)
                }
            }
        }
    }
}

struct NotesListSection: View {
    @ObservedObject var folderViewModel: FolderViewModel
    @ObservedObject var noteListViewModel: NoteListViewModel
    
    var body: some View {
        if let currentFolder = folderViewModel.currentFolder {
            if currentFolder.noteArray.isEmpty {
                Text("No notes in this folder")
                    .foregroundColor(.secondary)
                    .font(.caption)
            } else {
                ForEach(currentFolder.noteArray) { note in
                    NoteRow(note: note)
                        .onTapGesture {
                            noteListViewModel.selectedNote = note
                        }
                }
                .onDelete { indexSet in
                    let notesToDelete = indexSet.map { currentFolder.noteArray[$0] }
                    for note in notesToDelete {
                        noteListViewModel.deleteNote(note)
                    }
                }
            }
        } else {
            Text("Select a folder to view notes")
                .foregroundColor(.secondary)
                .font(.caption)
        }
    }
}

struct NewFolderSheet: View {
    @ObservedObject var folderViewModel: FolderViewModel
    @Binding var showingSheet: Bool
    @Binding var newFolderName: String
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("New Folder")) {
                    TextField("Folder Name", text: $newFolderName)
                }
            }
            .navigationTitle("Create Folder")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: leadingToolbarPlacement()) {
                    Button("Cancel") {
                        newFolderName = ""
                        showingSheet = false
                    }
                }
                
                ToolbarItem(placement: trailingToolbarPlacement()) {
                    Button("Create") {
                        if !newFolderName.isEmpty {
                            _ = folderViewModel.createFolder(name: newFolderName, parent: folderViewModel.currentFolder)
                            newFolderName = ""
                            showingSheet = false
                        }
                    }
                    .disabled(newFolderName.isEmpty)
                }
            }
        }
    }
    
    private func leadingToolbarPlacement() -> ToolbarItemPlacement {
        #if os(macOS)
        return .cancellationAction
        #else
        return .navigationBarLeading
        #endif
    }
    
    private func trailingToolbarPlacement() -> ToolbarItemPlacement {
        #if os(macOS)
        return .confirmationAction
        #else
        return .navigationBarTrailing
        #endif
    }
}
