require_relative 'player'
require_relative 'util'
require 'byebug'

class Game
  attr_accessor :PLAYER_LIST
  def initialize
    @INITIAL_BETS = {} #<Player, Bet>, which is populated at the beginning of each round.
    
    @PLAYER_LIST = [] #Master list of pleayers

    @DECK_INSTANCE = Deck.instance
  end

  def prepare
    #Gets Player count and initializes.
    #Grab the number of players and creates PLAYER_LIST [<Player>]
    print "Welcome to Black Jack! How many players?\n"
    while true
      raw_player_size = gets.chomp
      begin
        @int_player_size= Integer(raw_player_size)
      rescue Exception => e
        print ("Player number must be in integers, please re-enter! \n")
        next
      end
      if @int_player_size <= 0
        print ("Player number must grater than 0, please re-enter! \n")
        next
      end
      break
    end

    #Create a list of players, which are Player objects.
    for i in 1..@int_player_size
      #Initialize with (name, starting_cash)
      current_player = Player.new("Player"+i.to_s, 1000)
      @PLAYER_LIST << current_player
    end
  end

  def game_end?
    #Returns true, if no player has money.
    for p in @PLAYER_LIST
      if p.cash > 0
        return false
      end
    end
    return true
  end

  def start
    #Start the betting loop; ends when everyone is broke!
    while not self.game_end?
      @INITIAL_BETS = {}

      printf "*" * 15
      printf " Starting New Round "
      puts "*" * 15
      
      #First ask everyone for their initial bet.
      for player in @PLAYER_LIST
        if not player.is_broke?
          player_bet = query_for_bet(player)
          @INITIAL_BETS[player] = player_bet
        end
      end

      #Deal cards and prepare current turn
      deck_size = ((5*(@PLAYER_LIST.length + 1)) / 52.0).ceil #determine the number of decks
      current_turn = Turn.new(@INITIAL_BETS, @DECK_INSTANCE.new_shuffled_deck(deck_size))
      current_turn.deal()

      #Cards dealt, so start each player's turn
      for player in @INITIAL_BETS.keys
        current_turn.process(player)
      end

      #Dealer plays with basic strategy
      current_turn.dealer_play()

      #Now assess the table, payout as needed.
      current_turn.end_turn_process()
      
      #remove people who are now broke!
      remove_losers()

    end
    print "Game Over!"
  end

  def remove_losers()
    #Will remove players who no longer have money
    for player in @PLAYER_LIST
      if player.cash == 0
        @PLAYER_LIST.delete(player)
        printf "****Removing %s from the game since the player no longer has cash****\n", player.name
      end
    end
  end

  def query_for_bet(player)
    #Queries a player to print. Will loop until successful bet.
    # @return the integer amount successfully bet.
    printf "Hi %s how much would you like to bet? (You currently have $%s)\n", player.name, player.cash
    while true
      raw_bet_size = gets.chomp
      begin
        int_bet_size = player.bet(raw_bet_size)
      rescue ArgumentError => aE
        puts aE
        puts "Remember you can only bet positive integer values, and only up to your current worth. Please re-enter bet"
        next
      end
      break
    end
    return int_bet_size
  end
end

