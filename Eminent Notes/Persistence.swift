//
//  Persistence.swift
//  Eminent Notes
//
//  Created by Gabriel on 3/28/25.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()
    
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext
        
        // Create sample data for previews
        let sampleFolder = Folder(context: context)
        sampleFolder.name = "Quick Notes"
        sampleFolder.creationDate = Date()
        
        let sampleTag = Tag(context: context)
        sampleTag.name = "Important"
        sampleTag.colorHex = "#FF0000"
        
        for i in 0..<5 {
            let note = Note(context: context)
            note.title = "Sample Note \(i)"
            note.content = "This is sample content for note \(i)"
            note.creationDate = Date()
            note.modificationDate = Date()
            note.folder = sampleFolder
            note.tags = NSSet(object: sampleTag)
        }
        
        do {
            try context.save()
        } catch {
            fatalError("Failed to create preview data: \(error.localizedDescription)")
        }
        
        return controller
    }()
    
    let container: NSPersistentContainer
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Eminent_Notes")
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { description, error in
            if let error = error as NSError? {
                fatalError("Failed to load Core Data stores: \(error), \(error.userInfo)")
            }
        }
        
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    func save() {
        let context = container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Error saving context: \(error)")
            }
        }
    }
}
