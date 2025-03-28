// FolderViewModel.swift
import Foundation
import CoreData
import SwiftUI
import Combine

class FolderViewModel: ObservableObject {
    @Published var rootFolders: [Folder] = []
    @Published var currentFolder: Folder?
    @Published var folderPath: [Folder] = []
    
    private var context: NSManagedObjectContext?
    
    func setContext(_ context: NSManagedObjectContext) {
        self.context = context
        fetchRootFolders()
    }
    
    func fetchRootFolders() {
        guard let context = context else { return }
        rootFolders = Folder.fetchRootFolders(context: context)
    }
    
    func createFolder(name: String, parent: Folder? = nil) -> Folder? {
        guard let context = context else { return nil }
        
        // Check depth limitation if parent exists
        if let parent = parent, parent.depth >= 9 {
            print("Maximum folder depth reached (10)")
            return nil
        }
        
        let newFolder = Folder(context: context)
        newFolder.name = name
        newFolder.creationDate = Date()
        newFolder.parent = parent
        
        do {
            try context.save()
            fetchRootFolders()
            return newFolder
        } catch {
            print("Error creating folder: \(error)")
            return nil
        }
    }
    
    func deleteFolder(_ folder: Folder) {
        guard let context = context else { return }
        
        // Get notes to reassign them
        let notes = folder.noteArray
        
        // Get parent to reassign notes if needed
        let parent = folder.parent
        
        // Reassign notes to parent folder if exists
        if let parent = parent {
            for note in notes {
                note.folder = parent
            }
        }
        
        // Delete the folder
        context.delete(folder)
        
        do {
            try context.save()
            fetchRootFolders()
            
            // Update current folder if it was deleted
            if currentFolder == folder {
                currentFolder = parent
                updateFolderPath()
            }
        } catch {
            print("Error deleting folder: \(error)")
        }
    }
    
    func navigateToFolder(_ folder: Folder?) {
        currentFolder = folder
        updateFolderPath()
    }
    
    func navigateUp() {
        currentFolder = currentFolder?.parent
        updateFolderPath()
    }
    
    private func updateFolderPath() {
        var path: [Folder] = []
        var current = currentFolder
        
        // Build path from current folder up to root
        while current != nil {
            path.insert(current!, at: 0)
            current = current?.parent
        }
        
        folderPath = path
    }
}
