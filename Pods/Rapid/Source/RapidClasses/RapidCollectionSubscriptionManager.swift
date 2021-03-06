//
//  RapidSubscriptionHandler.swift
//  Rapid
//
//  Created by Jan Schwarz on 22/03/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

/// Class that handles all collection subscriptions which listen to the same dataset
class RapidColSubManager: NSObject, RapidSubscriptionManager {
    
    /// Hash that identifies subscriptions handled by the class
    ///
    /// Subscriptions that listen to the same dataset have equal hashes
    var subscriptionHash: String {
        return subscriptions.first?.subscriptionHash ?? ""
    }
    
    var subscriptionTake: Int? {
        return subscriptions.first?.subscriptionTake
    }
    
    var subscriptionOrdering: [RapidOrdering.Ordering] {
        return subscriptions.first?.subscriptionOrdering ?? []
    }
    
    /// ID of subscription
    let subscriptionID: String
    
    /// Handler delegate
    internal weak var delegate: RapidSubscriptionManagerDelegate?
    
    /// Array of subscription objects
    fileprivate var subscriptions: [RapidColSubInstance] = []
    
    /// Last known value of the dataset
    fileprivate var value: [RapidDocument]? {
        didSet {
            if let value = value {
                // Store last known value to a cache
                delegate?.cacheHandler?.storeDataset(value, forSubscription: self)
            }
            else {
                delegate?.cacheHandler?.storeDataset([], forSubscription: self)
            }
        }
    }
    
    /// Subscription state
    internal var state: RapidSubscriptionState = .unsubscribed
    
    /// Handler initializer
    ///
    /// - Parameters:
    ///   - subscriptionID: Subscription ID
    ///   - subscription: Subscription object
    ///   - dispatchQueue: `SocketManager` dedicated thread for parsing
    ///   - unsubscribeHandler: Block of code which must be called to unregister the subscription
    init(withSubscriptionID subscriptionID: String, subscription: RapidColSubInstance, delegate: RapidSubscriptionManagerDelegate?) {
        self.subscriptionID = subscriptionID
        self.delegate = delegate
        
        super.init()
        
        state = .registering
        appendSubscription(subscription)
        
        loadCachedData()
    }
    
    /// Add another subscription object to the handler
    ///
    /// - Parameter subscription: New subscription object
    func registerSubscription(subscription: RapidColSubInstance) {
        delegate?.websocketQueue.async {
            self.appendSubscription(subscription)
            
            // Pass the last known value immediatelly if there is any
            if let value = self.value {
                subscription.receivedUpdate(value, value, [], [])
            }
        }
    }

}

extension RapidColSubManager: RapidSerializable {
    
    func serialize(withIdentifiers identifiers: [AnyHashable : Any]) throws -> String {
        if let subscription = subscriptions.first {
            var idef = identifiers
            
            idef[RapidSerialization.CollectionSubscription.SubscriptionID.name] = subscriptionID
            
            return try subscription.serialize(withIdentifiers: idef)
        }
        else {
            throw RapidError.invalidData(reason: .serializationFailure)
        }
    }
    
    /// JSON message for unsubscribing request
    ///
    /// - Parameter identifiers: Custom identifiers
    /// - Returns: JSON string
    /// - Throws: `JSONSerialization` and `RapidError.invalidData` errors
    func serializeForUnsubscription(withIdentifiers identifiers: [AnyHashable : Any]) throws -> String {
        return try RapidSerialization.serialize(unsubscription: self, withIdentifiers: identifiers)
    }
}