class Turn
  #This class will represent a single round of black jack. 
  #It will have functions that can return player status and bets.
  #By defaukt we use a fresh deck each turn, makes card-counting impossible.
  #You can continue with the same deck by initializing next turn with old deck

  attr_reader :CURRENT_DECK, :PLAYER_TO_BETS
  
  def initialize(initial_bets, deck)
    #TODO RENAME TO PLAYER_HAND_BETS
    @PLAYER_TO_BETS = {} #{player1:{[hand1] : bet1, [hand2] : bet2,
                          #player2:{...}}
    @DEALER_HAND = [] #list of cards
    @CURRENT_DECK = deck

    for player in initial_bets.keys
      @PLAYER_TO_BETS[player] = {:initial_bet => initial_bets[player]}
    end
  end

  def process(player)
    #Given a player, print out their current hand, and offer play options as follows.
    #1: check for special states, i.e. split, double down
    #2: for each elgible hand, ask if the player wants to (h)it/(s)tay
    #The function only updates the current turn Data, which is then processed at end_turn_process()
    a = self.print_player_status(player)
    one_card = self.check_special(player)

    hand_index = 0
    for hand in @PLAYER_TO_BETS[player].keys
      hand_index += 1

      #Doubled down, so hit and quit.
      if one_card
        printf "You doubled down, hitting once and ending\nxs"
        hand_value = self.hit(player, hand)
        if hand_value > 21
          printf "Bust, hand%s of %s is now over 21.\n", hand_index, hand_value
        end
        next
      end

      #Regular hit/stay, loop for each hand until valid response
      while true
        printf "For %s's hand%s of %s, with bet $%s, would you like to hit? Reply (h)it/(s)tay.\n" , player.name, hand_index, Card.format_hand(hand), @PLAYER_TO_BETS[player][hand]
        hit_stay_response = gets.chomp.downcase
        if hit_stay_response == "h" or hit_stay_response == "hit"
          hand_value = self.hit(player, hand)
          if hand_value > 21
            printf "Bust, hand%s is now over 21.\n", hand_index
            break
          end          
        elsif hit_stay_response == "s" or hit_stay_response == "stay"
          break
        else
          printf "Your input of \"%s\" is invalid. Try again: \n", hit_stay_response
          next
        end
      end
      printf "____Player %s's turn is over____\n", player.name
      sleep(1)
    end  
  end

  def print_player_status(player)
    #Prints out player hand and bet,
    player_stat = @PLAYER_TO_BETS[player]
    if player_stat == nil
      raise ArgumentError "Plyer does not exist", caller
    else
      hidden_dealer_hand = Card.format_hand(@DEALER_HAND)
      hidden_dealer_hand[0] = "*"
      #puts "=" * 25
      printf "\nThe dealer's current hand is %s", hidden_dealer_hand
      printf "\n%s's current hand OVERVIEW: hand | corresponding bet\n", player.name
      for hand in player_stat.keys
        printf "%s | $%s\n", Card.format_hand(hand) ,player_stat[hand]
      end
    end
    print "\n"
  end

  def check_special(player)
    #Checks for special conditions, such as double down, split. 
    #Will add to @PLAYER_TO_BETS[plyer] hash, which maps hands to bet
    #@return true, if only one more hit is allowed
    return nil
  end

  def get_hands(player)
    # @returns a list of hands (which is another list), in case player has multiple hands
    # e.g. [[j,k], [a,10]]
    # will return empty list if player not in game
    if @PLAYER_TO_BETS[player] != nil
      return @PLAYER_TO_BETS[player].keys
    else
      return []
    end
  end

  def deal
    #deal everyone whose initial bet != 0 a pair of cards, replacing their :initial_bet value.
    #Completes 2 rounds of single card dealing for each person.

    for player in @PLAYER_TO_BETS.keys
      #Deal one card for everyone whose initial bet is > 0
      if @PLAYER_TO_BETS[player][:initial_bet] > 0
        card = @CURRENT_DECK.pop
        @PLAYER_TO_BETS[player][[card]] = @PLAYER_TO_BETS[player][:initial_bet]
        @PLAYER_TO_BETS[player].delete(:initial_bet)
      else
        @PLAYER_TO_BETS[player].delete(:initial_bet)#Remove those who are not in the game
      end
    end
      @DEALER_HAND << @CURRENT_DECK.pop #dealer's first card
    @PLAYER_TO_BETS.rehash
    for player in @PLAYER_TO_BETS.keys
      #Deal the second card
      for half_hand in @PLAYER_TO_BETS[player].keys #list of one card
        half_hand << @CURRENT_DECK.pop
        @PLAYER_TO_BETS[player].rehash
      end
    end
    @DEALER_HAND << @CURRENT_DECK.pop #dealer's second card
    print "=" * 10
    print " Cards Dealt "
    puts "=" * 10
  end

  def hit(player, hand)
    # for a particukar hand of a player, add a new card, updating @PLAYER_TO_BETS
    # @returns the value of the new hand

    if not @PLAYER_TO_BETS.has_key?(player)
      raise ArgumentError, "The player trying to hit() is not in the game", caller
    end

    if not @PLAYER_TO_BETS[player].has_key?(hand)
      raise ArgumentError, "Player doesn't have the hand specified in hit()", caller
    end

    new_card = @CURRENT_DECK.pop
    hand << new_card
    printf "Hit Result: %s \n", new_card.value
    
    @PLAYER_TO_BETS[player].rehash
    return Card.evaluate(hand)
  end

  def dealer_play()
    #Process dealer's turn, after players have finished
    #current strategy is if player remaining, hit until over 17.
    # @updates :DEALER_HAND
    # @return Dealer's final hand value

    printf "\n____Beginning Dealer's turn with hand %s ____\n", Card.format_hand(@DEALER_HAND)

    printf "Dealer is thinking\n"
    sleep(1)
    while Card.evaluate(@DEALER_HAND) < 17
      sleep(1)
      new_card = @CURRENT_DECK.pop
      @DEALER_HAND << new_card
      printf "Dealer hit, received %s\n", new_card.value
      printf "New dealer hand: %s\n", Card.format_hand(@DEALER_HAND)
    end
    sleep(1)
    printf "\n____Dealer's turn complete with hand %s ____\n", Card.format_hand(@DEALER_HAND)
    sleep(1)
    return Card.evaluate(@DEALER_HAND)
  end

  def end_turn_process()
    # arrange the payout as defined by blackjack rules.
    # Implements "draw" for all ties, meaning pay back original bet.

    printf "\n____processing results with dealer hand: %s____\n", Card.format_hand(@DEALER_HAND)

    dealer_bust = false
    dealer_val = Card.evaluate(@DEALER_HAND)
    if dealer_val > 21
      dealer_bust = true
    end

    for player in @PLAYER_TO_BETS.keys
      for hand in @PLAYER_TO_BETS[player].keys
        hand_value = Card.evaluate(hand)
        bet_value = @PLAYER_TO_BETS[player][hand]
        if  hand_value > 21 #player bust, no payout.
          printf "BUST: %s's hand of %s will not receive any payout\n", player.name, Card.format_hand(hand)
        elsif hand_value <= 21 and not dealer_bust
          #compare hands
          if hand_value > dealer_val
            printf "WIN: Payout to %s's hand of %s for $%s\n", player.name, Card.format_hand(hand), bet_value*2
            player.get_paid(bet_value * 2)
          elsif hand_value < dealer_val
            printf "LOSS: %s's hand of %s will not receive any payout\n", player.name, Card.format_hand(hand)
          else
            printf "DRAW: Return to %s's hand of %s for $%s\n", player.name, Card.format_hand(hand), bet_value
            player.get_paid(bet_value)
          end #end hand comparison
        elsif hand_value <= 21 and dealer_bust
          printf "DEALER_BUST: Payout to %s's hand of %s for $%s\n", player.name, Card.format_hand(hand), bet_value*2
          player.get_paid(bet_value * 2)
        else
          raise ArgumentError "Unhandled case in end_turn_process()", caller
        end
      end
    end
    printf "___Finished Processing Payouts___\n\n"
  end

end
 
game = Game.new
game.prepare
game.start
