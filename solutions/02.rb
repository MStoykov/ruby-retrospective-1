class Collection 
  def initialize songs, additional_tags 
    @collection = songs.lines.map{ |line| Song.new *line.split(".") }
    additional_tags.each do |artist, tags|
      find(artist: artist).each { |song| song.tags += tags }
    end
  end
  
  def find criterias 
    filters = []
    fields = [:name,:artist,:genre,:subgenre].select{ |field| criterias[field] }
    filters += fields.map{ |field| field_filter field, criterias[field] }
    filters += tags_filters(*criterias[:tags]) if criterias[:tags] 
    filters << criterias[:filter] if criterias[:filter]
    filter = ->(song) { filters.all? { |filter| filter.call song }}
    @collection.select{ |song| filter.call song }
  end
  
  private 
  
  def field_filter field, value 
    ->(song) { song.send(field) == value } 
  end

  def tags_filters *tags 
    tags.map { |tag| tag_filter tag}
  end
  
  def tag_filter tag 
    tag, exclude = tag[0..-2], true if tag.end_with? '!' 
    ->(song) { song.tags.include?(tag) ^ exclude } 
  end
end

class Song
  attr_accessor :name, :artist, :genre, :subgenre, :tags
  
  def initialize name, artist, genres, tags = "" 
    @name,@artist = name.strip, artist.strip
    @genre,@subgenre = genres.split(",").map{ |genre| genre.strip }
    @tags = tags.split( ",").map{ |tag| tag.strip.downcase } 
    @tags << @genre.downcase
    @tags << @subgenre.downcase if @subgenre 
  end
end
From mstoikov Sun Nov  6 18:27:31 2011
Date: Sun, 06 Nov 2011 18:27:31 +0200
To: -a, say@lt.home.say
Subject: Ruby 
User-Agent: Heirloom mailx 12.5 7/5/10
MIME-Version: 1.0
Content-Type: text/plain; charset=utf-8
Content-Transfer-Encoding: 8bit

задача(кратка и неясна версия): напишете колекция от песни която чете от входа в даден формат и после може да се търсят на база някакви критерии (съжалявам за правописно/смислените грешки :P)

