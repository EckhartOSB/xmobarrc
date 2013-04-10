#!/usr/local/bin/ruby
#
# ARGV contains ruby statements

def under(max, color)
  between(nil, max, color)
end

def over(min, color)
  between(min, nil, color)
end

def between(min, max, color)
  $input.gsub! /(\d+\.?\d*)/ do |val|
    num = val.to_f
    ((!min || min < num) && (!max || max > num)) ? "<fc=#{color}>#{val}</fc>" : val
  end
end

$stdin.each_line do |line|
  $input = line
  ARGV.each {|cmd| eval cmd;}
  $stdout.print $input
  $stdout.flush
end
