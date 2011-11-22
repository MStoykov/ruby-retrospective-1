class Formatter
  def initialize text
    @text = text
    @formatted = ([NilTag.new('')].concat @text.lines.map {|line| parse_line line}<<NilTag.new('')).inject(:+).text.strip
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
    when /^([\#]{1,4})\s+(\S.*)$/    then Header.new($2, $1.size) 
    when /^\ {4}(.*)$/            then Code.new $1
    when /^\ *$/                  then NilTag.new line
    else                    Paragraph.new line
    end
  end

  module Block # basic things for block type elements
    attr_reader :text

    def initialize text
      @text = ekranize text
    end

    def +(other)
      if other.instance_of? self.class
        @text << other.text
         
        self
      else
        @text << closing_tag
        other.put_before @text

        other
      end
    end

    SPECIAL_SYMBOLS = {'&' => '&amp;', '<' => '&lt;', '>' => '&gt;', '"' => '&quot;'}
    def ekranize text# TODO find out what the actual term is 
      result = text.clone
      SPECIAL_SYMBOLS.each { |key, value| result.gsub!(key.to_s, value) } 
      result
    end

    def opening_tag
      '<' + @tag + '>'
    end

    def closing_tag
      '</' + @tag + ">\n"
    end

    def put_before text
      @text = (text + opening_tag + @text)
    end
  end

  class Paragraph 
    include Block
    def initialize text
      super text.strip
      @tag = 'p'
    end
  end

  class NilTag
    include Block
    def initialize text
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
    include Block
    def initialize text, size
      super text.strip
      @tag = "h" + size.to_s
    end
  end

  class Code
    include Block
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

    def +(other)
      return super other unless other.instance_of? Code 
      @text << "\n" << other.text
      self
    end
  end
end
