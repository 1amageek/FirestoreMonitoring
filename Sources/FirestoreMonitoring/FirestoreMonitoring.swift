import FirebaseFirestore

public class Monitoring {

    public struct Options {
        let showLogs: Bool = false
    }

    public static let _monitoring: Monitoring = Monitoring()

    @discardableResult
    public class func monitoring(_ options: Options? = nil) -> Monitoring {
        let monitoring = Monitoring._monitoring
        if let options = options {
            monitoring.options = options
        }
        return monitoring
    }

    public private(set) var options: Options = Options()

    fileprivate var readCounter: ReadCounter = ReadCounter()

    private init() {

        swizzling(DocumentReference.self,
                  s0: #selector(DocumentReference.getDocument(completion:)),
                  s1: #selector(DocumentReference._getDocument(completion:)))

        swizzling(DocumentReference.self,
                  s0: #selector(DocumentReference.getDocument(source:completion:)),
                  s1: #selector(DocumentReference._getDocument(source:completion:)))

        swizzling(DocumentReference.self,
                  s0: #selector(DocumentReference.addSnapshotListener(_:)),
                  s1: #selector(DocumentReference._addSnapshotListener(_:)))

        swizzling(DocumentReference.self,
                  s0: #selector(DocumentReference.addSnapshotListener(includeMetadataChanges:listener:)),
                  s1: #selector(DocumentReference._addSnapshotListener(includeMetadataChanges:listener:)))

        swizzling(Query.self,
                  s0: #selector(Query.getDocuments(completion:)),
                  s1: #selector(Query._getDocuments(completion:)))

        swizzling(Query.self,
                  s0: #selector(Query.getDocuments(source:completion:)),
                  s1: #selector(Query._getDocuments(source:completion:)))

        swizzling(Query.self,
                  s0: #selector(Query.addSnapshotListener(_:)),
                  s1: #selector(Query._addSnapshotListener(_:)))

        swizzling(Query.self,
                  s0: #selector(Query.addSnapshotListener(includeMetadataChanges:listener:)),
                  s1: #selector(Query._addSnapshotListener(includeMetadataChanges:listener:)))

    }

    private func swizzling(_ cls: AnyClass?, s0: Selector, s1: Selector) {
        guard
            let m0: Method = class_getInstanceMethod(cls, s0),
            let m1: Method = class_getInstanceMethod(cls, s1)
            else { return }
        method_exchangeImplementations(m0, m1)
    }

}

private class ReadCounter {

    class Document {

        var countFromServer: Int = 0

        var countFromCache: Int = 0

        var errorCount: Int = 0

        var countOfEachPath: [String: Int] = [:]

        var countOfEachPathFromCache: [String: Int] = [:]

        var errors: [String: Int] = [:]

        func increment(for path: String, snapshot: DocumentSnapshot?, error: Error?) {
            if let _ = error {
                self.errorCount += 1
                if self.errors.keys.contains(path) {
                    self.errors[path]! += 1
                } else {
                    self.errors[path] = 0
                }
            } else {
                if let snapshot = snapshot, snapshot.metadata.isFromCache {
                    self.countFromCache += 1
                    if self.countOfEachPathFromCache.keys.contains(path) {
                        self.countOfEachPathFromCache[path]! += 1
                    } else {
                        self.countOfEachPathFromCache[path] = 0
                    }
                } else {
                    self.countFromServer += 1
                    if self.countOfEachPath.keys.contains(path) {
                        self.countOfEachPath[path]! += 1
                    } else {
                        self.countOfEachPath[path] = 0
                    }
                }
            }
            print("[Monitoring:Document] - Count from Server: \(self.countFromServer) | Count from Cache: \(self.countFromCache) | Error count: \(self.errorCount)")
        }
    }

    class Collection {

        var countFromServer: Int = 0

        var countFromCache: Int = 0

        var errorCount: Int = 0

        var countOfEachPath: [String: Int] = [:]

        var countOfEachPathFromCache: [String: Int] = [:]

        func increment(for snapshot: QuerySnapshot?, error: Error?) {
            if let _ = error {
                self.errorCount += 1
            } else if let snapshot = snapshot {
                if snapshot.metadata.isFromCache {
                    self.countFromCache += snapshot.count
                } else {
                    self.countFromServer += snapshot.count
                }
                snapshot.documents.forEach { documentSnapshot in
                    let path: String = documentSnapshot.reference.path
                    if snapshot.metadata.isFromCache {
                        if self.countOfEachPathFromCache.keys.contains(path) {
                            self.countOfEachPathFromCache[path]! += 1
                        } else {
                            self.countOfEachPathFromCache[path] = 0
                        }
                    } else {
                        if self.countOfEachPath.keys.contains(path) {
                            self.countOfEachPath[path]! += 1
                        } else {
                            self.countOfEachPath[path] = 0
                        }
                    }
                }
            }
            print("[Monitoring:Collection] - Count from Server: \(self.countFromServer) | Count from Cache: \(self.countFromCache) | Error count: \(self.errorCount)")
        }
    }

    let document: Document = Document()

    let collection: Collection = Collection()
}


private extension DocumentReference {

    @objc func _getDocument(completion: @escaping FIRDocumentSnapshotBlock) {
        let path: String = self.path
        if Monitoring.monitoring().options.showLogs {
            print("[Monitoring:Document] getDocument(completion:) path: \(path)")
        }
        self._getDocument { snapshot, error in
            Monitoring.monitoring().readCounter.document.increment(for: path, snapshot: snapshot, error: error)
            completion(snapshot, error)
        }
    }

    @objc func _getDocument(source: FirestoreSource, completion: @escaping FIRDocumentSnapshotBlock) {
        let path: String = self.path
        if Monitoring.monitoring().options.showLogs {
            print("[Monitoring:Document] getDocument(source:completion:) path: \(path) source: \(source.rawValue)")
        }
        self._getDocument(source: source)  { snapshot, error in
            Monitoring.monitoring().readCounter.document.increment(for: path, snapshot: snapshot, error: error)
            completion(snapshot, error)
        }
    }

    @objc func _addSnapshotListener(_ listener: @escaping FIRDocumentSnapshotBlock) -> ListenerRegistration {
        let path: String = self.path
        if Monitoring.monitoring().options.showLogs {
            print("[Monitoring:Document] addSnapshotListener(_:) path: \(path)")
        }
        return self._addSnapshotListener { snapshot, error in
            Monitoring.monitoring().readCounter.document.increment(for: path, snapshot: snapshot, error: error)
            listener(snapshot, error)
        }
    }

    @objc func _addSnapshotListener(includeMetadataChanges: Bool, listener: @escaping FIRDocumentSnapshotBlock) -> ListenerRegistration {
        let path: String = self.path
        if Monitoring.monitoring().options.showLogs {
            print("[Monitoring:Document] addSnapshotListener(includeMetadataChanges:listener:) path: \(path) includeMetadataChanges: \(includeMetadataChanges)")
        }
        return self._addSnapshotListener(includeMetadataChanges: includeMetadataChanges) { snapshot, error in
            Monitoring.monitoring().readCounter.document.increment(for: path, snapshot: snapshot, error: error)
            listener(snapshot, error)
        }
    }
}

private extension Query {

    @objc func _getDocuments(completion: @escaping FIRQuerySnapshotBlock) {
        if Monitoring.monitoring().options.showLogs {
            print("[Monitoring:Collection] getDocuments(completion:)")
        }
        self._getDocuments { snapshot, error in
            Monitoring.monitoring().readCounter.collection.increment(for: snapshot, error: error)
            completion(snapshot, error)
        }
    }

    @objc func _getDocuments(source: FirestoreSource, completion: @escaping FIRQuerySnapshotBlock) {
        if Monitoring.monitoring().options.showLogs {
            print("[Monitoring:Collection] getDocuments(source:completion:) source: \(source.rawValue)")
        }
        self._getDocuments(source: source)  { snapshot, error in
            Monitoring.monitoring().readCounter.collection.increment(for: snapshot, error: error)
            completion(snapshot, error)
        }
    }

    @objc func _addSnapshotListener(_ listener: @escaping FIRQuerySnapshotBlock) {
        if Monitoring.monitoring().options.showLogs {
            print("[Monitoring:Collection] addSnapshotListener(_:)")
        }
        self._addSnapshotListener { snapshot, error in
            Monitoring.monitoring().readCounter.collection.increment(for: snapshot, error: error)
            listener(snapshot, error)
        }
    }

    @objc func _addSnapshotListener(includeMetadataChanges: Bool, listener: @escaping FIRQuerySnapshotBlock) {
        if Monitoring.monitoring().options.showLogs {
            print("[Monitoring:Collection] addSnapshotListener(includeMetadataChanges:listener:) includeMetadataChanges: \(includeMetadataChanges)")
        }
        self._addSnapshotListener(includeMetadataChanges: includeMetadataChanges)  { snapshot, error in
            Monitoring.monitoring().readCounter.collection.increment(for: snapshot, error: error)
            listener(snapshot, error)
        }
    }
}
