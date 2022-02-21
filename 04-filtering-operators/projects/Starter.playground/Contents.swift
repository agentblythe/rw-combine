import Foundation
import Combine

var subscriptions = Set<AnyCancellable>()

// filter
// takes a closure expectd to return a Bool. It’ll only pass down values that match the provided predicate:
example(of: "filter") {
    // Create a new publisher, which will emit a finite number of values — 1 through 10, and then complete, using the publisher property on Sequence types.
    let numbers = (1...10).publisher
    
    // Use the filter operator, passing in a predicate where you only allow through numbers that are multiples of three.
    numbers
        .filter { $0.isMultiple(of: 3) }
        .sink { print("\($0) is a multiple of 3") }
        .store(in: &subscriptions)
}

// removeDuplicates
//
example(of: "removeDuplicates") {
    func join(_ words: [String]) -> AnyPublisher<String, Never> {
        Just(words.joined(separator: " ")).eraseToAnyPublisher()
    }
    
    // Separate a sentence into an array of words (e.g., [String]) and then create a new publisher to emit these words.
    let words = "hey hey there! want to listen to mister mister ?"
        .components(separatedBy: " ")
        .publisher
    
    words
        .removeDuplicates() // Apply removeDuplicates() to your words publisher.
        .collect()
        .flatMap(join)
        .sink { print($0) }
        .store(in: &subscriptions)
}

// compactMap
// remove nils from input
example(of: "compactMap") {
    // Create a publisher that emits a finite list of strings.
    let strings = ["a", "1.24", "3",
                     "def", "45", "0.23"].publisher
    
    // Use compactMap to attempt to initialize a Float from each individual string. If Float’s initializer doesn’t know how to convert the provided string, it returns nil. Those nil values are automatically filtered out by the compactMap operator.
    strings
        .compactMap { Float($0) }
        .sink(receiveValue: { print($0) }) // Only print strings that have been successfully converted to Floats.
        .store(in: &subscriptions)
}

// ignoreOutput
// ignore values and just respond when completion event occurs
example(of: "ignoreOutput") {
    // Create a publisher emitting 10,000 values from 1 through 10,000.
    let numbers = (1...10_000).publisher
    
    // Add the ignoreOutput operator, which omits all values and emits only the completion event to the consumer.
    numbers
        .ignoreOutput()
        .sink(receiveCompletion: { print("Completed with: \($0)") },
                   receiveValue: { print($0) })
        .store(in: &subscriptions)
}
    
// first(where:)
// find first matching pattern
example(of: "first(where:)") {
    // Creates a new publisher emitting numbers from 1 through 9.
    let numbers = (1...9).publisher
    
    // Uses the first(where:) operator to find the first emitted even value.
    numbers
        .first(where: {$0 % 2 == 0})
        .sink(receiveCompletion: { print("Completed with: \($0)") },
              receiveValue: { print($0) })
        .store(in: &subscriptions)
}

// last(where:)
// find last matching pattern
example(of: "last(where:)") {
    // Creates a new publisher emitting numbers from 1 through 9.
    let numbers = (1...9).publisher
    
    // Use the last(where:) operator to find the last emitted even value.
    numbers
        .last(where: { $0 % 2 == 0 })
        .sink(receiveCompletion: { print("Completed with: \($0)") },
              receiveValue: { print($0) })
        .store(in: &subscriptions)
}

// dropFirst(count = 1)
// drops the first *count* items
example(of: "dropFirst") {
    // Create a publisher that emits 10 numbers between 1 and 10.
    let numbers = (1...10).publisher
    
    // Use dropFirst(8) to drop the first eight values, printing only 9 and 10.
    numbers
        .dropFirst(8)
        .sink(receiveValue: { print($0) })
        .store(in: &subscriptions)
}

// dropWhile
// takes a predicate closure and ignores any values emitted by the publisher until the first time that predicate is met. As soon as the predicate is met, values begin to flow through the operator:
example(of: "dropWhile") {
    // Create a publisher that emits numbers between 1 and 10.
    let numbers = (1...10).publisher
    
    // Use drop(while:) to wait for the first value that is divisible by five. As soon as the condition is met, values will start flowing through the operator and won’t be dropped anymore.
    numbers
        .drop(while: { $0 % 5 != 0 })
        .sink(receiveValue: { print($0) })
        .store(in: &subscriptions)
}

// drop(untilOutputFrom:)
// It skips any values emitted by a publisher until a second publisher starts emitting values, creating a relationship between them:
example(of: "drop(untilOutputFrom:)") {
    // Create two PassthroughSubjects that you can manually send values through. The first is isReady while the second represents taps by the user.
    let isReady = PassthroughSubject<Void, Never>()
    let taps = PassthroughSubject<Int, Never>()
    
    // Use drop(untilOutputFrom: isReady) to ignore any taps from the user until isReady emits at least one value.
    taps
        .drop(untilOutputFrom: isReady)
        .sink(receiveValue: { print($0) })
        .store(in: &subscriptions)
    
    // Send five “taps” through the subject, just like in the diagram above. After the third tap, you send isReady a value.
    (1...5).forEach { n in
        taps.send(n)
        if n == 3 {
            isReady.send()
        }
    }
}

// prefix
// takes values only up to the provided amount and then completes
example(of: "prefix") {
    // Create a publisher that emits numbers from 1 through 10.
    let numbers = (1...10).publisher
    
    // Use prefix(2) to allow the emission of only the first two values. As soon as two values are emitted, the publisher completes.
    numbers
        .prefix(2)
        .sink(receiveCompletion: { print("Completed with: \($0)") },
                   receiveValue: { print($0) })
        .store(in: &subscriptions)
}

// prefix(while:)
//  takes a predicate closure and lets values from the upstream publisher through as long as the result of that closure is true. As soon as the result is false, the publisher will complete:
example(of: "prefix(while:)") {
    // Create a publisher that emits numbers from 1 through 10.
    let numbers = (1...10).publisher
    
    // Use prefix(while:) to let values through as long as they’re smaller than 3. As soon as a value equal to or larger than 3 is emitted, the publisher completes.
    numbers
        .prefix(while: { $0 < 3 })
        .sink(receiveCompletion: { print("Completed with: \($0)") },
                   receiveValue: { print($0) })
        .store(in: &subscriptions)
}

// prefix(untilOutputFrom:)
// skips values until a second publisher emits, prefix(untilOutputFrom:) takes values until a second publisher emits.
example(of: "prefix(untilOutputFrom:)") {
    // Create two PassthroughSubjects that you can manually send values through. The first is isReady while the second represents taps by the user.
    let isReady = PassthroughSubject<Void, Never>()
    let taps = PassthroughSubject<Int, Never>()
    
    // Use prefix(untilOutputFrom: isReady) to let tap events through until isReady emits at least one value.
    taps
        .prefix(untilOutputFrom: isReady)
        .sink(receiveCompletion: { print("Completed with: \($0)") },
              receiveValue: { print($0) })
        .store(in: &subscriptions)
    
    // Send five “taps” through the subject, exactly as in the diagram above. After the second tap, you send isReady a value.
    (1...5).forEach { n in
        taps.send(n)
        
        if n == 2 {
            isReady.send()
        }
    }
}
