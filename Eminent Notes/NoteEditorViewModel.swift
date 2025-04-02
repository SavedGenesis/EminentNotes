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
    @Published var hasUnsavedChanges: Bool = false
    
    private var originalTitle: String = ""
    private var originalContent: String = ""
    private var originalIsPinned: Bool = false
    
    private var note: Note?
    private var context: NSManagedObjectContext?
    private var onSave: (() -> Void)?
    private var cancellables = Set<AnyCancellable>()
    
    func configure(note: Note?, context: NSManagedObjectContext, onSave: @escaping () -> Void) {
        self.note = note
        self.context = context
        self.onSave = onSave
        
        self.hasUnsavedChanges = false
        
        if let note = note {
            // Load existing note data
            title = note.title ?? ""
            content = note.content ?? ""
            selectedTags = note.tagArray
            isPinned = note.isPinned
            
            // Store original values to track changes
            originalTitle = title
            originalContent = content
            originalIsPinned = isPinned
        } else {
            // Setup for new note
            title = ""
            content = ""
            selectedTags = []
            isPinned = false
            
            // Set original values for new note
            originalTitle = ""
            originalContent = ""
            originalIsPinned = false
        }
        
        // Set up publishers to track changes
        setupChangeTracking()
    }
    
    private func setupChangeTracking() {
        // Clear any existing cancellables
        cancellables.removeAll()
        
        // Track title changes
        $title
            .dropFirst() // Skip the initial value
            .sink { [weak self] _ in
                self?.updateChangeStatus()
            }
            .store(in: &cancellables)
        
        // Track content changes
        $content
            .dropFirst() // Skip the initial value
            .sink { [weak self] _ in
                self?.updateChangeStatus()
            }
            .store(in: &cancellables)
        
        // Track pin status changes
        $isPinned
            .dropFirst() // Skip the initial value
            .sink { [weak self] _ in
                self?.updateChangeStatus()
            }
            .store(in: &cancellables)
    }
    
    private func updateChangeStatus() {
        hasUnsavedChanges = title != originalTitle || 
                           content != originalContent || 
                           isPinned != originalIsPinned
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
            
            // Update original values to match saved values
            originalTitle = title
            originalContent = content
            originalIsPinned = isPinned
            hasUnsavedChanges = false
            
            // Call the onSave callback
            onSave?()
        } catch {
            print("Error saving note: \(error)")
        }
    }
    
    func togglePin() {
        isPinned.toggle()
    }
    
    func discardChanges() {
        // Revert to original values
        title = originalTitle
        content = originalContent
        isPinned = originalIsPinned
        hasUnsavedChanges = false
    }
}
