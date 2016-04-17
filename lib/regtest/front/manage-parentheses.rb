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
    
    # カッコの参照
    def get_paren(get_id)
      if(Integer === get_id)
        @paren_hash["$$_#{get_id}"]
      else
        @paren_hash[get_id]
      end
    end
  end
end

# テストスィート（このファイルがコマンド指定されたときだけ実行）
if __FILE__ == $0 
end

