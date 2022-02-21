import Foundation
import Combine

var subscriptions = Set<AnyCancellable>()

let numbers = (1...100).publisher

numbers
    // Skip the first 50 values emitted by the upstream publisher.
    .dropFirst(50)
    // Take the next 20 values after those first 50 values.
    .prefix(20)
    // Only take even numbers.
    .filter { $0.isMultiple(of: 2) }
    .sink(receiveCompletion: { print("Completed with: \($0)") },
               receiveValue: { print($0) })
    .store(in: &subscriptions)

