# encoding: utf-8

require 'regtest/back/element'

class Regtest::Back::Result
  def initialize()
    @results = []
    @look_aheads = []
    @look_behinds = []
    @positional_anchors = {}
    @start_offset = 0
    @end_offset = 0
    @pre_match = nil
    @match = nil
    @post_match = nil
  end
  
  attr_reader :results, :positional_anchors, :end_offset, 
              :pre_match, :match, :post_match
  
  # get pre-match string
  
  # Adds elem
  def push_body(elem)
    @results.push elem
    @end_offset += 1
  end

  # Offset of an elem
  def [](offset)
    @results[offset]
  end

  # size of results
  def size
    @results.size
  end

  # Adds results of look_ahead
  def add_look_ahead(command, sub_results)
    @look_aheads.push({offset: @end_offset, cmd: command, results: sub_results})
  end

  # Adds results of look_behind
  def add_look_behind(command, sub_results)
    @look_behinds.push({offset: @end_offset, cmd: command, results: sub_results})
  end

  # Adds offset of anchor
  def add_anchor(cmd)
    @positional_anchors[cmd] ||= []
    @positional_anchors[cmd].push @end_offset
  end

  # Merge results of look aheads / behinds
  def merge
    merge_look_ahead && 
    merge_look_behind
  end

  # Merge results of look aheads
  def merge_look_ahead
    @look_aheads.each do | elem |
      offset = elem[:offset]
      sub_results = elem[:results]
      command = elem[:cmd]
      
      merge_anchors(offset, sub_results)
      case command
      when :CMD_LOOK_AHEAD
        if !merge_look_ahead_elems(offset, sub_results)
          return nil
        end
      when :CMD_NOT_LOOK_AHEAD
        if !merge_not_look_ahead_elems(offset, sub_results)
          return nil
        end
      else
        raise "invalid command at merge_look_ahead: #{command}"
      end
    end
    true
  end
  
  # Merge each elements of look aheads
  def merge_look_ahead_elems(offset, sub_results)
    term_offset = offset + sub_results.end_offset
    
    # intersect elems
    offset.step(term_offset-1) do | i |
      sub_elem = sub_results[i-offset]
      
      if i < @end_offset
        if(!@results[i].intersect(sub_elem))
          return nil
        end
      else
        @results.push(sub_elem)
      end
    end
    true
  end

  # Merge each elements of not-look-aheads
  def merge_not_look_ahead_elems(offset, sub_results)
    term_offset = offset + sub_results.end_offset
    try_order = sub_results.size.times.to_a.shuffle
    
    found = false
    # exclude, at least, one element
    try_order.each do | j |
      results_work = @results.dup
      cur_offset = offset + j
    
      offset.step(term_offset-1).each do | i |
        sub_elem = sub_results[i-offset]
        
        if i < @end_offset
          if i == cur_offset
            if(!results_work[i].exclude(sub_elem))
              next
            else
              found = true
            end
          else
            # do nothing
          end
        else
          if i == cur_offset
            if(reverse_work = sub_elem.reverse)
              results_work.push reverse_work
              found = true
            else
              results_work.push(Regtest::Back::Element.any_char)
            end
          else
            results_work.push(Regtest::Back::Element.any_char)
          end
        end
      end
      if found
        @results = results_work
        break
      end
    end
    found
  end

  # Merge results of look behind
  def merge_look_behind
    @look_behinds.each do | elem |
      offset = elem[:offset]
      sub_results = elem[:results]
      command = elem[:cmd]
      
      merge_anchors(offset, sub_results)
      case command
      when :CMD_LOOK_BEHIND
        if !merge_look_behind_elems(offset, sub_results)
          return nil
        end
      when :CMD_NOT_LOOK_BEHIND
        if !merge_not_look_behind_elems(offset, sub_results)
          return nil
        end
      else
        raise "invalid command at merge_look_behind: #{command}"
      end
    end
    true
  end
  
  # Merge each elements of look behinds
  def merge_look_behind_elems(offset, sub_results)
    unshift_length = sub_results.end_offset - offset
    if unshift_length > 0
      # @results = sub_results[0..(unshift_length-1)] + @results
      if !unshift_params(unshift_length)
        return false
      end
    end

    # intersect elems
    results_offset = (unshift_length > 0)?0:(offset-sub_results.end_offset)
    pre_part = []
    0.step(sub_results.end_offset-1) do | i |
      sub_elem = sub_results[i]
      if i < unshift_length
        pre_part.push sub_elem
      else
        if(!@results[i-unshift_length].intersect(sub_elem))
          return nil
        end
      end
    end
    @results = pre_part + @results
    true
  end

  # Merge each elements of not look behinds
  def merge_not_look_behind_elems(offset, sub_results)
    unshift_length = sub_results.end_offset - offset
    if unshift_length > 0
      if !unshift_params(unshift_length)
        return false
      end
    end
    
    try_order = sub_results.size.times.to_a.shuffle
    found = false
    # exclude, at least, one element
    try_order.each do | j |
      results_work = @results.dup

      # intersect elems
      results_offset = (unshift_length > 0)?0:(offset-sub_results.end_offset)
      0.step(sub_results.end_offset-1) do | i |
        sub_elem = sub_results[i]
        
        if i < unshift_length
          if i == j
            results_work.unshift (sub_elem.reverse)
            found = true
          else
            results_work.unshift (Regtest::Back::Element.any_char)
          end
        else
          if i == j
            if(!results_work[results_offset+i].exclude(sub_elem))
              next
            else
              found = true
            end
          else
            # do nothing
          end
        end
      end
      if found
        @results = results_work
        break
      end
    end
    found
  end

  # Merge anchors
  def merge_anchors(offset, sub_results)
    sub_results.positional_anchors.each do | key, value |
      @positional_anchors[key] ||= []
      @positional_anchors[key] |= value.map{|elem| elem + offset}
    end
  end
  
  # unshift parameters
  def unshift_params(unshift_length)
    @look_aheads.each{|elem| elem[:offset] += unshift_length}
    @look_behinds.each{|elem| elem[:offset] += unshift_length}
    @positional_anchors.each do | cmd, offsets |
      return false if(cmd == :CMD_ANC_STRING_BEGIN)
      offsets.map!{| offset | offset += unshift_length}
    end
    @start_offset += unshift_length
    @end_offset += unshift_length
    true
  end
  
  # narrow down nominates by anchors
  def narrow_down
    @positional_anchors.each do | cmd, offsets |
      case cmd
      when :CMD_ANC_STRING_BEGIN, :CMD_ANC_MATCH_START
        return false if offsets.max > 0
      when :CMD_ANC_STRING_END
        return false if offsets.min < (@results.size() - 1)
      when :CMD_ANC_STRING_END2
        min_offset = offsets.min
        if min_offset < (@results.size() -1)
          return false
        elsif min_offset == (@results.size() -1)
          if @results[min_offset].new_line?
            @results[min_offset].set_new_line
          else
            return false
          end
        end
      when :CMD_ANC_LINE_BEGIN
        offsets.each do | offset |
          if offset == 0
              # ok
          elsif @results[offset-1].new_line?
            @results[offset-1].set_new_line
          else
            return false
          end
        end
      when :CMD_ANC_LINE_END
        offsets.each do | offset |
          if offset == @results.size
              # ok
          elsif @results[offset].new_line?
            @results[offset].set_new_line
          else
            return false
          end
        end
      when :CMD_ANC_WORD_BOUND
        offsets.uniq.size.times do | i |
          offset = offsets[i]
          # puts "before offset:#{offset} #{@results}"
          if offset > 0 && offset < @results.size
            if !bound_process(@results[offset-1], @results[offset])
              return false
            end
          elsif @results.size == 0
            @results.push (Regtest::Back::Element.any_char)
            @results.push (Regtest::Back::Element.any_char)
            bound_process(@results[0], @results[1])
          elsif offset == @results.size
            @results.push (Regtest::Back::Element.any_char)
            if !bound_process(@results[-2], @results[-1])
              return false
            end
          elsif offset == 0
            if !unshift_params(1)
              return false
            end
            @results.unshift (Regtest::Back::Element.any_char)
            if !bound_process(@results[0], @results[1])
              return false
            end
          end
        end
      when :CMD_ANC_WORD_UNBOUND
        offsets.uniq.size.times do | i |
          offset = offsets[i]
          # puts "before offset:#{offset} #{@results}"
          if offset > 0 && offset < @results.size
            if !unbound_process(@results[offset-1], @results[offset])
              return false
            end
          elsif @results.size == 0
            @results.push (Regtest::Back::Element.any_char)
            @results.push (Regtest::Back::Element.any_char)
            unbound_process(@results[0], @results[1])
          elsif offset == @results.size
            @results.push (Regtest::Back::Element.any_char)
            if !unbound_process(@results[-2], @results[-1])
              return false
            end
          elsif offset == 0
            if !unshift_params(1)
              return false
            end
            @results.unshift (Regtest::Back::Element.any_char)
            if !unbound_process(@results[0], @results[1])
              return false
            end
          end
        end
      else
        raise "command (#{cmd}) not implemented"
      end
    end
    return true
  end

  # bound process (\b)
  def bound_process(elem1, elem2)
    if    elem1.word_elements?
      elem2.set_non_word_elements
    elsif elem1.non_word_elements?
      elem2.set_word_elements
    elsif elem2.word_elements?
      elem1.set_non_word_elements
    elsif elem2.non_word_elements?
      elem1.set_word_elements
    else
      if(rand(2)==0)
        elem1.set_word_elements
        elem2.set_non_word_elements
      else
        elem1.set_non_word_elements
        elem2.set_word_elements
      end
    end
    if elem1.empty? || elem2.empty?
      return false
    end
    true
  end

  # unbound process (\B)
  def unbound_process(elem1, elem2)
    if    elem1.word_elements?
      elem2.set_word_elements
    elsif elem1.non_word_elements?
      elem2.set_non_word_elements
    elsif elem2.word_elements?
      elem1.set_word_elements
    elsif elem2.non_word_elements?
      elem1.set_non_word_elements
    else
      if(rand(2)==0)
        elem1.set_word_elements
        elem2.set_word_elements
      else
        elem1.set_non_word_elements
        elem2.set_non_word_elements
      end
    end
    if elem1.empty? || elem2.empty?
      return false
    end
    true
  end

  # Fixes results
  def fix
    @pre_match  = fix_part(0, @start_offset-1)
    @match      = fix_part(@start_offset, @end_offset-1)
    @post_match = fix_part(@end_offset, @results.size-1)
    
    @pre_match + @match + @post_match
  end
  
  # Fixes part of results
  def fix_part(start_offset, end_offset)
    result = ""
    start_offset.step(end_offset).each do | i |
      result += @results[i].random_fix
    end
    result
  end

end

# Test suite (execute when this file is specified in command line)
if __FILE__ == $0
end


