require 'singleton'

class Card
  attr_reader :kind, :value
  def initialize(kind, value)
    @kind = kind
    @value = value
  end
  
  def evaluate
    #returns the numeric value of the card. i.e. King = 13 etc.
    begin
      return Integer(@value)
    rescue ArgumentError => aE
      if @value == "K"
        return 13
      elsif @value == "Q"
        return 12
      elsif @value == "J"
        return 11
      else
        raise "Unrecognized Card Value: " + aE
      end
    end
  end

end

class Deck
  include Singleton
  attr_reader :DECK

  @@DECK = []
  def initialize()
    #Create the cards.
    for value in ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K']
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
