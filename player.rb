
class Player
  attr_reader :name, :cash

  def initialize(name, cash)
    @name = name
    @cash = cash
  end

  def bet(amount)
    # @throws ArgumentError if not enough money, or non-integer bet.
    # @return the integer amount successfully bet.
    #You put the amount on the table, i.e. immediately deduct cash.
    #You will gain appropriate ammount back through get_paid() if you win.

    amount = Integer(amount)
    if amount < 0
      raise ArgumentError, "Can't bet negative amount", caller
    end
    if amount <= @cash
      @cash -= amount
      return amount
    else
      raise ArgumentError, "Not Enough Money", caller
    end

  end
  def get_paid(amount)
    # @throws ArgumentError if non-integer, or negative payout amount received
    # Immediately increases player's current cash.
    amount = Integer(amount)
    if amount <= 0
      raise ArgumentError, "Can't give negative payouts.", caller
    end
    @cash += amount
  end

  def is_broke?
    # @return true iff the current player has no more money.
    return @cash == 0
  end

  def has_enough_money(amount)
    # @return true if player has enough money left over
    return amount <= @cash
  end
end
