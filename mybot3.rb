#!/Users/edv/.rvm/bin/ruby-1.9.2-rc2
require './planetwars2.rb'
require "logger"


class AI

  def initialize
    @logger = Logger.new("fleet.log")
    $stderr = File.open("rubyerr.log","w")
    @logger.info("AI initialized")
  end


  def do_turn(pw)
    @logger.info("New turn")
    #return if pw.my_fleets.length >= 3
    return if pw.my_planets.length == 0
    return if pw.not_my_planets.length == 0
    attack(pw)
  end

  def attack(pw)
    comb = pw.my_planets.product(pw.not_my_planets)
    comb2 = comb.map{|my, other| [my,other,PlanetWars.travel_time(my,other)]}
    comb3 = comb2.sort_by{|my,other,distance| distance}
    comb3.each do |my, other, distance|
      if my.num_ships > (other.e_num_ships(my) + 1) then
        pw.issue_order(my.planet_id,other.planet_id,other.e_num_ships(my) + 1)
      end
    end

  end


end



ai = AI.new

map_data = ''
loop do
  current_line = gets.strip rescue break
  if current_line.length >= 2 and current_line[0..1] == "go"
    pw = PlanetWars.new(map_data)
    ai.do_turn(pw)
    pw.finish_turn
    map_data = ''
  else
    map_data += current_line + "\n"
  end
end
