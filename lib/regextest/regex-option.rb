# encoding: utf-8

# A class that manages options of regular expression
class Regextest::RegexOption
  # Constants for the class
  TstRegOptDefault  =  1
  TstRegOptAscii    =  2
  TstRegOptUnicode  =  3

  attr_accessor :reg_options, :char_set
  
  def initialize(options = nil)
    self.set(options)
    @char_set = TstRegOptDefault
  end
  
  # a method for copy (maybe unnecessary)
  def initialize_copy(source_obj)
    @reg_options = source_obj.reg_options
    @char_set = source_obj.char_set
  end
    
  # set one or more options
  def set(options)
    @reg_options = 0
    modify(options)
  end
    
  # modify one or more options
  def modify(options)
    case options
    when String
      modify_string(options)
    when Integer
      modify_integer(options)
    end
  end
    
  # modify regoption by string (like 'x-im')
  def modify_string(opt_string)
    opts = opt_string.split("-")
    raise "Option string (#{opt_string}) is invalid." if(opts.size > 2)
    
    # set option bits
    if(opts[0])
      opts[0].split(//).each do | opt |
        case opt
        when 'i'
          @reg_options |= Regexp::IGNORECASE
        when 'x'
          @reg_options |= Regexp::EXTENDED
        when 'm'
          @reg_options |= Regexp::MULTILINE
        when 'd'
          @char_set = TstRegOptDefault
        when 'u'
          @char_set = TstRegOptUnicode
        when 'a'
          @char_set = TstRegOptAscii
        else
          raise "Invalid char (#{opt}) found in regexp option"
        end
      end
    end
    
    # reset option bits
    if(opts[1])
      opts[1].split(//).each do | opt |
        case opt
        when 'i'
          @reg_options &= ~Regexp::IGNORECASE
        when 'x'
          @reg_options &= ~Regexp::EXTENDED
        when 'm'
          @reg_options &= ~Regexp::MULTILINE
        else
          raise "Invalid char (#{opt}) found in regexp option"
        end
      end
    end
    @reg_options
  end

  # modify options by integer
  def modify_integer(options)
    @reg_options |= options
  end
      

  # methods for checking each flag
  def is_ignore?
    (@reg_options & Regexp::IGNORECASE != 0)
  end
  
  def is_extended?
    (@reg_options & Regexp::EXTENDED != 0)
  end
  
  def is_multiline?
    (@reg_options & Regexp::MULTILINE != 0)
  end
  
  def is_default_char_set?
    (@char_set == TstRegOptDefault)
  end
  
  def is_ascii?
    (@char_set == TstRegOptAscii)
  end
  
  def is_unicode?
    (@char_set == TstRegOptUnicode)
  end
end


  # Test suite (execute when this file is specified in command line)
  if __FILE__ == $0 
    puts "test #{__FILE__}"
    
    opts = Regextest::RegexOption.new("ixm")
    puts "OK igonore" if(opts.is_ignore?)
    puts "OK extended" if(opts.is_extended?)
    puts "OK multiline" if(opts.is_multiline?)
    
    opts2 = opts.dup
    puts "OK dup igonore" if(opts2.is_ignore?)
    puts "OK dup extended" if(opts2.is_extended?)
    puts "OK dup multiline" if(opts2.is_multiline?)
    
    opts.modify("-ixm")
    puts "OK mod igonore" if(!opts.is_ignore?)
    puts "OK mod extended" if(!opts.is_extended?)
    puts "OK mod multiline" if(!opts.is_multiline?)
    
    # verify opt2 is independent of opt
    puts "OK mod igonore" if(opts2.is_ignore?)
    puts "OK mod extended" if(opts2.is_extended?)
    puts "OK mod multiline" if(opts2.is_multiline?)
    
  end

