# Author: Tristan Tao
# Purpose: below
=begin 
This file contains the main loop for the game in start().
This file prepares the game, runs the main loop, and mananges/utilizes turn.
=end

require_relative 'player'
require_relative 'util'
require_relative 'turn'
#require 'byebug'

class Game
  attr_accessor :PLAYER_LIST
  def initialize
    @INITIAL_BETS = {} #<Player, Bet>, which is populated at the beginning of each round.
    @PLAYER_LIST = [] #Master list of pleayers

    @DECK_INSTANCE = Deck.instance
  end

  def prepare
    #Gets Player count and initializes.
    #Grab the number of players and populates PLAYER_LIST [<Player>]
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
      for player in current_turn.PLAYER_TO_BETS.keys
        current_turn.process(player)
      end

      #Dealer plays with basic strategy
      current_turn.dealer_play()

      #Now assess the table, payout as needed.
      current_turn.end_turn_process()
      
      #remove people who are now broke!
      remove_losers()

    end
    puts "Game Over!"
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

