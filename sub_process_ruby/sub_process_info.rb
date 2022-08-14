# frozen_string_literal: true

require_relative 'sub_process_list_gems'

module SubProcessInfo

  DASH = 8212.chr(Encoding::UTF_8) * 25

  class << self

    def call(cmd)
      case cmd
      when 'env'  then env
      when 'gems' then gems
      when 'lf'   then lf
      when 'lp'   then lp
      else
        "Invalid command '#{cmd}'!\n"
      end
    end

    # dump ENV
    def env
      data = ENV.sort_by { |k, _| k.downcase }
        .map { |k,v| "#{k.ljust 40} #{v.length > 60 ? "#{v}\n" : v}" }.join "\n"
      "\n#{DASH} ENV #{DASH}\n#{data}\n\n"
    end

    # show installed gem and some gem env settings
    def gems
      SubProcessGemList.gem_list
    end
   
    # dump $LOADED_FEATURES
    def lf
      data = $LOADED_FEATURES.join "\n"
      "\n#{DASH} $LOADED_FEATURES #{DASH}\n#{data}\n\n"
    end
    
    # dump $LOAD_PATH
    def lp
      data = $LOAD_PATH.join "\n"
      "\n#{DASH} $LOAD_PATH #{DASH}\n#{data}\n\n"
    end
  end
end
