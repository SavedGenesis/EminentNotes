// FolderViewModel.swift
import Foundation
import CoreData
import SwiftUI
import Combine

class FolderViewModel: ObservableObject {
    @Published var rootFolders: [Folder] = []
    @Published var currentFolder: Folder?
    @Published var folderPath: [Folder] = []
    @Published var isLoading: Bool = false
    
    private var context: NSManagedObjectContext?
    private var cancellables = Set<AnyCancellable>()
    
    func setContext(_ context: NSManagedObjectContext) {
        self.context = context
        fetchRootFolders()
    }
    
    func fetchRootFolders() {
        guard let context = context else { return }
        isLoading = true
        
        // Use a background task for better UI responsiveness
        Task {
            let folders = await withCheckedContinuation { continuation in
                context.perform {
                    let result = Folder.fetchRootFolders(context: context)
                    continuation.resume(returning: result)
                }
            }
            
            // Update UI on main thread
            await MainActor.run {
                self.rootFolders = folders
                self.isLoading = false
            }
        }
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
            
            // If the parent of the new folder is the current folder, refresh the list
            if parent?.objectID == currentFolder?.objectID {
                // We need to refresh the children of the current folder
                if let current = currentFolder {
                    context.refresh(current, mergeChanges: true)
                }
            } else if parent == nil {
                // If we're adding a root folder, refresh the root folders
                fetchRootFolders()
            }
            
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
            
            // If we're deleting a root folder, refresh the root folders
            if folder.parent == nil {
                fetchRootFolders()
            }
            
            // Update current folder if it was deleted
            if currentFolder == folder {
                currentFolder = parent
                updateFolderPath()
            }
        } catch {
            print("Error deleting folder: \(error)")
        }
    }
    
    func renameFolder(_ folder: Folder, newName: String) {
        guard let context = context else { return }
        
        // Update the folder name
        folder.name = newName
        
        do {
            try context.save()
            
            // Refresh the UI
            if folder.parent == nil {
                fetchRootFolders()
            } else {
                // Refresh the parent's children
                if let parent = folder.parent {
                    context.refresh(parent, mergeChanges: true)
                }
            }
            
            // If this is the current folder, update the folder path
            if currentFolder?.objectID == folder.objectID {
                updateFolderPath()
            }
        } catch {
            print("Error renaming folder: \(error)")
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
    
    // Helper method to get all folders (flattened)
    func getAllFolders() -> [Folder] {
        guard let context = context else { return [] }
        
        do {
            let request = Folder.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(keyPath: \Folder.name, ascending: true)]
            return try context.fetch(request)
        } catch {
            print("Error fetching all folders: \(error)")
            return []
        }
    }
}
