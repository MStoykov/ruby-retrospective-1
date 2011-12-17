# encoding: utf-8

describe GameOfLife::Board do
  describe 'initialization' do
    it 'accepts multiple coords in the constructor' do
      board = new_board [0, 0], [1, 1], [2, 2]
    end
  end

  describe 'corner cases' do
    it 'behaves correctly when no cells are given' do
      board = new_board

      board.count.should be_zero
      board.next_generation.count.should be_zero
    end

    it 'behaves correctly when the given cells are repeated' do
      board = new_board [1, 2], [1, 2], [1, 3], [1, 3]
      board.count.should eq 2
    end

    it 'copes with very large coordinates' do
      board = new_board([1000000000000000000000, 1000000000000000000000],
                        [1000000000000000000001, 1000000000000000000000],
                        [1000000000000000000000, 1000000000000000000001])
      board.count.should eq 3
      board.next_generation.count.should eq 4
    end
  end

  describe 'Enumerable interface' do
    it 'navigates through cells' do
      board = new_board [1, 1], [1, 2], [1, 3]

      board.first.should =~ [1, 1]
      board.reverse_each.first.should =~ [1, 3]
    end
  end

  describe 'enumeration' do
    it 'yields coordinates of live cells' do
      cells = [0, 1], [2, 3], [5, 5]

      new_board(*cells).each do |x, y|
        cells.should include([x, y])
        cells.delete [x, y]
      end

      cells.should be_empty
    end

    describe 'live cells count' do
      it 'returns the number of live cells on a board' do
        new_board([0, 0]).count.should eq 1
        new_board([0, 0], [1, 1]).count.should eq 2
      end
    end
  end

  describe 'indexing' do
    it 'works for live and dead cells' do
      board = new_board([1, 2])

      board[1, 2].should be_true
      board[2, 2].should be_false
    end
  end

  describe 'evolution' do
    describe 'rules' do
      it 'kills cells in underpopulated areas' do
        board = new_board [1, 1]
        board[1, 1].should be_true
        board.count.should eq 1

        next_gen = board.next_generation

        next_gen.count.should eq 0
        next_gen[1, 1].should be_false
      end

      it 'preserves stable cells' do
        board = new_board [0, 1], [1, 1], [2, 1], [1, 2]

        next_gen = board.next_generation

        next_gen[1, 1].should be_true
      end

      it 'kills cells in overpopulated areas' do
        board = new_board [0, 1], [1, 1], [2, 1], [1, 2], [1, 0]

        next_gen = board.next_generation

        next_gen[1, 1].should be_false
      end

      it 'sprouts new life when appropriate' do
        board = new_board [0, 1], [1, 1], [2, 1]
        board[1, 0].should be_false
        board.count.should eq 3

        next_gen = board.next_generation

        next_gen[1, 0].should be_true
        next_gen[1, 2].should be_true
      end
    end

    it 'does not mutate the old board when making next generation' do
      board = new_board [0, 1], [1, 1], [2, 1]
      board.next_generation
      board.to_a.should =~ [[0, 1], [1, 1], [2, 1]]
    end

    describe 'stills' do
      it 'realizes a block' do
        block = [[0, 0], [1, 0], [0, 1], [1, 1]]
        board = new_board *block
        board.next_generation.to_a.should =~ block
      end

      it 'realizes a boat' do
        boat = [[0, 0], [1, 0], [0, 1], [2, 1], [1, 2]]
        board = new_board *boat
        board.next_generation.to_a.should =~ boat
      end
    end

    describe 'oscillators' do
      it 'realizes a blinker' do
        board = new_board [-1, 0], [0, 0], [1, 0]
        next_gen = board.next_generation
        next_gen.to_a.should =~ [[0, -1], [0, 0], [0, 1]]
        next_gen.next_generation.to_a.should =~ board.to_a
      end

      it 'realizes a beacon' do
        board = new_board [1, 1], [1, 2], [2, 1], [2, 2], [3, 3], [3, 4], [4, 3], [4, 4]
        next_gen = board.next_generation
        next_gen.to_a.should =~ [[1, 1], [1, 2], [2, 1], [3, 4], [4, 3], [4, 4]]
        next_gen.next_generation.to_a.should =~ board.to_a
      end
    end

    describe 'spaceships' do
      it 'realizes a glider' do
        board = new_board [0, 0], [1, 1], [1, 2], [0, 2], [-1, 2]
        next_gen = board.next_generation
        next_gen.to_a.should =~ [[-1, 1], [1, 1], [1, 2], [0, 2], [0, 3]]
        next_gen.next_generation.to_a.should =~ [[1, 1], [1, 2], [1, 3], [0, 3], [-1, 2]]
      end
    end
  end

  def new_board(*args)
    GameOfLife::Board.new *args
  end

  def expect_generation_in(board, *cells)
    board.count.should eq cells.count
    (board.to_a - cells).should eq []
  end
end
