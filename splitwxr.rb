#!/usr/bin/ruby
#
# Split a WXR into smaller chunks 
# Parse the 'premable' into memory
# Parse the <items> into memory
# Parse the <postamble> into memory
# for each X number of posts or size of output
#   Create a new file
#   Write preamble, X posts, postamble
#
# Argument is -o "filename" to which is appended a .xxx.xml where xxx varys.
# Reads wxr from from stdin
# Depends on newlines in the right places. 
# hard coded for appoximately 2MB per output file. more or less
#
# 2/20/2008 - Might work - it splits and Firefox doesn't complain when loading 
# the little files. Ruby Rexml doesn't either. 
 def nextfile(ctr)
   fn = $prefix+'.'+ctr.to_s+".xml"
   # returns the handle
   h = File.new(fn,'w')
   $preamble.each {|ln| h.puts ln}
   return h
 end

OSIZE = (2**20)*1   #MB * n 
if ARGV.length != 2 || ARGV[0] != '-o'
  $stderr.puts "-o <partial_filename> required"
  exit
end
$prefix = ARGV[1]
$preamble = []
$postamble = []
$items = []
$chunksz = 0
$chunk = 1
$inPre = true
$inItems = false   
$inPosta = false
$curItem = []
$stdin.each do |ln|
  if $inPre
    if ln[/<item>/i]
      $inPre = false
      $inItems = true
      $curItem << ln
    else
      $preamble << ln
    end
  elsif $inItems  == true
    if ln[/<\/channel>/]
      $inItems = false
      $postamble[0] = ln
      $inPosta = true
      next
    end
    if ln[/<\/item>/]
      # Finalize item - move curItem to items
      $curItem << ln
      $items << $curItem
    elsif ln[/<item>/]
      # start new item
      $curItem = ln
    else
      $curItem << ln
    end
  elsif $inPosta == true
    $postamble << ln
  else 
    # an error in the state machine
    $stderr.puts "Should not get here"
    $curItem << ln
  end
end
$stderr.puts "#{$preamble.length} Preamble Lines"
$stderr.puts "#{$items.length} Entrys"
$stderr.puts "#{$postamble.length} Postamble Lines"
# for testing purposes, dump it all to stdout
# $preamble.each { |l| $stdout.puts l}
# $items.each { |l| $stdout.puts l}
# $postamble.each { |l| $stdout.puts l}
# time to parse and chunkify those posts in $items
$stderr.puts "Breaking into parts near #{OSIZE} bytes"
$outf = nextfile($chunk)
$items.each do |item|
  item.each do |ln|
    $outf.puts ln
    $chunksz = $chunksz + ln.length
  end
  if $chunksz > OSIZE
    $postamble.each {|t| $outf.puts t}
    $outf.close
    $chunk = $chunk + 1
    $chunksz = 0
    $outf = nextfile($chunk)
  end
end
# close the last one
$postamble.each {|t| $outf.puts t}


