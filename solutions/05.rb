# https://github.com/MStoykov/ruby-retrospective-1/blob/master/solutions/05.rb
# it's half way done
class Formatter
  def initialize text
    @text = text
    buf = NilTag.new
    text.lines.each { |line| buf += parse_line(line) }
    @formatted = (buf + NilTag.new).text.strip
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
    when /^\ {4}(.*)$/            then Code.new $1
    when /^\s*([\#]{1,4})\s+(\S.*)$/ then Header.new($2, $1.size) 
    when /^>\s+(.*)$/             then Quote.new $1
    when /^\ *$/                  then NilTag.new line
    when /^\d*\.\ (.*)$/          then List.new $1
    when /^\*\ (.*)$/             then List.new $1, false
    else                          Paragraph.new line
    end
  end

  module Tag
    attr_reader :text

    def initialize text
      @text = text
    end
 
    SPECIAL_SYMBOLS = {'&' => '&amp;', '<' => '&lt;', '>' => '&gt;', '"' => '&quot;'}
    def ekranize# TODO find out what the actual term is 
      SPECIAL_SYMBOLS.each { |key, value| @text.gsub!(key.to_s, value) } 
    end

    def opening_tag
      '<' + @tag + attributes_string + '>'
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
      ekranize
    end

    def +(other)
      if other.instance_of? self.class
        @text << "\n" << other.text
 
        self
      else
        @text << closing_tag
        other.put_before @text

        other
      end
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

#TODO: rewrite to do it in order 
    def format_inline # Smells to me 
      @text.gsub!(/\[(.*?)\]\((.*?)\)/) { |s| Link.new($1, $2).to_s }
      @text.gsub!(/\*\*([^<]*?)\*\*/) {|s| Strong.new($1).to_s }
      @text.gsub!(/_([^<]*?)_/) {|s| Emphasize.new($1).to_s }
    end
  end

  module ContainerTag # has to be code, quote and lists 
    include Tag

    def initialize text 
      super text 
    end

    def +(other)
      return super other if other.instance_of? self.class
      
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

    def initialize text 
      if /^\s*$/ === text # SMELLLS
        @pre = NilTag.new("\n")
      else
        @pre = Paragraph.new(text)
      end
      @tag = "blockquote"
    end

    def +(other)
      if other.instance_of? self.class 
        @pre += other.pre

        self
      else
#       p "| " + @pre.text + " |"
        @text << (@pre + NilTag.new('')).text.strip
        super other
      end
    end


    def put_before text
      @text = (NilTag.new('')).text + "<p>"
      super text
    end
  end

  class Strong
    include InlineTag
    include PostFormattedTag

    def initialize text
      super text
      @tag = "strong"
    end
  end

  class Link
    include InlineTag
    include PostFormattedTag

    def initialize text, link
      super text 
      @tag = 'a'
      @attributes = {href: link}
    end
  end

  class Emphasize
    include InlineTag
    include PostFormattedTag

    def initialize text
      super text
      @tag = 'em'
    end
  end

  class List
    include BlockTag
    include PostFormattedTag

    def initialize text, ordered = true 
      @indent = "  "
      @text = @indent + (ListElement.new text).to_s
      @tag = ordered ? "ol" : "ul"
    end

    def +(other)
      return super other unless other.instance_of? self.class
      @text << other.text

      self
    end

    def opening_tag
      super + "\n"
    end
  end

  class ListElement
    include BlockTag
    include PostFormattedTag

    def initialize text
      super text
      @tag = 'li'
    end
  end
end
