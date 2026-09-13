import Foundation

enum DetailPhase<Value: Equatable>: Equatable {
    case loading
    case loaded(Value)
    case notFound
    case failed(message: String)
}
