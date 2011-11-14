class Collection 
  def initialize(songs, additional_tags)
    @collection = songs.lines.map { |line| Song.new *parse_line(line) }
    additional_tags.each do |artist, tags|
      find(artist: artist).each { |song| song.tags += tags }
    end
  end

  def find(criteria)
    fields = [:name,:artist,:genre,:subgenre].select { |field| criteria[field] }
    filters = fields.map { |field| field_filter(field, criteria[field]) }
    filters.concat tags_filters(*criteria[:tags]) if criteria[:tags] 
    filters << criteria[:filter] if criteria[:filter]
    filter = ->(song) { filters.all? { |filter| filter.call song }}
    @collection.select { |song| filter.call song }
  end

  private 
  def field_filter(field, value)
    ->(song) { song.send(field) == value } 
  end

  def tags_filters(*tags)
    tags.map { |tag| tag_filter tag }
  end

  def tag_filter(tag)
    tag, exclude = tag.chop, true if tag.end_with? '!'
    ->(song) { song.tags.include?(tag) ^ exclude }
  end

  def parse_line(line)
    args = line.split(".")
    result = args[0..1].map(&:strip)
    result[2..3] = args[2].split(',').map(&:strip)
    result[4] = args[3].split(',').map(&:strip) if args[3]
    result
  end
end

class Song
  attr_accessor :name, :artist, :genre, :subgenre, :tags

  def initialize(name, artist, genre, subgenre = nil, tags = [])
    @name, @artist, @genre, @subgenre = name, artist, genre, subgenre
    @tags = tags
    @tags << @genre.downcase
    @tags << @subgenre.downcase if @subgenre
  end
end
