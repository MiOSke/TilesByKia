//
//  DatabaseManager.swift
//  TilesByKia
//
//  Created by Michael Kampouris on 5/7/22.
//

import Foundation
import FirebaseFirestore
import UserNotifications

class DatabaseManager {
    
    static let shared = DatabaseManager()
    var items: [Item] = []
    
    private let itemReference = Firestore.firestore().collection("Items")
    
    func save(item: Item, completion: @escaping (Bool, Error?) -> ()) {
        if item.upc != "" {
            itemReference.document(item.upc).setData(item.asJSON as [String:Any?], merge: true) { error in
                if let error = error {
                    completion(false, error)
                } else {
                    completion(true, nil)
                }
            }
        } else {
            itemReference.addDocument(data: item.asJSON as [String:Any?]) { error in
                if let error = error {
                    completion(false, error)
                } else {
                    completion(true, nil)
                }
            }
        }
    }
    
    func loadItem(upc: String, completion: @escaping (Item?, Error?) -> ()) {
        itemReference.document(upc).getDocument { snapshot, error in
            if let error = error {
                print(error.localizedDescription)
                completion(nil, error)
            } else if let itemJSON = snapshot?.data(), let key = snapshot?.documentID {
                let item = Item(key: key, dictionary: itemJSON)
                completion(item, nil)
            } else {
                completion(nil, NSError(domain: "ItemError", code: 404))
            }
        }
    }
    
    func deleteItem(upc: String) {
        itemReference.document(upc).delete()
        self.postNotification()
    }
    
    func loadItems() {
        var tempItems: [Item] = []
        itemReference.addSnapshotListener(includeMetadataChanges: true) { snapshot, error in
            if let error = error {
                print(error.localizedDescription)
            } else {
                snapshot?.documentChanges.forEach { diff in
                    tempItems.removeAll()
                    if (diff.type == .added) {
                        if let documents = snapshot?.documents {
                            documents.forEach { document in
                                let item = Item(key: document.documentID, dictionary: document.data())
                                tempItems.append(item)
                            }
                            print(tempItems.count)
                            self.items = tempItems.sorted(by: { lhs, rhs in
                                lhs.name < rhs.name
                            })
                            self.postNotification()
                        }
                        print("Item Added: \(diff.document.data())")
                    }
                    if (diff.type == .modified) {
                        tempItems.removeAll()
                        if let documents = snapshot?.documents {
                            documents.forEach { document in
                                let item = Item(key: document.documentID, dictionary: document.data())
                                tempItems.append(item)
                            }
                            self.items = tempItems.sorted(by: { lhs, rhs in
                                lhs.name < rhs.name
                            })
                            self.postNotification()
                        }
                        print("Item Modified: \(diff.document.data())")
                    }
                    if (diff.type == .removed) {
                        tempItems.removeAll()
                        if let documents = snapshot?.documents {
                            documents.forEach { document in
                                let item = Item(key: document.documentID, dictionary: document.data())
                                tempItems.append(item)
                            }
                            print(tempItems.count)
                            self.items = tempItems.sorted(by: { lhs, rhs in
                                lhs.name < rhs.name
                            })
                            self.postNotification()
                        }
                        print("Item Removed: \(diff.document.data())")
                    }
                }

            }
        }
    }
    
    func postNotification() {
        NotificationCenter.default.post(name: Notification.Name("ItemChanged"), object: nil, userInfo: nil)
    }
    
}
