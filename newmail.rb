#!/usr/bin/env ruby
UNIX_FROM = /^From \S+ ([A-Z][a-z]{2} ){2}[\s\d]\d \d{2}:\d{2}:\d{2} \d{4}$/
newmail=0
in_hdr=false
$<.each do |line|
  case line
    when UNIX_FROM
      newmail += 1
      in_hdr = true
    when /^Status: RO/
      newmail -= 1 if in_hdr
    when /^\s*$/
      in_hdr = false
  end
end
puts newmail
