require 'bigdecimal'
require 'bigdecimal/util'

class Promotion
  def self.get_promotion description
    return NilPromotion.new if description == nil
    send description.first[0], description.first[1]
  end

private 
  def self.get_one_free value
    GetOneFree.new value
  end

  def self.threshold value
    percent = value.first[1]/'100'.to_d
    threshold = value.first[0]
    return Threshold.new percent, threshold
  end

  def self.package value
    package, percent = value.first[0], value.first[1]/'100'.to_d
    return Package.new package, percent
  end

  class Threshold 
    def initialize percent, threshold
      @percent, @threshold = percent, threshold
    end

    def description
      "(#{(@percent*100).to_i}% off of every after the #{ordinal @threshold})"
    end

    def apply count, price
      count > @threshold ? (count - @threshold) * price * @percent : 0
    end

    def ordinal number
      result = number.to_s
      if (number >= 10 and number <= 19) then result+="th"
      elsif (number%10 == 1) then result += "st"
        elsif (number%10 == 2) then result += "nd"
      elsif (number%10 == 3) then result += "rd"
      else result += "th"
      end
      result
    end
  end

  class Package
    def initialize package, percent
      @percent, @package = percent, package
    end

    def description
      "(get %2d%% off for every %d)" % [(@percent*100).to_i, @package]
    end

    def apply count, price
      if count >= @package
        on_promo = count - count % @package
        (price * on_promo * @percent)
      else
        0
      end
    end
  end

  class GetOneFree
    def initialize count
      @count = count #TODO change name
    end
    def apply count, price
      count/@count * price 
    end
    def description
      "(buy #{@count-1}, get 1 free)"
    end
  end

  class NilPromotion
    def apply count, price
      0
    end

    def description
      ''
    end
  end
end

class Product
  attr_reader :name, :price, :promotion

  def initialize name, price, promotion = nil
    raise "too long" if name.length > 40
    raise "too low" if not ('999.99'.to_d >= price and price>= '0.01'.to_d)
    #TODO constants
    @name, @price = name, price
    @promotion = Promotion.get_promotion promotion
  end

  def calculate count
    result = flat_calculate count
    result -= discount count 
    result
  end

  def discount count
    promotion.apply(count, @price) 
  end

  def price count
    @price * count
  end

  def eql? (other)
    name == other.name if other != nil 
  end

  alias :== :eql?

  def hash
    name.hash
  end

  alias :to_hash :hash
end

class Coupon

  def self.get_coupon name, description
    type, value = description.first
    case type #Batsov style
    when :percent then Percent.new name, value
    when :amount then Amount.new name, value.to_d
    else raise "Illegal Coupon #{type}"
    end
  end

  private
  class Percent
    attr_reader :name, :description, :info

    def initialize name, percent
      @name, @percent = name, percent
      @info = "Coupon %s - %d%% off" % [@name, @percent]
    end

    def apply price
      -(price * @percent/100)
    end
  end
  class Amount
    attr_reader :name, :description, :info

    def initialize name, amount
      @name, @amount = name, amount
      @info = "Coupon %s - %-.2f " % [@name, @amount] + "off"
    end

    def apply price
      @amount > price ? -price : -@amount
    end
  end
end

class Inventory
  def initialize
    @items = {}
    @coupons = {}
  end

  def register(name, cost, promotion = nil)
    raise "exist" if @items[name]
    @items[name] = Product.new(name, cost.to_d, promotion)
  end

  def register_coupon name, description
    raise "exist" if @coupons[name]
    @coupons[name] = Coupon.get_coupon(name, description)
  end

  def new_cart
    Cart.new method(:get_item), method(:get_coupon) 
  end

  def get_item name
    temp = @items[name]
    raise "No Item" if temp == nil 
    temp
  end

  def get_coupon name
    @coupons[name]
  end
end

class Cart
  def initialize get_item, get_coupon
    @get_item, @get_coupon = get_item, get_coupon
    @items = {}
    @coupon = nil
  end

  def add name, count = 1
    item = get_item name
    item.count += count
  end

  def use name
    raise "Sexist Error2" if @coupon
    coupon = @get_coupon.call name
    raise "Missing Error" if not coupon
    @coupon = coupon
  end

  def get_item name
    if @items[name] == nil
      @items[name] = CartItem.new @get_item.call(name)
    end
    @items[name]
  end

  def total
    sum = items_price
    sum += @coupon.apply sum if @coupon
    sum
  end

  def invoice
    sum, invoice = '0'.to_d, NEWHEAD.clone
    sum += items_price
    invoice += @items.values.map(&:to_invoice).inject(&:+)
    invoice << coupon_invoice(sum)
    sum += @coupon.apply sum if @coupon
    invoice << InvoiceEnd % sum
    invoice
  end

  private
  NEWHEAD =<<LINES
+------------------------------------------------+----------+
| Name                                       qty |    price |
+------------------------------------------------+----------+
LINES

  InvoiceEnd =<<LINES
+------------------------------------------------+----------+
| TOTAL                                          | %8.2f |
+------------------------------------------------+----------+
LINES

  def items_price 
    @items.values.map(&:price).inject(&:+)
  end

  def coupon_invoice sum
    return "" if @coupon == nil
    info = [@coupon.info, @coupon.apply(sum)]
    "| %-46s | %8.2f |\n" % info
  end

  class CartItem
    attr_reader :item, :count

    def initialize item, count = 0 
      @count = 0
      @item = item
      @count += count
    end

    def count= (count)
      raise "negative" if (count) < 0
      raise "too much" if (count) > 99
      @count = count
    end

    def to_invoice
      result = "| %-42s%4d | %8.2f |\n" % [@item.name, count,@item.price(count)]
      if @item.discount(count).nonzero?
        array = [@item.promotion.description, -@item.discount(count)]
        result << "|   %-44s | %8.2f |\n" % array
      end
      result
    end

    def price
      @item.price(@count) - @item.discount(@count)
    end
  end
end
