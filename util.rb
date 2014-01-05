# Author: Tristan Tao
# Purpose: Contains Card/Deck, (was planned for other misc) classes.

require 'singleton'

class Card
  attr_reader :kind, :value
  def initialize(kind, value)
    @kind = kind
    @value = value
  end

  def self.is_blackjack?(hand)
    return hand.length == 2 && Card.evaluate(hand) == 21
  end

  def self.evaluate(hand)
    #Calculates the value of a hand.
    #A hand should be a list of cards.
    hand_value = 0
    has_has = false
    #byebug
    for card in hand
      if card.value.is_a? Integer
        hand_value += card.value
      elsif card.value == 'A'
        has_ace = true
        hand_value += 1
      else
        hand_value += 10
      end
    end
    if has_ace and hand_value <= 11
      hand_value += 10
    end
    return hand_value
  end
  
  def self.format_hand(hand)
    #Given a hand, return list of string names suitable for printing.
    result = hand.map { |h| h.value }
    return result
  end

  def self.can_split?(hand)
    if self.evaluate([hand[0]]) ==  self.evaluate([hand[1]])
      return true
    end
    return false
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

  def new_shuffled_deck(deck_count)
    #returns a new shuffled list of cards representing a deck.
    #will return @param deck_count number of decks
    return_deck = []
    for deck_index in 1..deck_count
      new_deck = Array.new(@@DECK)
      return_deck += new_deck
    end
      return_deck.shuffle!
    return return_deck
  end
  
end

##usage
=begin
a = Deck.instance
b = Deck.instance
a_deck = a.new_shuffled_deck
b_deck = b.new_shuffled_deck
=end
