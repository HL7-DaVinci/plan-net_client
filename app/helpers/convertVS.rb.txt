require 'pry'
require 'json'


    jsonfile = ARGV[0]
    outfile = jsonfile + ".txt"

    puts "working on: #{jsonfile}..."
   # binding.pry
    s = File.read(jsonfile)
    h = JSON.parse(s)
    o = File.open(outfile,"w")
    o.puts "jsonfile = ["
    binding.pry 
    h["compose"]["include"][0]["concept"].map do |code |
        # binding.pry
        o.puts "    { value: \'#{code["code"]}\', name: \'#{code["display"]}\' },"
    end
    o.puts "\n]\n"
    o.close
