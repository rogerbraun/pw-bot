#!/Users/edv/.rvm/bin/ruby-1.9.2-rc2
require './planetwars2.rb'
require "logger"


class AI

  def initialize
    @logger = Logger.new("fleet.log")
    $stderr = File.open("rubyerr.log","w")
    @logger.info("AI initialized")
  end

  def endgame(pw)
    pw.my_planets.each do |p|

      @logger.info("Looking at Planet #{p.planet_id}")

      attackable = p.attackable(pw) 

      @logger.info("Attackable Planets: #{attackable.map{|planet| [planet.planet_id, PlanetWars.travel_time(p,planet), planet.e_num_ships(p)]} }")

      attackable.reject{|planet| planet.under_attack?(pw)}.each do |candidate|

        @logger.info("Attack Candidate: #{candidate.planet_id}") if candidate

        if candidate.e_num_ships(p) < p.safe_ships(pw) then
          pw.issue_order(p.planet_id, candidate.planet_id, candidate.e_num_ships(p) + 1)
        end
      end

      @logger.info("Finished Planet #{p.planet_id}")

    end
  end
  def rescue_endangered_planets(pw)
    endangered_planets = pw.my_planets.map{|p| [p.planet_id,p.in_danger?(pw)]}.select{|p| p[1]}
    comb = endangered_planets.product(pw.my_planets - endangered_planets)
    @logger.info(endangered_planets.inspect)
    comb.sort_by!{|my,other,distance| distance}
    comb.each do |danger, other, distance|
      if 0 < other.safe_ships(pw) then
        sendable = [danger[1] + 1, other.safe_ships(pw)].min
        pw.issue_order(other.planet_id, danger[0], sendable)
      end
    end
    
  end

  def do_turn(pw)
    @logger.info("New turn")
    #return if pw.my_fleets.length >= 3
    return if pw.my_planets.length == 0
    return if pw.not_my_planets.length == 0
    if pw.my_planets.size > pw.not_my_planets.size then
      rescue_endangered_planets(pw)
      endgame(pw)
    else
      attack(pw)
    end
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
