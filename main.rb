require_relative 'player'

class Game
  attr_accessor :PLAYER_LIST
  def initialize
    @CURRENT_BETS = {} #<Player, Bet>
    @DEALER_HAND = []
    @PLAYER_LIST = []
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
          @CURRENT_BETS[player] = player_bet
        end
        
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
end
 
game = Game.new
game.prepare
game.query_for_bet(game.PLAYER_LIST[0])
game.start
