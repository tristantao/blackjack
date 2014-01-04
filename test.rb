require_relative 'main'
require_relative 'util'
require 'test/unit'


class TestDeck < Test::Unit::TestCase
  def test_deck_size
    #tests that 52 cards are instantiated
    a = Deck.instance
    a_deck_1 = a.new_shuffled_deck.length
    a_deck_2 = a.new_shuffled_deck.length
    assert_equal(52, a_deck_1)
    assert_equal(52, a_deck_2)
    b = Deck.instance
    assert_equal(52, b.new_shuffled_deck.length)
  end

  def test_cards
    #test that the content of the deck is equivalent to a full deck
    a = Deck.instance
    a_deck_1 = a.new_shuffled_deck
    value_hash_received = Hash.new(0)
    for card in a_deck_1
      value_hash_received[card.evaluate([card])] = value_hash_received[card.evaluate([card])] + 1
    end
    for answer_check in 2..9
      #check that each number appears 4 times
      assert_equal(4, value_hash_received[answer_check])
    end
    #check that there are 20 10's.
    assert_equal(20, value_hash_received[10])
  end

  def test_card
    #test that the cards are getting correct values
  end
end

class TestPlayer <  Test::Unit::TestCase

  def setup
    @tester = Player.new("chester", 1000)
  end
  def teardown
  end
  
  def test_name
    assert_equal("chester", @tester.name)
  end

  def test_bet_happy
    @tester.bet("100")
    assert_equal(900, @tester.cash)
  end

  def test_bet_sad
    assert_raise ArgumentError do
      @tester.bet("10.01")
    end
  end
  
  def test_pay_happy
    @tester.get_paid('10')
    assert_equal(1010, @tester.cash)
  end

  def test_broke
    @tester.bet("1000")
    assert_equal(true, @tester.is_broke?)
  end
end

class TestTurn <  Test::Unit::TestCase

  def setup
    @deck = Deck.instance
    @game = Game.new
    @c = Player.new("Craig", 1000)
    @j = Player.new("Jamie", 1000)
    @game.PLAYER_LIST << @c
    @game.PLAYER_LIST << @j

    @initial_bet = {@c => 200,
                         @j => 100}
    @current_turn = Turn.new(@initial_bet, @deck.new_shuffled_deck)
    @current_turn.deal
  end
  
  def test_get_hands
    assert_equal(@current_turn.PLAYER_TO_BETS[@j].keys, @current_turn.get_hands(@j)) 
  end

  def test_deal
    assert_equal(@current_turn.get_hands(@j)[0].length, 2)
  end

  def test_hit_happy
    result = @current_turn.hit(@j, @current_turn.get_hands(@j)[0])
    assert_equal(@current_turn.get_hands(@j)[0].length, 3)
    result = @current_turn.hit(@j, @current_turn.get_hands(@j)[0])
    assert_equal(@current_turn.get_hands(@j)[0].length, 4)
  end

  def test_hit_sad_player
    spectator = Player.new("Lindgren", 1000)
    fake_hand = [Card.new('Spades','K'), Card.new('Spades','J')]

    assert_raise ArgumentError do
      @current_turn.hit(spectator,fake_hand) 
    end
  end
  
  def test_hit_sad_hand
    fake_hand = [Card.new('Spades','K'), Card.new('Spades','J')]

    assert_raise ArgumentError do
      @current_turn.hit(@j, fake_hand) 
    end
  end
end


class TestGame <  Test::Unit::TestCase

  def setup
    @game = Game.new
    @game.PLAYER_LIST << Player.new("Craig", 1000)
    @game.PLAYER_LIST << Player.new("Jamie", 1000)
  end
  
  def test_bet
    @game.PLAYER_LIST[0].bet('100')
    assert_equal(@game.PLAYER_LIST[0].cash, 900)
  end
end


