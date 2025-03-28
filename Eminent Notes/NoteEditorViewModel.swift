// NoteEditorViewModel.swift
import Foundation
import CoreData
import SwiftUI
import Combine

class NoteEditorViewModel: ObservableObject {
    @Published var title: String = ""
    @Published var content: String = ""
    @Published var selectedTags: [Tag] = []
    @Published var isPinned: Bool = false
    
    private var note: Note?
    private var context: NSManagedObjectContext?
    private var onSave: (() -> Void)?
    
    func configure(note: Note?, context: NSManagedObjectContext, onSave: @escaping () -> Void) {
        self.note = note
        self.context = context
        self.onSave = onSave
        
        if let note = note {
            // Load existing note data
            title = note.title ?? ""
            content = note.content ?? ""
            selectedTags = note.tagArray
            isPinned = note.isPinned
        } else {
            // Setup for new note
            title = ""
            content = ""
            selectedTags = []
            isPinned = false
        }
    }
    
    func saveNote(folder: Folder? = nil) {
        guard let context = context else { return }
        
        let noteToSave: Note
        
        if let existingNote = note {
            // Update existing note
            noteToSave = existingNote
        } else {
            // Create new note
            noteToSave = Note(context: context)
            noteToSave.creationDate = Date()
        }
        
        // Update properties
        noteToSave.title = title.isEmpty ? "Untitled" : title
        noteToSave.content = content
        noteToSave.modificationDate = Date()
        noteToSave.isPinned = isPinned
        
        // Set folder if provided
        if let folder = folder {
            noteToSave.folder = folder
        }
        
        // Handle tags - proper Core Data relationship handling
        if let existingTags = note?.tags as? Set<Tag> {
            for tag in existingTags {
                if !selectedTags.contains(tag) {
                    if let tags = noteToSave.tags?.mutableCopy() as? NSMutableSet {
                        tags.remove(tag)
                        noteToSave.tags = tags
                    }
                }
            }
        }
        
        for tag in selectedTags {
            if let tags = noteToSave.tags as? Set<Tag>, !tags.contains(tag) {
                if let mutableTags = noteToSave.tags?.mutableCopy() as? NSMutableSet {
                    mutableTags.add(tag)
                    noteToSave.tags = mutableTags
                }
            } else if noteToSave.tags == nil {
                noteToSave.tags = NSSet(array: [tag])
            }
        }
        
        // Save context
        do {
            try context.save()
            onSave?()
        } catch {
            print("Error saving note: \(error)")
        }
    }
    
    func togglePin() {
        isPinned.toggle()
    }
}
