# encoding: utf-8

# A class for managing parentheses
class Regextest::Front::ManageParentheses
  def initialize()
    @paren_hash = {}
    @paren_array = []
  end
  
  # register a parenthesis
  def add(paren)
    # register capturable parentheses
    if(paren.prefix.length == 0 ||    # capture without prefix or
       (paren.prefix[-1] != ':' &&    # other than (?: or (?i: or (?imx), etc.
        !paren.prefix.match(/^([imx]*(?:\-[imx]+)?)$/) &&
        !paren.prefix.match(/^[\=\!\>]|\<[\=\!]/)
       )
      ) 
      @paren_array.push paren
    end
    
    # if name (ie. (?<foo>... ), register the name
    if(paren.name)
      @paren_hash[paren.name] = paren
    end
    paren
  end
  
  # sort of parentheses (since number of parenthesis not analyze order but offset order)
  def sort
    # pp @paren_array.map{|paren| paren.offset}
    @paren_array.sort{|x, y| x.offset <=> y.offset}.each_with_index do | paren, i |
      # puts "$$_#{i+1}  offset:#{paren.offset}"
      refer_name = "$$_#{i+1}"
      @paren_hash[refer_name] = paren    # parenthesis number from 1
      paren.set_refer_name(refer_name)
    end
  end
  
  # search target parenthesis
  def get_paren(get_id, offset = nil)
    if !offset
      if(Integer === get_id)
        @paren_hash["$$_#{get_id}"]
      else
        @paren_hash[get_id]
      end
    else
      # puts "offset = #{offset}, id = #{get_id}"
      target_id = @paren_array.size + 1
      @paren_array.each_with_index do | paren, i |
        # puts paren.offset
        if paren.offset > offset
          target_id = i + 1  # paren is started from 1
          break
        end
      end
      relative_offset = get_id.to_i
      if relative_offset < 0
        target_id += get_id.to_i
      else
        target_id += get_id.to_i - 1
      end
      @paren_hash["$$_#{target_id}"]
    end
  end
end

# Test suite (execute when this file is specified in command line)
if __FILE__ == $0 
end

