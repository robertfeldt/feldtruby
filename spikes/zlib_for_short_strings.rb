require 'zlib'
require 'feldtruby/array/basic_stats'

def rand_string(length, alphabet)
  as = alphabet.length
  (1..length).map {alphabet[rand(as)]}.join
end

def compress(string)
  Zlib::Deflate.deflate(string)
end

def compression_ratio(string)
  compress(string).length.to_f/string.length
end

def info_for_alphabet(alphabet)
  puts "for alphabet = #{alphabet.inspect}"
  ([1,5,10,15,20,25,30,35,40,45,50,60,70]).each do |len|
    avg_c_len = (1..1000).map {compress(rand_string(len, alphabet)).length}.mean
    puts( "#{len}: %.2f, %.2f, %.2f" % [avg_c_len, avg_c_len-len, avg_c_len/len.to_f] )
  end
end

info_for_alphabet(("a".."z").to_a)
info_for_alphabet(("a".."d").to_a)
info_for_alphabet(("a".."b").to_a)