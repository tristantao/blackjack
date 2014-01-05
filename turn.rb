# Author: Tristan Tao
# Purpose: below
=begin 
This file contains the class that represents a single turn (driven and used in game_core.rb 
It houses vars/functions to represent the table (player hands/cards), dealer and more.
It has the functionality for most dealer/player interaction (bets, evaluation, payouts). 
=end

require_relative 'player'
require_relative 'util'
#require 'byebug'

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
    
    if Card.is_blackjack?(@PLAYER_TO_BETS[player].keys[0])
      printf "BLACKJACK!____Player %s's turn is over____\n", player.name
      return nil
    end

    #first process any special states
    doubled_down = self.check_special(player)

    hand_index = 0
    for hand in @PLAYER_TO_BETS[player].keys
      hand_index += 1
      one_card = doubled_down[hand] #since doubled down, only take one card
      
      #Doubled down, so hit and it.
      if one_card
        printf "%s doubled down on %s, hitting once and ending\n", player.name, Card.format_hand(hand)
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
      sleep(1)
    end
    printf "____Player %s's turn is over____\n", player.name
    sleep(1)
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
    #Allows doubling down after split.
    #Does NOT allow re-split
    # @returns a hash: {hand => boolean} containing bolean indicating the hand was doubled down.

    starting_hand = @PLAYER_TO_BETS[player].keys[0]
    initial_bet = @PLAYER_TO_BETS[player][starting_hand]

    #Check for split
    if Card.can_split?(starting_hand) and player.has_enough_money(@PLAYER_TO_BETS[player][starting_hand])
      #Ask if user wants to split
      printf "%s's hand of %s can be split. Proceed? (s)plit/(n)o.\n", player.name, Card.format_hand(starting_hand)
      while true
        split_response = gets.chomp
        if split_response.downcase == 's'
          player.bet(@PLAYER_TO_BETS[player][starting_hand]) #betting for the additional hand

          new_player_stat = {}
          #split the hand into 2, enter split bet appropariately
          hand_one = [starting_hand[0]]
          hit_one = @CURRENT_DECK.pop
          hand_one << hit_one
          new_player_stat[hand_one] = initial_bet

          hand_two = [starting_hand[1]]
          hit_two = @CURRENT_DECK.pop
          hand_two << hit_two
          new_player_stat[hand_two] = initial_bet
          
          @PLAYER_TO_BETS[player] = new_player_stat

          printf "___Split into %s and %s___\n", Card.format_hand(hand_one), Card.format_hand(hand_two)
          break
        elsif split_response.downcase == 'n'
          break
        else
          printf "Your input of \"%s\" is invalid. Try again [(s)plit/(n)o]: \n", split_response
        end
      end
    end
    @PLAYER_TO_BETS.rehash
    #@PLAYER_TO_BETS[player].rehash

    #Ask for Double
    double_down = {}
    for hand in @PLAYER_TO_BETS[player].keys
      if not player.has_enough_money(@PLAYER_TO_BETS[player][hand])
        printf "Not enough money to double down for hand: %s\n", Card.format_hand(hand)
        double_down[hand] = false
        next
      end

      printf "For %s's hand of %s, with bet $%s, would you like to Double Down? Reply (d)ouble/(n)o.\n" , player.name, Card.format_hand(hand), @PLAYER_TO_BETS[player][hand]
      while true
        double_down_response = gets.chomp
        if double_down_response.downcase == 'd'
          double_down[hand] = true
          player.bet(@PLAYER_TO_BETS[player][hand]) #Make additional bet
          @PLAYER_TO_BETS[player][hand] = @PLAYER_TO_BETS[player][hand] * 2 #double payout amount
          printf "Doubling down initial bet for %s to $%s\n", Card.format_hand(hand), @PLAYER_TO_BETS[player][hand]
          @PLAYER_TO_BETS[player].rehash
          break
        elsif double_down_response.downcase =='n'
          double_down[hand] = false
          break
        else
          printf "Your input of \"%s\" is invalid. Try again [(d)ouble/(n)o]: \n", double_down_response
        end
      end
    end
    #@PLAYER_TO_BETS.rehash
    #@PLAYER_TO_BETS[player].rehash
    return double_down
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
    while Card.evaluate(@DEALER_HAND) < 17
      sleep(1)
      new_card = @CURRENT_DECK.pop
      @DEALER_HAND << new_card
      printf "Dealer hit, received %s\n", new_card.value
      printf "New dealer hand: %s\n", Card.format_hand(@DEALER_HAND)
    end
    sleep(1)
    if Card.evaluate(@DEALER_HAND) > 21
      printf "\n____Dealer's turn complete with hand %s: BUST ____\n", Card.format_hand(@DEALER_HAND)
    else
      printf "\n____Dealer's turn complete with hand %s ____\n", Card.format_hand(@DEALER_HAND)
    end
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

