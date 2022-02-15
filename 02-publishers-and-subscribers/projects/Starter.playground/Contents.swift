import Foundation
import Combine
import _Concurrency

example(of: "Publisher") {
    // Create Notification Name
    let myNotification = Notification.Name("MyNotification")

    // Access NotificationCentre's default instance, calling its publisher() method and assign the return value to a local constant
    let publisher = NotificationCenter.default
        .publisher(for: myNotification, object: nil)

    // Get the default instance
    let centre = NotificationCenter.default

    // Create an observer to listen for the notification with the name
    let observer = centre.addObserver(forName: myNotification, object: nil, queue: nil) { notification in
        print("Notification Received!")
    }

    // Post a notification with that name
    centre.post(name: myNotification, object: nil)

    // Remove the observer
    centre.removeObserver(observer)
}

example(of: "Subscriber") {
    let myNotification = Notification.Name("MyNotification")

    let centre = NotificationCenter.default

    let publisher = centre.publisher(for: myNotification, object: nil)

    // Create subscription by calling sink on the publisher
    let subscription = publisher
        .sink { _ in
            print("Notification Received from a Publisher!")
        }

    // Post the notification
    centre.post(name: myNotification, object: nil)

    // Cancel the subscription
    subscription.cancel()
}

example(of: "Just") {
    // Create a publisher using Just which lets you create a publisher from a single value
    let just = Just("Hello World")

    // Create a subscription to the publisher and print a message fo each received event
    _ = just
        .sink(receiveCompletion: {
            print("Received completion", $0)
        }, receiveValue: {
            print("Received value", $0)
        })

    _ = just
        .sink(receiveCompletion: {
            print("Received completion (another)", $0)
        }, receiveValue: {
            print("Received value (another)", $0)
        })
}

example(of: "Assign(to:on:)") {
    // Define a class with a property that has a didSet property observer that prints the new value.
    class SomeObject {
        var value: String = "" {
            didSet {
                print(value)
            }
        }
    }

    // Create an instance of that class.
    let object = SomeObject()

    // Create a publisher from an array of strings.
    let publisher = ["Hello", "World"].publisher

    // Subscribe to the publisher, assigning each value received to the value property of the object.
    _ = publisher.assign(to: \.value, on: object)
}

example(of: "assign(to:)") {
    // Define and create an instance of a class with a property annotated with the @Published property wrapper, which creates a publisher for value in addition to being accessible as a regular property.
    class SomeObject {
        @Published var value = 0
    }
    let object = SomeObject()

    // Use the $ prefix on the @Published property to gain access to its underlying publisher, subscribe to it, and print out each value received.
    object.$value
        .sink {
            print($0)
        }

    // Create a publisher of numbers and assign each value it emits to the value publisher of object. Note the use of & to denote an inout reference to the property.
    (0..<10).publisher
        .assign(to: &object.$value)
}

example(of: "Custom Subscriber") {
    // Create a publisher of integers via the range’s publisher property.
    let publisher = (1...6).publisher

    // Define a custom subscriber, IntSubscriber.
    final class IntSubscriber: Subscriber {
        // Implement the type aliases to specify that this subscriber can receive integer inputs and will never receive errors.
        typealias Input = Int
        typealias Failure = Never

        // receive(subscription:), called by the publisher; and in that method, call .request(_:) on the subscription specifying that the subscriber is willing to receive up to three values upon subscription.
        func receive(subscription: Subscription) {
            subscription.request(.max(3))
        }

        // Print the completion event.
        func receive(completion: Subscribers.Completion<Never>) {
            print("Received completion", completion)
        }

        // Print each value as it’s received and return .none, indicating that the subscriber will not adjust its demand; .none is equivalent to .max(0).
        func receive(_ input: Int) -> Subscribers.Demand {
            print("Received value", input)
            return .none
        }
    }

    // Create an instance of the subscriber and tell to publisher to attach it
    let subscriber = IntSubscriber()
    publisher.subscribe(subscriber)
}

// a Future can be used to asynchronously produce a single result and then complete. Add this new example to your playground:
example(of: "Future") {
    // Here, you create a factory function that returns a future of type Int and Never; meaning, it will emit an integer and never fail.
    func futureIncrement(
        integer: Int,
        afterDelay delay: TimeInterval) -> Future<Int, Never> {
            // This code defines the future, which creates a promise that you then execute using the values specified by the caller of the function to increment the integer after the delay.
            // Promise is a type alias to a closure that receives a Result containing either a single value published by the Future, or an error.
            Future<Int, Never> { promise in
                print("Original")
                DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                    promise(.success(integer + 1))
                }
            }
        }

    // Create a future using the factory function you created earlier, specifying to increment the integer you passed after a three-second delay.
    let future = futureIncrement(integer: 1, afterDelay: 3)

    // Subscribe to and print the received value and completion event, and store the resulting subscription in the subscriptions set. You’ll learn more about storing subscriptions in a collection later in this chapter, so don’t worry if you don’t entirely understand that portion of the example.
    future
      .sink(receiveCompletion: { print($0) },
            receiveValue: { print($0) })
      .store(in: &subscriptions)

    future
      .sink(receiveCompletion: { print("Second", $0) },
            receiveValue: { print("Second", $0) })
      .store(in: &subscriptions)
}

