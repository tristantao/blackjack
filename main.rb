require_relative 'player'

class Game
  attr_reader :PLAYER_LIST
  def initialize
  end

  def prepare
    #Gets Player count and initializes.

    #Grab the number of players
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
      
    end
    print "Game Over!"
  end
end

#game = Game.new
#game.prepare
#game.start

