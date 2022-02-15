import Foundation
import Combine

var subscriptions = Set<AnyCancellable>()

example(of: "Create a Blackjack card dealer") {
    let dealtHand = PassthroughSubject<Hand, HandError>()
    
    func deal(_ cardCount: UInt) {
        var deck = cards
        var cardsRemaining = 52
        var hand = Hand()
        
        for _ in 0 ..< cardCount {
            let randomIndex = Int.random(in: 0 ..< cardsRemaining)
            hand.append(deck[randomIndex])
            deck.remove(at: randomIndex)
            cardsRemaining -= 1
        }
        
        // Challenge Part #1
        // Evaluates the result returned from the hand’s points property. If the result is greater than 21, send the HandError.busted through the dealtHand subject. Otherwise, send the hand value.
        if hand.points > 21 {
            dealtHand.send(completion: .failure(.busted))
        } else {
            dealtHand.send(hand)
        }
    }
    
    // Challenge Part #2
    // subscribe to dealtHand and handle receiving both values and an error.
    _ = dealtHand.sink(receiveCompletion: { completion in
        if case let .failure(error) = completion {
            print(error)
        }
    }, receiveValue: { 
        print("Cards: \($0.cardString) [\($0.points)]")
    })
    
    deal(3)
}

