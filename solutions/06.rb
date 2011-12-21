#TODO make it work for n
require 'set'

module GameOfLife
  class Board
    include Enumerable

    def initialize(*generation)
      @generation = Set.new generation
    end

    def next_generation
      hash_map = map_neighbors.select do |cell, neighbors|
        neighbors == 3 or ( neighbors == 2 and self[*cell] )
      end
      Board.new *hash_map.keys
    end

    def each &block
      if block_given?
        @generation.each block
      else
        @generation.each
      end
    end

    def [](x, y)
      @generation.include? [x, y]
    end

    def size
      @generation.size
    end

    private

    def neighbors_of(x, y)
      [ [x - 1, y + 1], [x    , y + 1], [x + 1, y + 1],
        [x - 1, y    ],                 [x + 1, y    ],
        [x - 1, y - 1], [x    , y - 1], [x + 1, y - 1]]
    end

    def map_neighbors
      hash = Hash.new 0
      each do |cell|
        neighbors_of(*cell).each { |neighbor| hash[neighbor] += 1 }
      end
      hash
    end
  end
end
