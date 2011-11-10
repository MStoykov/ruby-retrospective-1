class Array 
  def index_by
    result = {}
    each { |n| result[yield n] = n } 
    result 
  end

  def to_hash
    result = {}
    each { |n| result[n[0]] = n[1] } 
    result 
  end

  def subarray_count sub
    indexes = []
    each_with_index { |item, index| indexes << index if item === sub.first }
    indexes.select { |index| slice(index, sub.size) === sub }.size
  end

  def occurences_count
    result = Hash.new(0)
    each { |n| result[n] += 1 }
    result
  end
end