fileprivate extension RapidColSubManager {
    
    /// Load cached data if there are any
    func loadCachedData() {
        delegate?.cacheHandler?.loadSubscriptionValue(forSubscription: self, completion: { [weak self] (cachedValue) in
            self?.delegate?.parseQueue.async {
                if let subscriptionID = self?.subscriptionID, self?.value == nil, let cachedValue = cachedValue as? [RapidDocument] {
                    let batch = RapidSubscriptionBatch(withSubscriptionID: subscriptionID, collection: cachedValue)
                    self?.receivedNewValue(batch)
                }
            }
        })
    }
    
    /// Add a new subscription object
    ///
    /// - Parameter subscription: New subscription object
    func appendSubscription(_ subscription: RapidColSubInstance) {
        subscription.registerUnsubscribeHandler { [weak self] instance in
            self?.delegate?.websocketQueue.async {
                self?.unsubscribe(instance: instance)
            }
        }
        subscriptions.append(subscription)
    }
    
    /// Updated dataset received from the server
    ///
    /// - Parameter newValue: Updated dataset
    func receivedNewValue(_ update: RapidSubscriptionBatch) {
        let updates = incorporate(batch: update, oldValue: value)
        
        // Inform subscriptions only if any change occured
        guard updates.insert.count > 0 || updates.update.count > 0 || updates.delete.count > 0 || value == nil else {
            value = updates.dataSet
            return
        }
        
        if let collection = update.collection {
            RapidLogger.log(message: "Subscription initial value - collection \(subscriptionHash)", level: .debug)
            RapidLogger.log(message: "\(collection.map({ "\($0.id): \($0.value ?? [:])" }))", level: .debug)
        }
        if update.updates.count > 0 {
            RapidLogger.log(message: "Subscription update - collection \(subscriptionHash)", level: .debug)
            RapidLogger.log(message: "\(update.updates.map({ "\($0.id): \($0.value ?? [:])" }))", level: .debug)
        }
        
        // Inform all subscription objects
        for subsription in subscriptions {
            subsription.receivedUpdate(updates.dataSet, updates.insert, updates.update, updates.delete)
        }
        
        value = updates.dataSet
    }
    
    /// Proces updated dataset
    ///
    /// - Parameters:
    ///   - rawArray: Updated documents
    ///   - oldValue: Last known dataset
    /// - Returns: Tuple with a new dataset and arrays of new, updated and removed documents
    func incorporate(batch: RapidSubscriptionBatch, oldValue: [RapidDocument]?) -> (dataSet: [RapidDocument], insert: [RapidDocument], update: [RapidDocument], delete: [RapidDocument]) {
        
        var updates = RapidDocumentOperationSet()
        
        // Store previously known dataset to `documents`
        // If there is a new complete dataset in the update work with it
        // If there is no previous dataset work with a collection from the update
        var documents: [RapidDocument]
        
        if var oldValue = oldValue, let collection = batch.collection {
            documents = collection.flatMap({ $0.value == nil ? nil : $0 })
            
            // Firstly, consider all original documents as being removed
            // Their status will be changed if they are present in the new dataset from update
            updates.formUnion(oldValue.map { RapidDocumentOperation(document: $0, operation: .remove) })
            
            for document in documents {
                let operation = incorporate(document: document, inCollection: &oldValue, mutateCollection: false)
                updates.update(operation)
            }
        }
        else if let oldValue = oldValue {
            documents = oldValue
        }
        else {
            documents = batch.collection?.flatMap({ $0.value == nil ? nil : $0 }) ?? []
            updates.formUnion(documents.map { RapidDocumentOperation(document: $0, operation: .add) })
        }
        
        // Loop through updated documents
        for update in batch.updates {
            let operation = incorporate(document: update, inCollection: &documents, mutateCollection: true)
            updates.insertOrUpdate(operation)
        }
        
        // If there are more documents than a subscription handler expects remove them
        if let take = subscriptionTake, documents.count > take {
            for document in documents[take..<documents.count] {
                let operation = RapidDocumentOperation(document: document, operation: .remove)
                updates.insertOrUpdate(operation)
            }
            
            documents.removeLast(documents.count - take)
        }
        
        // If there was no previous dataset consider all values as new
        // Otherwise, deal with different types of updates
        if oldValue == nil {
            return (documents, documents, [], [])
        }
        
        var inserted = [RapidDocument]()
        var updated = [RapidDocument]()
        var deleted = [RapidDocument]()
        
        // Sort updates according to type
        for docOp in updates {
            switch docOp.operation {
            case .add:
                inserted.append(docOp.document)
                
            case .update:
                updated.append(docOp.document)
                
            case .remove:
                deleted.append(docOp.document)
                
            case .none:
                break
            }
        }
        
        return (documents, inserted, updated, deleted)
    }

    /// Sort the document in the collection
    ///
    /// - Parameters:
    ///   - document: Document to process
    ///   - documents: Original collection
    ///   - mutateCollection: Set to `true` if `documents` array should be mutated
    /// - Returns: Resulting `RapidDocumentOperation`
    func incorporate(document: RapidDocument, inCollection documents: inout [RapidDocument], mutateCollection: Bool = true) -> RapidDocumentOperation {
        // Index of the document in the last known dataset
        let index = documents.index(where: { $0.id == document.id })
        
        // If etag of the document hasn't changed the document itself hasn't changed
        if let index = index, documents[index].etag == document.etag {
            return RapidDocumentOperation(document: document, operation: .none)
        }
        
        // If documents should not be mutated return an operation right away
        if !mutateCollection {
            let operation: RapidDocumentOperation.Operation
            let doc: RapidDocument
            
            if document.value == nil, let index = index {
                operation = .remove
                doc = documents[index]
            }
            else if document.value == nil {
                operation = .none
                doc = document
            }
            else {
                operation = index == nil ? .add : .update
                doc = document
            }
 
            return RapidDocumentOperation(document: doc, operation: operation)
        }
        
        // If the document was removed
        if document.value == nil {
            if let index = index {
                let removedDoc = documents.remove(at: index)
                
                return RapidDocumentOperation(document: removedDoc, operation: .remove)
            }
            
            return RapidDocumentOperation(document: document, operation: .none)
        }
        
        // Get a new index of the new/updated document
        let newIndex = findInsertIndex(forDocument: document, toCollection: documents[0..<documents.count])

        if let index = index {
            if newIndex == index {
                documents[newIndex] = document
            }
            else if newIndex < index {
                documents.remove(at: index)
                documents.insert(document, at: newIndex)
            }
            else {
                documents.insert(document, at: newIndex)
                documents.remove(at: index)
            }
            
            return RapidDocumentOperation(document: document, operation: .update)
        }
        
        documents.insert(document, at: newIndex)
        return RapidDocumentOperation(document: document, operation: .add)
    }
    
    /// Find an index where should be a new/updated document inserted
    ///
    /// - Parameters:
    ///   - document: Document to be inserted
    ///   - collection: Original collection
    /// - Returns: Index where should be a new/updated document inserted
    func findInsertIndex(forDocument document: RapidDocument, toCollection collection: ArraySlice<RapidDocument>, sliceStartIndex: Int = 0) -> Int {
        guard !collection.isEmpty else {
            return 0
        }
        
        let referenceIndex = collection.count/2 + sliceStartIndex
        let referenceKeys = collection[referenceIndex].sortKeys
        
        for i in 0..<document.sortKeys.count {
            let referenceValue = referenceKeys[i]
            let ordering = subscriptionOrdering[i]
            
            if document.sortKeys[i] == referenceValue {
                continue
            }
            else if (document.sortKeys[i] < referenceValue && ordering == .ascending) || (document.sortKeys[i] > referenceValue && ordering == .descending) {
                return findInsertIndex(forDocument: document, toCollection: collection.prefix(upTo: referenceIndex), sliceStartIndex: sliceStartIndex)
            }
            else {
                let index = findInsertIndex(forDocument: document, toCollection: collection.suffix(from: referenceIndex+1), sliceStartIndex: referenceIndex+1)
                return (referenceIndex - sliceStartIndex) + index + 1
            }
        }
        
        let referenceDate = collection[referenceIndex].sortValue 
        let createdAt = document.sortValue 
        let ordering = subscriptionOrdering.first ?? .ascending
        
        if createdAt == referenceDate {
            return referenceIndex - sliceStartIndex
        }
        else if (createdAt < referenceDate && ordering == .ascending) || (createdAt > referenceDate && ordering == .descending) {
            return findInsertIndex(forDocument: document, toCollection: collection.prefix(upTo: referenceIndex), sliceStartIndex: sliceStartIndex)
        }
        else {
            let index = findInsertIndex(forDocument: document, toCollection: collection.suffix(from: referenceIndex+1), sliceStartIndex: referenceIndex+1)
            return (referenceIndex - sliceStartIndex) + index + 1
        }
    }
    
    /// Unregister subscription object from listening to the dataset changes
    ///
    /// - Parameter instance: Subscription object
    func unsubscribe(instance: RapidSubscriptionInstance) {
        // If there is only one subscription object unsubscribe the handler
        // Otherwise just remove the subscription object from array of registered subscription objects
        if subscriptions.count == 1 {
            state = .unsubscribing
            delegate?.unsubscribe(handler: RapidUnsubscriptionManager(subscription: self))
        }
        else if let index = subscriptions.index(where: { $0 === instance }) {
            subscriptions.remove(at: index)
        }
    }
}

extension RapidColSubManager: RapidClientRequest {
    
    func eventAcknowledged(_ acknowledgement: RapidServerAcknowledgement) {
        delegate?.websocketQueue.async {
            self.state = .subscribed
        }
    }
    
    func eventFailed(withError error: RapidErrorInstance) {
        delegate?.websocketQueue.async {
            RapidLogger.log(message: "Subscription failed \(self.subscriptionHash) with error \(error.error)", level: .info)
            
            self.value = nil
            self.state = .unsubscribed
            
            for subscription in self.subscriptions {
                subscription.subscriptionFailed(withError: error.error)
            }
        }
    }
    
    func receivedSubscriptionEvent(_ update: RapidSubscriptionBatch) {
        delegate?.parseQueue.async {
            self.receivedNewValue(update)
        }
    }
}
