require_relative 'player'
require_relative 'util'

class Game
  attr_accessor :PLAYER_LIST
  def initialize
    @INITIAL_BETS = {} #<Player, Bet>
    @DEALER_HAND = {} #<player, [<
    @PLAYER_LIST = []
    @DECK_INSTANCE = Deck.instance
  end

  def prepare
    #Gets Player count and initializes.
    #Grab the number of players and creates PLAYER_LIST [<Player>]

    print "Welcome to Black Jack! How many players?\n"
    raw_player_size = gets.chomp
    begin
      @int_player_size= Integer(raw_player_size)
    rescue Exception => e
      abort("Player Number must be be in integers!")
    end

    #Create a list of players, which are Player objects.
    @PLAYER_LIST = []
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
 
      #First ask everyone for their bet price.
      for player in @PLAYER_LIST
        if not player.is_broke?
          player_bet = query_for_bet(player)
          @INITIAL_BETS[player] = player_bet
        end
      end
      current_turn = Turn.new(@INITIAL_BETS, @DECK_INSTANCE.new_shuffled_deck)
      current_turn.deal()

      for player in @INITIAL_BETS.keys
        current_turn.process(player)
      end
    end
    print "Game Over!"
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
        puts "Remember you can only bet integer values, and only up to your current worth. Please re-enter bet"
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

  attr_reader :CURRENT_DECK 

  def initialize(initial_bets, deck)
    #TODO RENAME TO PLAYER_HAND_BETS
    @PLAYER_TO_BETS = {} #{player1:{[hand1] : bet1, [hand2] : bet2,
                          #player2:{...}}
    @CURRENT_DECK = deck

    for player in initial_bets.keys
      @PLAYER_TO_BETS[player] = {:initial_bet => initial_bets[player]}
    end
  end

  def process(player)
    #Given a player, print out their current hand, and offer play options as follows.
    #1: check for special states, i.e. split, double down
    #2: for each elgible hand, ask if the player wants to (h)it/(s)tay

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
          printf "Bust, hand%s is now over 21.\n", hand_index
        end
        next
      end

      #Regular hit/stay, loop for each hand until valid response
      while true
        printf "For you hand%s of %s, with bet %s, would you like to hit? Reply (h)it/(s)tay.\n" , hand_index, hand, @PLAYER_TO_BETS[player]
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
    end  
  end

  def print_player_status(player)
    #Prints out player hand and bet,
    player_stat = @PLAYER_TO_BETS[player]
    if player_stat == nil
      raise ArgumentError "Plyer does not exist", caller
    else
      
      print "Your current hand overview: hand | corresponding bet\n"
      for hand in player_stat.keys
        printf "%s | $%s\n", hand ,player_stat[hand]
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
    if @PLAYER_TO_BETS.keys != nil
      return @PLAYER_TO_BETS.keys
    else
      return []
    end
  end

  def deal
    #deal everyone whose initial bet != 0 a pair of cards, replacing their :initial_bet value.
    for player in @PLAYER_TO_BETS.keys
      if @PLAYER_TO_BETS[player][:initial_bet] != 0
        ##@TODO figure out the proper rule for blackjack...

      end
    end
  end

  def hit(player, hand)
    # for a particukar hand of a player, add a new card, updating @PLAYER_TO_BETS
    # @returns the value of the new hand
    current_bet = @PLAYER_TO_BETS[player][hand]
    @PLAYER_TO_BETS[player].delete(hand)

    new_card = @CURRENT_DECK.pop
    hand << new_card
    @PLAYER_TO_BETS[player][hand] = current_bet

    return Card.evaluate(hand)
  end
  
end
 
game = Game.new
game.prepare
#game.query_for_bet(game.PLAYER_LIST[0])
game.start
