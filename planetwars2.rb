require "logger"

class Fleet
  attr_reader :owner, :num_ships, :source_planet, 
    :destination_planet, :total_trip_length, :turns_remaining
 
   def initialize(owner, num_ships, source_planet, 
                 destination_planet, total_trip_length, 
                 turns_remaining)
    @owner, @num_ships = owner, num_ships
    @source_planet = source_planet
    @destination_planet = destination_planet
    @total_trip_length = total_trip_length
    @turns_remaining = turns_remaining
  end
end

class Planet
  attr_reader :planet_id, :growth_rate, :x, :y
  attr_accessor :owner, :num_ships

  def initialize(planet_id, owner, num_ships, growth_rate, x, y)
    @planet_id, @owner, @num_ships = planet_id, owner, num_ships
    @growth_rate, @x, @y = growth_rate, x, y
  end

  def add_ships(n)
    @num_ships += amt
  end

  def remove_ships(n)
    @num_ships -= n
  end

  def e_num_ships(other)
    #@num_ships + self.distance(other_planet) * self.growth_rate
    (@owner != 0 ? (PlanetWars.travel_time(self, other) * @growth_rate) : 0)  + @num_ships
  end

  def safe_ships(pw)
    @num_ships - attacking_ships(pw) 
  end

  def in_danger?(pw)
    t = self.num_ships - attacking_ships(pw) + supporting_ships(pw) 
    t < 0 ? -t : false
  end

  def enemy_distance(pw)
    #pw.enemy_planets.inject(99999){|r,p| [r,PlanetWars.travel_time(self,p)].min}
    pw.enemy_planets.map{|p| PlanetWars.travel_time(self,p)}.min
  end

  def desirability(other,pw)
    travel_time_factor = PlanetWars.travel_time(self,other)
    growth_factor = - (2 * (@growth_rate.to_f  / travel_time_factor.to_f))
    enemy_factor = - @owner 
    enemy_distance_factor = - enemy_distance(pw) 
    ships_available_factor = - (other.num_ships / 5)
    ships_needed_factor = (self.e_num_ships(other) / 10)
    travel_time_factor + growth_factor + enemy_factor + enemy_distance_factor + ships_available_factor + ships_needed_factor
  end

  def needed_to_conquer(other,pw)
    self.e_num_ships(other) - attacking_ships(pw) + supporting_ships(pw)
  end

  def attacking_ships(pw)
    incoming_ships(@owner == 1 ? pw.enemy_fleets : pw.my_fleets)
  end

  def supporting_ships(pw)
    incoming_ships(@owner == 1 ? pw.my_fleets : pw.enemy_fleets)
  end

  def incoming_ships(fleet)
    fleet.select{|f| f.destination_planet == self.planet_id}.inject(0){|r,f| r += f.num_ships}
  end

  def attackable(pw)
    pw.not_my_planets.reject{|planet| planet.e_num_ships(self) >=  @num_ships - attacking_ships(pw)}.sort_by{|planet| planet.e_num_ships(self)}
  end

  def under_attack?(pw)
    return pw.fleets.inject(false){|r, f| r or f.destination_planet == self.planet_id}
  end
    

end

class PlanetWars
  attr_reader :planets, :fleets
  def initialize(game_state)
    parse_game_state(game_state)
    @orders = Logger.new("orders.log")
  end

  def num_planets
    @planets.length
  end

  def get_planet(id)
    @planets[id]
  end

  def num_fleets
    @fleets.length
  end

  def get_fleet(id)
    @fleets[id]
  end

  def my_planets
    @planets.select {|planet| planet.owner == 1 }
  end

  def neutral_planets
    @planets.select {|planet| planet.owner == 0 }
  end

  def enemy_planets
    @planets.select {|planet| planet.owner > 1 }
  end

  def not_my_planets
    @planets.reject {|planet| planet.owner == 1 }
  end

  def my_fleets
    @fleets.select {|fleet| fleet.owner == 1 }
  end

  def enemy_fleets
    @fleets.select {|fleet| fleet.owner > 1 }
  end

  def to_s
    s = []
    @planets.each do |p|
      s << "P #{p.x} #{p.y} #{p.owner} #{p.num_ships} #{p.growth_rate}"
    end
    @fleets.each do |f|
      s << "F #{f.owner} #{f.num_ships} #{f.source_planet} #{f.destination_planet} #{f.total_trip_length} #{f.turns_remaining}"
    end
    return s.join("\n")
  end

  def self.distance(source, destination)
    Math::hypot( (source.x - destination.x), (source.y - destination.y) )
  end

  def self.travel_time(source, destination)
    distance(source, destination).ceil
  end

  def issue_order(source, destination, num_ships)
    @fleets << Fleet.new(1,num_ships,source,destination,0,0) 
    @planets[source].num_ships -= num_ships
    t = "#{source} #{destination} #{num_ships}"
    puts t
    @orders.info(t)
    STDOUT.flush
  end

  def is_alive(player_id)
    ((@planets.select{|p| p.owner == player_id }).length > 0) || ((@fleets.select{|p| p.owner == player_id }).length > 0)
  end

  def parse_game_state(s)
    @planets = []
    @fleets = []
    lines = s.split("\n")
    planet_id = 0

    lines.each do |line|
      line = line.split("#")[0]
      tokens = line.split(" ")
      next if tokens.length == 1
      if tokens[0] == "P"
        return 0 if tokens.length != 6
        p = Planet.new(planet_id,
                       tokens[3].to_i, # owner
                       tokens[4].to_i, # num_ships
                       tokens[5].to_i, # growth_rate
                       tokens[1].to_f, # x
                       tokens[2].to_f) # y
        planet_id += 1
        @planets << p
      elsif tokens[0] == "F"
        return 0 if tokens.length != 7
        f = Fleet.new(tokens[1].to_i, # owner
                      tokens[2].to_i, # num_ships
                      tokens[3].to_i, # source
                      tokens[4].to_i, # destination
                      tokens[5].to_i, # total_trip_length
                      tokens[6].to_i) # turns_remaining
        @fleets << f
      else
        return 0
      end
    end
    return 1
  end

  def finish_turn
    puts "go"
    STDOUT.flush
  end
end