example(of: "PassthroughSubject") {
    // Define a custom error type.
    enum MyError: Error {
        case test
    }

    // Define a custom subscriber that receives strings and MyError errors.
    final class StringSubscriber: Subscriber {
        typealias Input = String
        typealias Failure = MyError

        func receive(subscription: Subscription) {
            subscription.request(.max(2))
        }

        func receive(completion: Subscribers.Completion<MyError>) {
            print("Received completion", completion)
        }

        func receive(_ input: String) -> Subscribers.Demand {
            print("Received value", input)
            // Adjust the demand based on the received value.
            // Returning .max(1) in receive(_:) when the input is "World" results in the new max being set to 3 (the original max (2) plus 1).
            return input == "World" ? .max(1) : .none
        }
    }

    // Create an instance of the custom subscriber.
    let subscriber = StringSubscriber()

    // Creates an instance of a PassthroughSubject of type String and the custom error type you defined.
    let subject = PassthroughSubject<String, MyError>()

    // Subscribes the subscriber to the subject.
    subject.subscribe(subscriber)

    // Creates another subscription using sink.
    let subscription = subject.sink { completion in
        print("Received completion (sink)", completion)
    } receiveValue: { value in
        print("Received value (sink)", value)
    }

    subject.send("Hello")
    subject.send("World")

    // Cancel the second subscription.
    subscription.cancel()

    // Send another value.
    subject.send("Still there?")

    // The first subscriber does not receive the "How about another one?" value, because it received the completion event right before the subjects sends the value. The second subscriber does not receive the completion event or the value, because its subscription was previously canceled.
    subject.send(completion: .finished)
    subject.send("How about another one?")
}

example(of: "CurrentValueSubject") {
    // Create a subscriptions set.
    var subscriptions = Set<AnyCancellable>()

    // Create a CurrentValueSubject of type Int and Never. This will publish integers and never publish an error, with an initial value of 0.
    let subject = CurrentValueSubject<Int, Never>(0)

    // Create a subscription to the subject and print values received from it.
    // Store the subscription in the subscriptions set (passed as an inout parameter instead of a copy).
    subject
        .print()
        .sink(receiveValue: { print($0) })
        .store(in: &subscriptions)

    subject.send(1)
    subject.send(2)

    // Unlike a passthrough subject, you can ask a current value subject for its value at any time
    print(subject.value)

    // Calling send(_:) on a current value subject is one way to send a new value. Another way is to assign a new value to its value property
    subject.value = 3
    print(subject.value)

    subject
        .print()
        .sink(receiveValue: { print("Second subscription:", $0) })
        .store(in: &subscriptions)

    subject.send(completion: .finished)
}

example(of: "Dynamically adjusting Demand") {
    final class IntSubscriber: Subscriber {
        typealias Input = Int
        typealias Failure = Never

        func receive(subscription: Subscription) {
            subscription.request(.max(2))
        }

        func receive(_ input: Int) -> Subscribers.Demand {
            print("Received value", input)

            switch input {
            case 1:
                return .max(2) // The new max is 4 (original max of 2 + new max of 2).
            case 3:
                return .max(1) // The new max is 5 (previous 4 + new 1).
            default:
                return .none // max remains 5 (previous 4 + new 0).
            }
        }

        func receive(completion: Subscribers.Completion<Never>) {
            print("Received completion", completion)
        }
    }

    let subscriber = IntSubscriber()

    let subject = PassthroughSubject<Int, Never>()

    subject.subscribe(subscriber)

    subject.send(1)
    subject.send(2)
    subject.send(3)
    subject.send(4)
    subject.send(5)
    subject.send(6)
}

// There will be times when you want to let subscribers subscribe to receive events from a publisher without being able to access additional details about that publisher.
example(of: "Type erasure") {
    // Create a subscriptions set.
    var subscriptions = Set<AnyCancellable>()

    // Create a passthrough subject.
    let subject = PassthroughSubject<Int, Never>()

    // Create a type-erased publisher from that subject.
    // AnyPublisher is a type-erased struct that conforms the Publisher protocol. Type erasure allows you to hide details about the publisher that you may not want to expose to subscribers
    let publisher = subject.eraseToAnyPublisher()

    // Subscribe to the type-erased publisher.
    publisher
        .sink(receiveValue: { print($0) })
        .store(in: &subscriptions)

    // Send a new value through the passthrough subject.
    subject.send(0)

    // Errors
    //publisher.send(1)
}

example(of: "async/await") {
    let subject = CurrentValueSubject<Int, Never>(0)
    
    Task {
        for await element in subject.values {
            print("Element: \(element)")
        }
        print("Completed.")
    }

    subject.send(1)
    subject.send(2)
    subject.send(3)

    subject.send(completion: .finished)
}

