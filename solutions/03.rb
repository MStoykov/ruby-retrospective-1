require 'bigdecimal'
require 'bigdecimal/util'

class Promotion
  attr_reader :description

  def initialize key, value
    send key, value
  end

  def apply count,price
    @lambda.call count, price
  end

private 
  def get_one_free value
    @description = "(buy #{value-1}, get 1 free)"
    @lambda = ->(count, price) { return count/value * price }
  end

  def threshold value
    percent = value.first[1]/'100'.to_d
    threshold = value.first[0]
    @description = "(#{value.first[1]}% off of every after the #{ordinal threshold})"
    @lambda = ->(count, price) do
      return count > threshold ? (count - threshold) * price * percent : 0
    end
  end

  def package value
    package = value.first[0]
    percent = value.first[1]/'100'.to_d
    @description = "(get #{value.first[1]}% off for every #{value.first[0]})"
    @lambda = ->(count, price) do
      if count >= package then
        on_promo = count - count%package
        return (price * on_promo * percent)
      else
        0
      end
    end
  end
  
  def ordinal number
    result = number.to_s
    if (number >= 10 and number <= 19) 
      result+="th"
    elsif (number%10 == 1) then result += "st"
    elsif (number%10 == 2) then result += "nd"
    elsif (number%10 == 3) then result += "rd"
    else result += "th"
    end
    result
  end
end

class Product
  attr_reader :name, :price, :promotion

  def initialize name, price, promotion = nil
    @price = price.to_d
    raise "too long" if name.length > 40
    raise "too low" if not ('999.99'.to_d >= @price and @price>= '0.01'.to_d)
    #TODO constants
    @name, @price = name, price.to_d
    @promotion = Promotion.new *promotion.first if promotion
  end

  def calculate count
    result = flat_calculate count 
    result -= discount count 
    result
  end

  def discount count
    promotion != nil ? promotion.apply(count, price) : 0
  end

  def flat_calculate count
    price * count
  end

  def eql? (other)
    name == other.name
  end

  alias :== :eql?

  def hash
    name.hash
  end

  alias :to_hash :hash
end

class Coupon
  attr_reader :name, :description, :info

  def initialize name, description
    @name,@description = name, description
    @info = "Coupon " + name + " - "
    @info << "%d%% off" % description.first[1] if description[:percent]
    @info << "%-.2f off" % description.first[1] if description[:amount]
  end

  def apply price
    return -(price * description[:percent]/'100'.to_d) if description[:percent]
    return -price if description[:amount] and description[:amount].to_d > price
    return -description[:amount].to_d if description[:amount]
  end
end

class Inventory
  def initialize
    @items = {}
    @coupons = {}
  end
  def register(name, cost, promotion = nil)
    raise "exist" if @items[name]
    @items[name] = Product.new(name, cost, promotion)
  end

  def register_coupon name, description
    raise "exist" if @coupons[name]
    @coupons[name] = Coupon.new(name, description)
  end

  def new_cart
    Cart.new method(:get_item), method(:get_coupon) 
  end

  def get_item name
    @items[name]
  end

  def get_coupon name
    @coupons[name]
  end
end

class Cart
  def initialize get_item, get_coupon
    @get_item, @get_coupon = get_item, get_coupon
    @items = Hash.new(0)
    @coupon = nil
  end

  def add name, count = 1
    raise "negative" if count < 1
    item = @get_item.call name
    raise "Missing Error" if not item
    raise "Sexist Error" if @items[item] + count > 99
    @items[item] += count
  end

  def use name
    coupon = @get_coupon.call name
    raise "Missing Error" if not coupon
    raise "Sexist Error2" if @coupon
    @coupon = coupon
  end

  def total
    return total_invoice[0]
  end


  def invoice
    return total_invoice[1]
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

  def item_info item
    result = [item.name, @items[item]]
    result << item.flat_calculate(result[1])
    if item.promotion then
      promotion = item.promotion
      result += [promotion.description, -promotion.apply(@items[item], item.price)]
    end
    result
  end

  def item_invoice info
    result = "| %-42s%4d | %8.2f |\n" % info
    result << "|   %-44s | %8.2f |\n" % info[3..4] if info.size == 5
    result
  end
  
  def coupon_invoice info
    "| %-46s | %8.2f |\n" % info
  end

  def total_invoice
    result, invoice = '0'.to_d, NEWHEAD.clone
    result, invoice = [result, invoice].zip(total_invoice_items).map { |i| i.inject(&:+) }
    if @coupon
      info = [@coupon.info, @coupon.apply(result)]
      invoice << coupon_invoice(info)
      result += info[1]
    end
    invoice << InvoiceEnd % result
    [result, invoice]
  end

  def total_invoice_items
    result, invoice = '0'.to_d, ""
    @items.keys.map { |item| item_info(item) }.each do |info|
      invoice << item_invoice(info)
      result += info[2]
      result += info[4] if info[4]
    end
    [result, invoice]
  end
end
