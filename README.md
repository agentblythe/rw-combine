# Combine: Asynchronous Programming with Swift: Materials

https://www.raywenderlich.com/books/combine-asynchronous-programming-with-swift

# Key Points - Publishers and Subscribers

- Publishers transmit a sequence of values over time to one or more subscribers, either synchronously or asynchronously.
- A subscriber can subscribe to a publisher to receive values; however, the subscriber’s input and failure types must match the publisher’s output and failure types.
- There are two built-in operators you can use to subscribe to publishers: sink(_:_:) and assign(to:on:).
- A subscriber may increase the demand for values each time it receives a value, but it cannot decrease demand.
- To free up resources and prevent unwanted side effects, cancel each subscription when you’re done.
- You can also store a subscription in an instance or collection of AnyCancellable to receive automatic cancelation upon deinitialization.
- You use a future to receive a single value asynchronously at a later time.
- Subjects are publishers that enable outside callers to send multiple values asynchronously to subscribers, with or without a starting value.
- Type erasure prevents callers from being able to access additional details of the underlying type.
- Use the print() operator to log all publishing events to the console and see what’s going on.

# Key Points - Transforming Operators

- You call methods that perform operations on output from publishers “operators”.
- Operators are also publishers.
- Transforming operators convert input from an upstream publisher into output that is suitable for use downstream.
- Marble diagrams are a great way to visualize how each Combine operators work.
- Be careful when using any operators that buffer values such as collect or flatMap to avoid memory problems.
- Be mindful when applying existing knowledge of functions from Swift standard library. Some similarly-named Combine operators work the same while others work entirely differently.
- It’s common chaining multiple operators together in a subscription to create complex and compound transformations on events emitted by a publisher.
