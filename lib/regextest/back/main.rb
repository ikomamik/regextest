# encoding: utf-8

# Copyright (C) 2016 Mikio Ikoma

require 'regextest/common'
require 'regextest/back/element'
require 'regextest/back/result'

# Main class of back-end. Construct candidates array and narrow down
class Regextest::Back::Main
  include Regextest::Common
  def initialize(json_obj, max_nest)
    @json_obj = json_obj
    @max_nest = max_nest
    @parens_hash = {}  # hash to keep string generated by parentheses
    @nest = 0          # current nest of back-reference
    @quit_mode = false # flag for preventing from increase of nest
                       # if true, \g<foo> is restrained if possible
  end
  
  def generate
    # seek parentheses because there are references defined ahead
    seek_parens(@json_obj)
    
    # generate pre-result of matched string (pre-result contains candidates of letters)
    pre_result = generate_candidates({json: @json_obj})
    return nil unless pre_result
    TstLog("pre_result1:\n" + pre_result.inspect)
    
    # narrow down the candidates
    result = narrow_down_candidates(pre_result)
    TstLog("pre_result2:\n" + result.inspect)
    return nil if !result || !result.narrow_down
    
    # fixes result
    result.fix
    
    result
  end
  
  # seek parentheses
  def seek_parens(target)
    if(target["type"] == "LEX_PAREN")
      @parens_hash[target["refer_name"]] = {:target => target}
    end
    if(target["value"])
      if( Array === target["value"])
        target["value"].each{|child| seek_parens(child)}
      else
        seek_parens(target["value"])
      end
    end
  end
  
  # generate pre-result of matched string (pre-result contains candidates of letters)
  def generate_candidates(param)
    target = param[:json]
    # puts "MATCH type:#{target["type"]}"
    
    result = nil
    case target["type"]
    when "LEX_SEQ"  # sequence of letters or parentheses
      result = generate_candidates_seq(param)
    when "LEX_SELECT"
      result = generate_candidates_select(param)
    when "LEX_PAREN"
      result = generate_candidates_paren(param)
    when "LEX_CHAR_CLASS"
      result = generate_candidates_char_class(param)
    when "LEX_BRACKET", "LEX_SIMPLIFIED_CLASS", "LEX_ANY_LETTER", "LEX_POSIX_CHAR_CLASS", "LEX_UNICODE_CLASS"
      result = generate_candidates({json: target["value"]})
    when "LEX_REPEAT"
      result = generate_candidates_repeat(param)
    when "LEX_RANGE"
      result = generate_candidates_range(param)
    when "LEX_BACK_REFER", "LEX_NAMED_REFER"
      result = generate_candidates_back_refer(param)
    when "LEX_NAMED_GENERATE"
      result = generate_candidates_named_generate(param)
    when "LEX_CHAR"
      result = generate_candidates_char(param)
    when "LEX_ANC_LINE_BEGIN"
      result = Regextest::Back::Element.new({cmd: :CMD_ANC_LINE_BEGIN})
    when "LEX_ANC_LINE_END"
      result = Regextest::Back::Element.new({cmd: :CMD_ANC_LINE_END})
    when "LEX_ANC_WORD_BOUND"
      result = Regextest::Back::Element.new({cmd: :CMD_ANC_WORD_BOUND})
    when "LEX_ANC_WORD_UNBOUND"
      result = Regextest::Back::Element.new({cmd: :CMD_ANC_WORD_UNBOUND})
    when "LEX_ANC_STRING_BEGIN"
      result = Regextest::Back::Element.new({cmd: :CMD_ANC_STRING_BEGIN})
    when "LEX_ANC_STRING_END"
      result = Regextest::Back::Element.new({cmd: :CMD_ANC_STRING_END})
    when "LEX_ANC_STRING_END2"
      result = Regextest::Back::Element.new({cmd: :CMD_ANC_STRING_END2})
    when "LEX_ANC_MATCH_START"
      result = Regextest::Back::Element.new({cmd: :CMD_ANC_MATCH_START})
    when "LEX_ANC_LOOK_BEHIND2"
      result = Regextest::Back::Element.new({cmd: :CMD_ANC_LOOK_BEHIND2})
    when "LEX_OPTION_PAREN"     # options are processed at front-end
      result = []
    when "LEX_EMPTY"
      result = []
    else
      raise "#{target["type"]} not implemented (from generate_candidates routine)"
    end
    result
  end
  
  # sequence of letters or parentheses
  def generate_candidates_seq(param)
    target = param[:json]
    results = []
    target["value"].each do |elem|
      generated_string = generate_candidates({json: elem})
      if(Array === generated_string)
        generated_string.flatten!(1)
        results += generated_string
      else
        results.push generated_string
      end
    end
    # nil if one element failed
    if(results.index(nil))
      result = nil
    else
      # result = results.join("")
      result = results
    end
    result
  end
  
  # selection of sequence. such as (aa|b|c)
  def generate_candidates_select(param)
    target = param[:json]
    if param[:forced_select]
      # index is specified by condition 
      if target["value"][param[:forced_select]]
        result = generate_candidates({json: target["value"][param[:forced_select]]})
      else
        # regexp such as /^(?:b|(a))(?(1)1)$/ match "b"!
        result = []
      end
    else
      # success if there is at least one result
      offsets = (0 ... target["value"].size).to_a
      if !param[:atomic] && offsets.size > 1
        offsets = TstShuffle(offsets)  # shuffle if not atomic group (this proceduce is not sufficient...)
      end
      result = nil
      offsets.each do | offset |
        result = generate_candidates({json: target["value"][offset]})
        break if(result)
      end
    end
    result
  end
  
  # parenthesis
  def generate_candidates_paren(param)
    target = param[:json]
    # analyze options of the parenthesis
    paren_prefix = target["prefix"]
    # pp target["prefix"]
    if(paren_prefix == "<=")
      lb_result = generate_candidates({json: target["value"]})
      result = Regextest::Back::Element.new({cmd: :CMD_LOOK_BEHIND, result: lb_result})
    elsif(paren_prefix == "=")
      la_result = generate_candidates({json: target["value"]})
      result = Regextest::Back::Element.new({cmd: :CMD_LOOK_AHEAD, result: la_result})
    elsif(paren_prefix == "<!")
      lb_result = generate_candidates({json: target["value"]})
      result = Regextest::Back::Element.new({cmd: :CMD_NOT_LOOK_BEHIND, result: lb_result})
    elsif(paren_prefix == "!")
      la_result = generate_candidates({json: target["value"]})
      result = Regextest::Back::Element.new({cmd: :CMD_NOT_LOOK_AHEAD, result: la_result})
    elsif(paren_prefix == ">")   # atomic group
      generate_string = generate_candidates({json: target["value"], atomic: true})
      @parens_hash[target["refer_name"]][:generated] ||= []
      @parens_hash[target["refer_name"]][:generated][@nest] = generate_string
      result = generate_string
    elsif(paren_prefix == "")   # simple parenthesis
      generate_string = generate_candidates({json: target["value"]})
      @parens_hash[target["refer_name"]][:generated] ||= []
      @parens_hash[target["refer_name"]][:generated][@nest] = generate_string
      result = generate_string
    else
      # when condition is specified
      select_num = nil
      if(target["condition_name"] && target["condition_name"].length > 0)
        if @parens_hash[target["condition_name"]][:generated]
          select_num = 0
        else
          select_num = 1
        end
      end
      
      if(select_num == 1 && target["value"]["type"] != "LEX_SELECT")
        result = nil
      else
        generate_string = generate_candidates({json: target["value"], forced_select: select_num})
        
        @parens_hash[target["refer_name"]][:generated] ||= []
        @parens_hash[target["refer_name"]][:generated][@nest] = generate_string
        result = generate_string
      end
    end
    result
  end
  
  # char class
  def generate_candidates_char_class(param)
    target = param[:json]
    results = Regextest::Back::Element.new({cmd: :CMD_SELECT, data: []})
    target["value"].each do | elem |
      sub_results = generate_candidates({json: elem})
      results.union sub_results
    end
    if results.size > 0
      result = results
    else
      result = nil
    end
    result
  end
  
  # repeat
  def generate_candidates_repeat(param)
    target = param[:json]
    if(@quit_mode)
      repeat = target["min_repeat"]
    elsif(target["max_repeat"] > target["min_repeat"])
      repeat = target["min_repeat"]+TstRand(target["max_repeat"]-target["min_repeat"]+1)
    else
      repeat = target["min_repeat"]
    end
    result = []
    if target["reluctant"] == "yes"
      result.push Regextest::Back::Element.new({cmd: :CMD_ANC_RELUCTANT_BEGIN, id: target["id"]})
    end
    # puts "repeat=#{repeat} quit=#{@quit_mode} nest=#{@nest}"
    repeat.times do
      if( elem = generate_candidates({json: target["value"]}))
        result.push elem
      else
        result = nil
        break
      end
      
      # quit to repeat if the first element is begin anchor
      elem.flatten! if Array === elem  # flatten considering duplicated repeat
      if elem.size > 0 && elem[0].respond_to?(:command) && elem[-1].respond_to?(:command)
        break if elem[0].command == :CMD_ANC_LINE_BEGIN && !elem[-1].new_line?
        break if elem[0].command == :CMD_ANC_STRING_BEGIN
      end
    end
    if target["reluctant"] == "yes"
      result.push Regextest::Back::Element.new({cmd: :CMD_ANC_RELUCTANT_END, id: target["id"]})
    end
    result
  end
  
  # range
  def generate_candidates_range(param)
    target = param[:json]
    letter = []
    codepoints = (target["begin"]..target["end"]).to_a
    letter = codepoints.map{| codepoint | [codepoint].pack("U*")}   # to be faster
    result = Regextest::Back::Element.new({cmd: :CMD_SELECT, data: letter})
  end
  
  # back_refer
  def generate_candidates_back_refer(param)
    target = param[:json]
    if @parens_hash[target["refer_name"]][:generated]
      relative_num = (target["relative_num"]=="")?(-1):(@nest + target["relative_num"].to_i)
      result = @parens_hash[target["refer_name"]][:generated][relative_num]
    else
      result = nil
    end
    result
  end
  
  # named generate
  def generate_candidates_named_generate(param)
    target = param[:json]
    @quit_mode = true if(@nest >= @max_nest)
    if(@quit_mode)
      result = nil
    else
      @nest += 1
      if target["refer_name"] == "$$_0"     # recursively call whole expression
        result = generate_candidates({json: @json_obj})
      else
        result = generate_candidates({json: @parens_hash[target["refer_name"]][:target]})
      end
      @nest -= 1
    end
    result
  end
  
  # char
  def generate_candidates_char(param)
    target = param[:json]
    case target["value"]
    when String
      result = Regextest::Back::Element.new({cmd: :CMD_SELECT, data: [target["value"]]})
    else
      result = generate_candidates({json: target["value"]})
    end
    result
  end
  
  # narrow down candidates considering anchors
  def narrow_down_candidates(candidate_array)
    # pp candidate_array
    results = Regextest::Back::Result.new
    candidate_array.each do | elem |
      command = elem.command
      case command
      when :CMD_SELECT
        results.push_body elem
      when :CMD_LOOK_AHEAD, :CMD_NOT_LOOK_AHEAD
        if(sub_results = narrow_down_candidates(elem.param[:result]))
          results.add_look_ahead(command, sub_results)
        else
          return nil
        end
      when :CMD_LOOK_BEHIND, :CMD_NOT_LOOK_BEHIND
        if(sub_results = narrow_down_candidates(elem.param[:result]))
          results.add_look_behind(command, sub_results)
        else
          return nil
        end
      when :CMD_ANC_LINE_BEGIN, :CMD_ANC_LINE_END, :CMD_ANC_WORD_BOUND, :CMD_ANC_WORD_UNBOUND,
           :CMD_ANC_STRING_BEGIN, :CMD_ANC_STRING_END, :CMD_ANC_STRING_END2, :CMD_ANC_MATCH_START,
           :CMD_ANC_LOOK_BEHIND2
        results.add_anchor(command)
      when :CMD_ANC_RELUCTANT_BEGIN, :CMD_ANC_RELUCTANT_END
        results.add_reluctant_repeat(elem)
      else
        raise "inner error, invalid command at checking anchors: #{command}"
      end
    end
    if !results.merge
      return nil
    end
    results
  end
end

# Test suite (execute when this file is specified in command line)
if __FILE__ == $0

end

