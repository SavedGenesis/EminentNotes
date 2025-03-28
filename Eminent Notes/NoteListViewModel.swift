import Foundation
import CoreData
import SwiftUI
import Combine

class NoteListViewModel: ObservableObject {
    // Published properties automatically notify SwiftUI views when they change
    @Published var notes: [Note] = []
    @Published var selectedNote: Note?
    @Published var searchText: String = ""
    @Published var isSearching: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    private var context: NSManagedObjectContext?
    
    // Initialize the view model
    init() {
        // The search text publisher debounces the search to avoid too many updates
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] searchText in
                self?.fetchNotes()
            }
            .store(in: &cancellables)
    }
    
    // Set the managed object context (called from a view)
    func setContext(_ context: NSManagedObjectContext) {
        self.context = context
        fetchNotes()
    }
    
    // Fetch notes from Core Data
    func fetchNotes() {
        guard let context = context else { return }
        
        let request = Note.fetchRequest()
        
        // Apply search filter if needed
        if !searchText.isEmpty {
            request.predicate = NSPredicate(
                format: "title CONTAINS[cd] %@ OR content CONTAINS[cd] %@", 
                searchText, searchText
            )
        } else {
            request.predicate = NSPredicate(format: "isArchived == %@", NSNumber(value: false))
        }
        
        // Sort by modified date (newest first)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Note.modificationDate, ascending: false)]
        
        do {
            notes = try context.fetch(request)
        } catch {
            print("Error fetching notes: \(error)")
        }
    }
    
    // Create a new note
    func createNote() -> Note? {
        guard let context = context else { return nil }
        
        let newNote = Note(context: context)
        newNote.title = "New Note"
        newNote.content = ""
        newNote.creationDate = Date()
        newNote.modificationDate = Date()
        newNote.isArchived = false
        newNote.isPinned = false
        
        do {
            try context.save()
            fetchNotes() // Refresh the list
            return newNote
        } catch {
            print("Error creating note: \(error)")
            return nil
        }
    }
    
    // Delete a note
    func deleteNote(_ note: Note) {
        guard let context = context else { return }
        
        context.delete(note)
        
        do {
            try context.save()
            fetchNotes() // Refresh the list
        } catch {
            print("Error deleting note: \(error)")
        }
    }
    
    // NoteListViewModel.swift - Add this method
    func createNote(folder: Folder? = nil) -> Note? {
        guard let context = context else { return nil }
        
        let newNote = Note(context: context)
        newNote.title = "New Note"
        newNote.content = ""
        newNote.creationDate = Date()
        newNote.modificationDate = Date()
        newNote.isArchived = false
        newNote.isPinned = false
        newNote.folder = folder
        
        do {
            try context.save()
            fetchNotes() // Refresh the list
            return newNote
        } catch {
            print("Error creating note: \(error)")
            return nil
        }
    }
}
