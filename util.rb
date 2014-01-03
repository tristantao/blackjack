require 'singleton'

class Card
  attr_reader :kind, :value
  def initialize(kind, value)
    @kind = kind
    @value = value
  end

  def is_blackjack(hand)
    return hand.length == 2 && hand.value(hand)
  end
  
  def evaluate(hand)
    #Used much like a static method. Calculates the value of a hand.
    #a hand should be a list of cards.
    hand_value = 0
    has_has = false
    for card in hand
      if card.value.is_a? Integer
        hand_value += card.value
      else
        hand_value += 10
        has_ace = true
      end
    end
    if has_ace == true and hand_value > 21
      hand_value -= 10
    end
    return hand_value
  end
end

class Deck
  include Singleton
  attr_reader :DECK

  @@DECK = []
  def initialize
    #Create the cards.
    for value in [2, 3, 4, 5, 6, 7, 8, 9, 10, 'J', 'Q', 'K', 'A']
      for kind in [:spades, :hearts, :diamonds, :clubs]
        @@DECK << Card.new(kind, value)
      end
    end
  end

  def new_shuffled_deck
    #returns a new shuffled list of cards representing a deck. 
    new_deck = Array.new(@@DECK).shuffle
    return new_deck
  end
  
end

##usage
=begin
a = Deck.instance
b = Deck.instance
a_deck = a.new_shuffled_deck
b_deck = b.new_shuffled_deck
=end
