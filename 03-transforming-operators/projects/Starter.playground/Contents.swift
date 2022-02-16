import Foundation
import Combine

var subscriptions = Set<AnyCancellable>()

// collect()
// The collect operator provides a convenient way to transform a stream of individual values from a publisher into a single array.
example(of: "collect") {
    ["A", "B", "C", "D", "E"].publisher
        .collect(2)
        .sink(receiveCompletion: { print($0) },
              receiveValue: { print($0) })
        .store(in: &subscriptions)
}

// map()
// This works just like Swift’s standard map, except that it operates on values emitted from a publisher.
example(of: "map") {
    // Create a number formatter to spell out each number.
    let formatter = NumberFormatter()
    formatter.numberStyle = .spellOut
    
    // Create a publisher of integers.
    [123, 4, 56].publisher
        .map {
            formatter.string(for: NSNumber(integerLiteral: $0)) ?? ""
        }
        .sink { print($0) }
        .store(in: &subscriptions)
}

// mapping key paths
//
example(of: "mapping key paths") {
    // Create a publisher of Coordinates that will never emit an error.
    let publisher = PassthroughSubject<Coordinate, Never>()
    
    // Begin a subscription to the publisher
    publisher
        // Map into the x and y properties of Coordinate using their key paths.
        .map(\.x, \.y)
        // Print a statement that indicates the quadrant of the provide x and y values.
        .sink { (x, y) in
            print("The coordinate at (\(x), \(y)) is in quadrant", quadrantOf(x: x, y: y))
        }
        .store(in: &subscriptions)
    
    publisher.send(Coordinate(x: 10, y: -8))
    publisher.send(Coordinate(x: 0, y: 5))
}

// trymap()
// Several operators, including map, have a counterpart with a try prefix that takes a throwing closure. If you throw an error, the operator will emit that error downstream.
example(of: "tryMap") {
    // Create a publisher of a string representing a directory name that does not exist.
    Just("Directory name that does not exist")
        // Use tryMap to attempt to get the contents of that nonexistent directory.
        .tryMap { try FileManager.default.contentsOfDirectory(atPath: $0) }
        // Receive and print out any values or completion events.
        .sink {
            print($0)
        } receiveValue: {
            print($0)
        }
        .store(in: &subscriptions)
}

// flatMap(maxPublishers:_:)
// The flatMap operator flattens multiple upstream publishers into a single downstream publisher — or more specifically, flatten the emissions from those publishers.
// A common use case for flatMap in Combine is when you want to pass elements emitted by one publisher to a method that itself returns a publisher, and ultimately subscribe to the elements emitted by that second publisher.
example(of: "flatMap") {
    // Define a function that takes an array of integers, each representing an ASCII code, and returns a type-erased publisher of strings that never emits errors.
    func decode(_ codes: [Int]) -> AnyPublisher<String, Never> {
        // Create a Just publisher that converts the character code into a string if it’s within the range of 0.255, which includes standard and extended printable ASCII characters.
        Just(
          codes
            .compactMap { code in
              guard (32...255).contains(code) else { return nil }
              return String(UnicodeScalar(code) ?? " ")
            }
            // Join the strings together.
            .joined()
        )
        // Type erase the publisher to match the return type for the fuction.
        .eraseToAnyPublisher()
    }
    
    // Create a secret message as an array of ASCII character codes, convert it to a publisher, and collect its emitted elements into a single array.
    [72, 101, 108, 108, 111, 44, 32, 87, 111, 114, 108, 100, 33]
        .publisher
        .collect()
        // Use flatMap to pass the array element to your decoder function.
        .flatMap(decode)
        // Subscribe to the elements emitted by the pubisher returned by decode(_:) and print out the values.
        .sink(receiveValue: { print($0) })
        .store(in: &subscriptions)
}

// replaceNil(with:)
// replaceNil will receive optional values and replace nils with the value you specify
example(of: "replaceNil") {
    // Create a publisher from an array of optional strings.
    ["A", nil, "C"].publisher
        .eraseToAnyPublisher()
        // Use replaceNil(with:) to replace nil values received from the upstream publisher with a new non-nil value.
        .replaceNil(with: "*")
        .sink { print($0) }
        .store(in: &subscriptions)
}

// replaceEmpty(with:)
// You can use the replaceEmpty(with:) operator to replace — or really, insert — a value if a publisher completes without emitting a value.
example(of: "replaceEmpty") {
    // Create an empty publisher that immediately emits a completion event.
    let empty = Empty<Int, Never>()
    
    // Subscribe to it, and print received events.
    empty
        .replaceEmpty(with: 5)
        .sink(receiveCompletion: { print($0) },
              receiveValue: { print($0) })
        .store(in: &subscriptions)
}

// scan(_:_:)
// scan provides the current value emitted by an upstream publisher to a closure, along with the last value returned by that closure.
example(of: "scan") {
    // Create a computed property that generates a random integer between -10 and 10.
    var dailyGainLoss: Int { .random(in: -10...10) }
    
    // Use that generator to create a publisher from an array of random integers representing fictitious daily stock price changes for a month.
    let august2019 = (0..<22).map { _ in
        dailyGainLoss
    }.publisher
    
    // Use scan with a starting value of 50, and then add each daily change to the running stock price. The use of max keeps the price non-negative — thankfully stock prices can’t fall below zero!
    august2019
        .scan(50) { latest, current in
            max(0, latest + current)
        }
        .sink(receiveValue: { _ in })
        .store(in: &subscriptions)
}
