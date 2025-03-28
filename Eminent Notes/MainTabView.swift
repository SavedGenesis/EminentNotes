import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                NoteListView()
            }
            .tabItem {
                Label("Notes", systemImage: "note.text")
            }
            .tag(0)
            
            NavigationStack {
                Text("Folders View")
            }
            .tabItem {
                Label("Folders", systemImage: "folder")
            }
            .tag(1)
            
            NavigationStack {
                Text("Tags View")
            }
            .tabItem {
                Label("Tags", systemImage: "tag")
            }
            .tag(2)
        }
    }
}

#Preview {
    MainTabView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(NoteListViewModel())
}