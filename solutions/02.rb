class Collection 
  def initialize songs, additional_tags 
    @collection = songs.lines.map { |line| Song.new *line.split(".") }
    additional_tags.each do |artist, tags|
      find(artist: artist).each { |song| song.tags += tags }
    end
  end

  def find criteria 
    filters = []
    fields = [:name,:artist,:genre,:subgenre].select { |field| criteria[field] }
    filters += fields.map { |field| field_filter field, criteria[field] }
    filters += tags_filters(*criteria[:tags]) if criteria[:tags] 
    filters << criteria[:filter] if criteria[:filter]
    filter = ->(song) { filters.all? { |filter| filter.call song }}
    @collection.select { |song| filter.call song }
  end

private 
  def field_filter field, value 
    ->(song) { song.send(field) == value } 
  end

  def tags_filters *tags 
    tags.map { |tag| tag_filter tag }
  end

  def tag_filter tag 
    tag, exclude = tag.chop, true if tag.end_with? '!' 
    ->(song) { song.tags.include?(tag) ^ exclude } 
  end
end

class Song
  attr_accessor :name, :artist, :genre, :subgenre, :tags

  def initialize name, artist, genres, tags = "" 
    @name,@artist = name.strip, artist.strip
    @genre,@subgenre = genres.split(",").map { |genre| genre.strip }
    @tags = tags.split( ",").map { |tag| tag.strip.downcase } 
    @tags << @genre.downcase
    @tags << @subgenre.downcase if @subgenre 
  end
end
