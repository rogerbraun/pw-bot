#!/home/roger/.rvm/rubies/ruby-1.9.2-head/bin/ruby
require './planetwars2.rb'
require "logger"


class AI

  def initialize
    @logger = Logger.new("fleet.log")
    $stderr = File.open("rubyerr.log","w")
    @logger.info("AI initialized")
  end

  def rescue_endangered_planets(pw)
    endangered_planets = pw.my_planets.map{|p| [p.planet_id,p.in_danger?(pw)]}.select{|p| p[1]}
    comb = endangered_planets.product(@my_planets - endangered_planets)
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
    @my_planets = pw.my_planets.sort_by {|x| x.growth_rate}
    @other_planets = pw.not_my_planets.sort_by {|x| -x.num_ships }
    @attacked = pw.my_fleets.map(&:destination_planet)
    
    if pw.my_planets.size > pw.not_my_planets.size then 
      rescue_endangered_planets(pw)
      endgame(pw)
    else
      attack_2(pw)
      if @my_planets.size > 3 then
        rescue_endangered_planets(pw)
      end
    end    
  end

  def endgame(pw)
    @my_planets.each do |p|

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

  def endgame2(pw)
    @other_planets.each do |p|
      ships_needed = p.num_ships - p.attacking_ships(pw) 
      @my_planets.sort_by{|p2| PlanetWars.travel_time(p,p2)}.each do |p2|
        r_ships_needed = p.stg(p2) + ships_needed
        if ships_needed > 0 then 
          
          if p2.safe_ships(pw) > 0 then
            sendable = [r_ships_needed + 1,p2.safe_ships(pw) * 2 / 3].min
            next if sendable == 0
            ships_needed -= sendable
            pw.issue_order(p2.planet_id,p.planet_id, sendable) 

          end
        end
      end     
    end
  end

  def attack_2(pw)
    @comb = @my_planets.product(@other_planets)
    @comb.map! do |my,other| 
      [my,other,other.desirability(my,pw)]
    end
    @comb.sort_by!{|my,other,d| d}
    @comb.each do |my, other, d|
      
      if d < 0 and my.safe_ships(pw) > other.needed_to_conquer(my,pw) and other.needed_to_conquer(my,pw) > 0  then
        pw.issue_order(my.planet_id, other.planet_id,other.needed_to_conquer(my,pw) + 1)  
      end
    end
  end

  def attack_3(pw)
    @my_planets.each do |p|

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

  def attack_planets(pw)
    @other_planets.each do |p|
      ships_needed = p.num_ships - p.attacking_ships(pw)
      @my_planets.sort_by{|p2| PlanetWars.travel_time(p,p2)}.each do |p2|
        r_ships_needed = p.stg(p2) + ships_needed
        if ships_needed > 0 and r_ships_needed < @my_planets.inject(0){|r,planet| r += planet.num_ships}  then
          
          if p2.safe_ships(pw) > 0 then
            sendable = [r_ships_needed + 1,p2.safe_ships(pw)].min
            ships_needed -= sendable
            pw.issue_order(p2.planet_id,p.planet_id, sendable) 

          end
        end
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
