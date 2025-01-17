# https://github.com/MStoykov/ruby-retrospective-1/blob/master/solutions/05.rb
# it's half way done
=begin TODO LIST 
* Complete reimplementing with Container
*.* Code
* make regexp part of each class
* match better
* make Formatter a Container
* remove put_before with somekind of ordered list construction
=end

module Tag
attr_reader :text

  def initialize text
    @text = text
    ekranize unless @no_ekranize
  end

  SPECIAL_SYMBOLS = {'&' => '&amp;', '<' => '&lt;', '>' => '&gt;', '"' => '&quot;'}
  def ekranize# TODO find out what the actual term is 
    SPECIAL_SYMBOLS.each { |key, value| @text.gsub!(key.to_s, value) } 
  end

  def opening_tag
    throw self.class.to_s unless @tag 
    (@indent||'') + '<' + @tag + attributes_string + '>'
  end

  def attributes_string
    return '' unless @attributes
    @attributes.map { |key, value| " %s=\"%s\"" % [key, value] }.inject(:+) 
  end

  def closing_tag
    '</' + @tag + ">"
  end

  def to_s
    opening_tag + @text + closing_tag
  end
end

module InlineTag # TODO: add the inline stuff here :)
  include Tag
end

module BlockTag # basic things for block type elements
  include Tag

  def initialize text
    super text
  end

  def +(other)
    @text << "\n" << other.text

    self
  end

  def closing_tag
    super + "\n" 
  end

  def put_before text
    @text = (text + opening_tag + @text)
  end
end

module PostFormattedTag # AKA not PreFormated
  include Tag
  
  def initialize text
    super text
    format_inline
  end

  def format_inline # Smells to me
    @text.gsub!(/((\*\*[^<]*?\*\*)|(_[^<]*?_))/) do |s|
      case s
      when /^\*/  then Strong.new(s[2..-3]).to_s
      when /^_/   then Emphasize.new(s[1..-2]).to_s
      end
    end
    @text.gsub!(/\[(.*?)\]\((.*?)\)/) { |s| Link.new($1, $2).to_s }
  end
end

module ContainerTag # has to be code, quote and lists 
  attr_reader :pre
  include Tag

  def +(other)
    self << other.pre
    self
  end

  def <<(other)
    if other.instance_of? @pre.last.class
      @pre.last + other 
    else
      @pre.concat [*other]
    end
    self
  end

  def to_s
    opening_tag + inner_to_s  + closing_tag
  end

  def inner_to_s
    temp = @pre.map(&:to_s).inject(:+) 
    @dont_strip_pre ? temp : temp.strip
  end
end

class Paragraph 
  include BlockTag
  include PostFormattedTag

  def initialize text
    super text.strip
    @tag = 'p'
  end
end

class NilTag
  include BlockTag

  def initialize text = ''
    super text
  end

  def opening_tag
    ''
  end

  def closing_tag
    ''
  end
end

class Header
  include BlockTag
  include PostFormattedTag
  def initialize text, size
    super text.strip
    @tag = "h" + size.to_s
  end
end

class Code
  include BlockTag

  def initialize text
    super text
    @tag = 'pre><code'
  end

  def opening_tag
    '<pre><code>'
  end

  def closing_tag
    "</code></pre>\n"
  end
end

class Quote
  attr_reader :pre

  include BlockTag
  include PostFormattedTag
  include ContainerTag

  def initialize text 
    if /^\s*$/ === text # SMELLLS
      @pre = [NilTag.new("\n")]
    else
      @pre = [Paragraph.new(text)]
    end
    @tag = "blockquote"
    super text
  end

  def to_s 
    super
  end
end

Strong, Emphasize = %w[strong em].map do |tag|
  Class.new do 
    include InlineTag
    include PostFormattedTag

    define_method(:initialize) do |text|
      @tag = tag
      @no_ekranize = true 
      super text
    end 
  end
end

class Link
  include InlineTag
  include PostFormattedTag

  def initialize text, link
    @tag = "a"
    @attributes = {href: link}
    @no_ekranize = true 
    super text 
  end
end


class List
  include BlockTag
  include ContainerTag

  def initialize text, ordered = true 
    @pre = [ListElement.new(text)]
    @tag = ordered ? "ol" : "ul"
    @dont_strip_pre = true
  end
  def opening_tag 
    super + "\n"
  end
end

class ListElement
  include BlockTag
  include PostFormattedTag

  def initialize text
    @tag = 'li'
    @indent = " " * 2
    super text
  end

  def +(other)
    other.put_before (@text + closing_tag)
    other
  end
  
  def put_before text
    @text = (text + opening_tag + @text)
  end
end

class Markdown
  include ContainerTag
  def initialize(text = nil)
    @tag = ''
    @pre = [NilTag.new]
  end
end

class Formatter
  def initialize text
    @text = text
    md = Markdown.new ''
     
    buf = NilTag.new
    text.lines.each { |line| md << parse_line(line) }
    buf += NilTag.new
    @formatted = md.inner_to_s.strip
  end

  def to_html
    @formatted
  end

  alias to_s to_html

  def inspect 
    @text
  end

  private 

  def parse_line line
    case line 
    when /^\ {4}(.*)$/                then Code.new $1
    when /^\s*([\#]{1,4})\s+(\S.*)$/  then Header.new($2, $1.size) 
    when /^>\s+(.*)$/                 then Quote.new $1
    when /^\ *$/                      then NilTag.new line
    when /^\d*\.\ (.*)$/              then List.new $1
    when /^\*\ (.*)$/                 then List.new $1, false
    else                              Paragraph.new line
    end
  end
end
