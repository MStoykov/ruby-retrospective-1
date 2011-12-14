module GameOfLife
  class Board 
    include Enumerable
   
     
    def initialize(*generation)
      @generation  = generation
    end


    def next_generation 
      new_generation = @generation.select { |cell| lives(*cell) } 
      @generation.map { |cell| new_generation.concat sprout(*cell)}
      Board.new *new_generation.uniq
    end

    def count
      @generation.size
    end

    def each &block
      @generation.each { |cell| block.call cell }
    end

    def [](x,y)
      any? { |cell| cell == [x, y] }
    end
  
    def neighbors(x, y)
      possible_neighbors(x, y).select { |neighbor| self[*neighbor] }
    end

    private 
    def possible_neighbors (x, y)
      [ [x - 1, y + 1], [x    , y + 1], [x + 1, y + 1],
        [x - 1, y    ],                 [x + 1, y    ],
        [x - 1, y - 1], [x    , y - 1], [x + 1, y - 1]]      
    end

    def lives(x, y)
      n = neighbors(x, y).count 
      n >= 2 and n <= 3
    end

    def sprout(x, y)
      possible_new = possible_neighbors(x, y) - neighbors(x, y)
      possible_new.select { |cell| neighbors(*cell).count == 3 }
    end
      
  end
end
