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
    return find_all_indexes(sub.first).select { |index| slice(index, sub.size) == sub }.size
    return 0 if sub.length > length
    buf = find_index(sub.first)
    return 0 if buf == nil
    [buf+1..-1].subarray_count(sub) + (self[buf, sub.length] == sub ? 1 : 0)
  end

  def find_all_indexes element
    result = []
    each_with_index { |item, index| result << index if item == element }
    result
  end

  def occurences_count
    result = Hash.new(0)
    each { |n| result[n] += 1 }
    result
  end
end
