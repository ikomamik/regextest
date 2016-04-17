# encoding: utf-8

require "pp"

# 正規表現のオプションを保持するクラス
class Regtest::RegexOption
  attr_accessor :reg_options
  
  def initialize(options = nil)
    self.set(options)
  end
  
  # コピー用のメソッド（不要か）
  def initialize_copy(source_obj)
    @reg_options = source_obj.reg_options
  end
    
  # オプションのセット
  def set(options)
    @reg_options = 0
    modify(options)
  end
    
  # オプションの変更
  def modify(options)
    case options
    when String
      modify_string(options)
    when Integer
      modify_integer(options)
    end
  end
    
  # オプション文字列による変更
  def modify_string(opt_string)
    opts = opt_string.split("-")
    raise "Option string (#{opt_string}) is invalid." if(opts.size > 2)
    
    # ビットの設定
    if(opts[0])
      opts[0].split(//).each do | opt |
        case opt
        when 'i'
          @reg_options |= Regexp::IGNORECASE
        when 'x'
          @reg_options |= Regexp::EXTENDED
        when 'm'
          @reg_options |= Regexp::MULTILINE
        else
          raise "Invalid char (#{opt}) found in regexp option"
        end
      end
    end
    
    # ビットのリセット
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

  # オプションの変更
  def modify_integer(options)
    @reg_options |= options
  end
      

  # フラグの状態確認
  def is_ignore?
    (@reg_options & Regexp::IGNORECASE != 0)
  end
  
  def is_extended?
    (@reg_options & Regexp::EXTENDED != 0)
  end
  
  def is_multiline?
    (@reg_options & Regexp::MULTILINE != 0)
  end
  
end


  # テストスィート（このファイルがコマンド指定されたときだけ実行）
  if __FILE__ == $0 
    puts "test #{__FILE__}"
    
    opts = Regtest::RegexOption.new("ixm")
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
    
    # 元のオブジェクトと独立であることを確認
    puts "OK mod igonore" if(opts2.is_ignore?)
    puts "OK mod extended" if(opts2.is_extended?)
    puts "OK mod multiline" if(opts2.is_multiline?)
    
  end



