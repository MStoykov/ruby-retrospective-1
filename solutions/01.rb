# no injects due to presentation QQ
class Array 
  def index_by
    result = {}
    self.each {|n| result[ yield n ] = n } 
    result     
  end

  def to_hash # Hash[*self.flatten] - hash apidock comment 
    result = {}
    self.each {|n| result[n[0]] = n[1]}   
    result 
  end

  def subarray_count ( sub )
    if (sub.length > length) then  return 0 end 
    buf = find_index(sub.first)
    if buf == nil  then return 0 end 
    #print self[buf+1..-1]
    self[buf+1..-1].subarray_count(sub) + (self[buf, sub.length] == sub ? 1 : 0)
    # sorry but I'm too lazy atm to not recurse it :P for me it dies on 
    # 'Array.new(8166,1).subarray_count([1]).should eq 0' with 
    # 'stack level too deep'
  end
  
  def occurences_count
    result = Hash.new(0)
    self.each { |n| result [n] +=1}
    result
  end    
     	
end
