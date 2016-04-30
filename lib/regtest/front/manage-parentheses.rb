# encoding: utf-8

# カッコを管理するクラス
module Regtest::Front::ManageParentheses
  class Parens
    def initialize()
      @paren_hash = {}
      @paren_array = []
    end
    
    # カッコの登録
    def add(paren)
      # 後方参照がある場合は、とりあえず登録
      if(paren.prefix.length == 0 ||    # prefixが無いときは捕獲
         (paren.prefix[-1] != ':' &&    # (?: or (?i: or (?imx), etc.以外のとき
          !paren.prefix.match(/^([imx]*(?:\-[imx]+)?)$/) &&
          !paren.prefix.match(/^[\=\!\>]|\<[\=\!]/)
         )
        ) 
        @paren_array.push paren
      end
      
      # 名前付きの場合は、その名前も登録
      if(paren.name)
        @paren_hash[paren.name] = paren
      end
      paren
    end
    
    # カッコのソート（カッコの番号はoffset順で解析順ではないので）
    def sort
      # pp @paren_array.map{|paren| paren.offset}
      @paren_array.sort{|x, y| x.offset <=> y.offset}.each_with_index do | paren, i |
        # puts "$$_#{i+1}  offset:#{paren.offset}"
        refer_name = "$$_#{i+1}"
        @paren_hash[refer_name] = paren    # カッコは１から。
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
        target_id = @paren_array.size - 1
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
end

# Test suite (execute when this file is specified in command line)
if __FILE__ == $0 
end

