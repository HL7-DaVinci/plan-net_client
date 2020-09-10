require 'json'


    jsonfile = ARGV[0]
    outfile = jsonfile + ".txt"

    puts "working on: #{jsonfile}..."
    s = File.read(jsonfile)
    h = JSON.parse(s)
    o = File.open(outfile,"w")
    o.puts "jsonfile = ["
    h["concept"].map do |code |
        o.puts "    { value: \'#{code["code"]}\', name: \'#{code["display"]}\' },"
    end
    o.puts "\n]\n"
    o.close
