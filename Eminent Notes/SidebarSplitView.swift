import SwiftUI

struct SidebarSplitView: View {
    @State private var selectedSidebarItem: String? = "notes"
    @EnvironmentObject var viewModel: NoteListViewModel
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedSidebarItem) {
                Label("All Notes", systemImage: "note.text")
                    .tag("notes")
                
                Label("Folders", systemImage: "folder")
                    .tag("folders")
                
                Label("Tags", systemImage: "tag")
                    .tag("tags")
            }
            .navigationTitle("Eminent Notes")
        } content: {
            if selectedSidebarItem == "notes" {
                NoteListView()
            } else if selectedSidebarItem == "folders" {
                Text("Folders View")
            } else if selectedSidebarItem == "tags" {
                Text("Tags View")
            }
        } detail: {
            if let note = viewModel.selectedNote {
                Text("Note Editor for \(note.title ?? "Untitled")")
            } else {
                Text("Select a note or create a new one")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    SidebarSplitView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(NoteListViewModel())
}