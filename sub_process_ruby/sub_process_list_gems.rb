# frozen_string_literal: true

module SubProcessGemList

  GEM_PLATFORMS = Gem.platforms.reject { |p| p == 'ruby' }.map(&:to_s)
  
  class << self

    def gem_list
      # if a gem exists in multiple locations, @names[name] will be > 1
      names = Hash.new { |h,k| h[k] = 0 }
      dflt  = extract names, Gem.default_specifications_dir
      build = extract names, File.join(Gem.default_dir, 'specifications')
      user  = extract names, File.join(Gem.user_dir   , 'specifications')

      @dash  = 8212.chr(Encoding::UTF_8)
      @width = 75
      @dash_line = @dash * @width

      str = "\n#{RUBY_DESCRIPTION}\n".dup
      str <<  "#{@dash_line} Installed Gems\n"
      str << "Build     #{Gem.dir}\n"
      str << "User      #{Gem.user_dir}\n"
      t = Gem.path.join "\n          "
      str << "Gem.path  #{t}\n"
      str << "\n* gem exists in multiple locations\n\n" 

      str << "#{@dash * 11} Default Gems #{@dash * 11}\n"
      str << output(names, dflt, "D ")

      str << "#{@dash * 11} Build Gems #{@dash   * 13} \n"
      str << output(names, build, "B ")
      
      str << "#{@dash * 11} User Gems #{@dash    * 14} \n"
      str << output(names, user, "U ")
      str
    end

    private

    def output(names, ary, pre)
      cntr = 1
      str = ''.dup
      ary.each do |a|
        if names[a[0]] > 1
          str << "#{pre} #{a[0].ljust 25} * #{a[1]}\n"
        else
          str << "#{pre} #{a[0].ljust 25}   #{a[1]}\n"
        end
        str << "\n" if (cntr % 5) == 0
        cntr += 1
      end
      # str can contain two returns at end
      str.rstrip + "\n\n"
    end

    def extract(names, spec_dir)
      gem_ary = Dir['*.gemspec', base: spec_dir]
      ary = []
      gem_ary.each do |fn| 
        full = fn.sub(/\.gemspec\z/, '').dup
        platform = nil
        GEM_PLATFORMS.each do |p|
          if full.end_with? p
            platform = p
            full.sub! "-#{p}", ''
            break
          end
        end

        name, _, vers = full.rpartition '-'

        ary << [name, Gem::Version.new(vers), platform]
      end

      hsh = ary.group_by(&:first)
      ary = []
      hsh.each do |k,v|
        val = v.sort { |a,b| b[1] <=> a[1] }
          .map { |i| i[2].nil? ? i[1] : "#{i[1]}-#{i[2]}" }
          .join ' '
        ary << [k, val]
        names[k] += 1
      end
      ary
    end
  end
end
