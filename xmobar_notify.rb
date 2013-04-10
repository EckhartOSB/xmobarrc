#!/usr/local/bin/ruby
require "date"
require "optparse"

DATEFMT = "%Y %b %d %T"

def readfile(file)
  rv = []
  File.open(file) do |fd|
    fd.each_line do |l|
      urgency, expiration, said, text = l.strip.split ',', 4
      rv << [urgency.to_i,
	     DateTime.parse(expiration),
	     said,
	     text]
    end
  end
  rv
end

def writefile(file, ar)
  File.open(file, "w") do |fd|
    ar.each do |urgency, expiration, said, text|
      fd.puts "#{urgency.to_s},#{expiration.strftime(DATEFMT)},#{said},#{text}"
    end
  end
end

class DateTime
   class << self
     alias :oldparse :parse
     def parse(string)
	(string.downcase == "never") ? DateTime.jd(0x7FFFFFFF) : DateTime.oldparse(string)
     end
   end
end

options = {:file => "~/.xmobar_notify", :urgency => 0, :colors => {}, :expiration => "never"}

optparse = OptionParser.new do |opts|
  opts.banner = '
  usage: xmobar_notify.rb [-l]
  			  [-a text]
  			  [-c color]
	 		  [-d itemno]
			  [-e expiration]
			  [-f file]
			  [-r pattern]
			  [-u urgency]
			  [-v voice]
         		  [-w seconds]'

  opts.on('-a', '--add text', 'Add a notification') do |text|
    options[:add] = text.gsub(/[\x00-\x1f]/,'');
  end

  opts.on('-c', '--color colorspec', 'specify urgency:color pairs (comma separated)') do |colorspec|
    colorspec.split(',').each do |c|
      urg,clr = c.split(':',2)
      options[:colors][urg.to_i] = clr
    end
  end

  opts.on('-d', '--delete itemno', 'Delete ordinal notification') do |itm|
    options[:delete] = itm.to_i
  end

  opts.on('-e', '--expiration datetime', 'Specify when to remove this notification (default = never)') do |exp|
    options[:expiration] = exp
  end

  opts.on('-f', '--file file', 'Specify notifications file (default = ~/.xmobar_notify)') do |file|
    options[:file] = file
  end

  opts.on('-l', '--list', 'List remaining notifications') do
    options[:list] = true
  end

  opts.on('-r', '--remove pattern', 'Remove all notifications matching pattern') do |pattern|
    options[:remove] = Regexp.new pattern
  end

  opts.on('-u', '--urgency urgency', 'Specify urgency (only applies to -a)') do |urg|
    options[:urgency] = urg.to_i
  end

  opts.on('-v', '--voice urgency', 'Specify minimum urgency for audible reminders') do |urg|
    options[:voice] = urg.to_i
  end

  opts.on('-w', '--wait seconds', 'Specify how long to wait (enables cycling)') do |nsecs|
    options[:cycle] = nsecs.to_f
  end

end

begin
  optparse.parse!
rescue OptionParser::InvalidOption, OptionParser::MissingArgument => e
  puts e
  puts optparse
  exit 1
end

file = File.expand_path options[:file]
ar = readfile(file)

ar.slice!(options[:delete]) && writefile(file, ar) if options[:delete]
if (rgx = options[:remove])
  ndx = ar.size-1
  while (ndx >= 0)
    ar.slice! ndx if rgx =~ ar[ndx][3]
    ndx -= 1
  end
  writefile(file, ar)
end
(ar << [options[:urgency], DateTime.parse(options[:expiration]), 0, options[:add]]) && writefile(file, ar) if options[:add]
if nsecs = options[:cycle]
 begin
   ndx = 0
   voice = options[:voice]
   loop do
     if (ar.size > 0)
       ndx = 0 if (ndx >= ar.size)
       urgency, expiration, said, text = ar[ndx]
       color = nil
       found = nil
       options[:colors].each do |urg,clr|
	 if urg <= urgency && (!found || found < urg)
	   color = clr
	   found = urg
	 end
       end
       print "<fc=#{color}>" if color
       print "#{ndx}:#{text}"
       print "</fc>" if color
       print "\n"
       if voice && (voice <= urgency) && (said == '0')
         system "~/bin/say #{text} 2>/dev/null"
	 ar[ndx] = [urgency, expiration, 1, text]
	 writefile(file, ar)
       end
       if DateTime.now >= expiration
         ar.slice! ndx
	 writefile(file, ar)
       else
         ndx += 1
       end
     else
       puts " "
     end
     $stdout.flush
     break if nsecs <= 0
     sleep nsecs
     ar = readfile(file)	# pick up any external changes
   end
 rescue Interrupt
 end
end
if options[:list]
  ar.each_index do |ndx|
    urgency, expiration, said, text = ar[ndx]
    puts "#{ndx}:#{text}"
  end
end
