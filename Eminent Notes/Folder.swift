// Folder.swift - Update to support parent-child relationship
import Foundation
import CoreData

@objc(Folder)
public class Folder: NSManagedObject, Identifiable {
    @NSManaged public var name: String?
    @NSManaged public var creationDate: Date?
    
    public static let entityName = "Folder"
    
    // Relationships
    @NSManaged public var notes: NSSet?
    @NSManaged public var parent: Folder?
    @NSManaged public var children: NSSet?
    
    // Convenience properties
    public var noteArray: [Note] {
        let set = notes as? Set<Note> ?? []
        return set.sorted { $0.modificationDate ?? Date() > $1.modificationDate ?? Date() }
    }
    
    public var childrenArray: [Folder] {
        let set = children as? Set<Folder> ?? []
        return set.sorted { $0.name ?? "" < $1.name ?? "" }
    }
    
    // Calculate folder depth (for limiting max depth)
    public var depth: Int {
        var current: Folder? = self
        var depth = 0
        
        while current?.parent != nil {
            depth += 1
            current = current?.parent
        }
        
        return depth
    }
}

extension Folder {
    static func fetchRequest() -> NSFetchRequest<Folder> {
        return NSFetchRequest<Folder>(entityName: Folder.entityName)
    }
    
    static func fetchAll(context: NSManagedObjectContext) -> [Folder] {
        let request = fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Folder.name, ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching folders: \(error)")
            return []
        }
    }
    
    static func fetchRootFolders(context: NSManagedObjectContext) -> [Folder] {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "parent == nil")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Folder.name, ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching root folders: \(error)")
            return []
        }
    }
}
