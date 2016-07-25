require 'httparty'
require 'awesome_print'
require 'byebug'
require 'json'
require 'pg'

class PokemonOccurence < Object
  attr_accessor :api_id
  attr_accessor :pokemon_number
  attr_accessor :latitude
  attr_accessor :longitude
  attr_accessor :expiration_time;
end

def parse_pokemon(pokemon_json)
  pokemon = PokemonOccurence.new
  pokemon.pokemon_number = pokemon_json['pokemonId']
  pokemon.api_id = pokemon_json['id']
  pokemon.expiration_time = Time.at(pokemon_json['expiration_time']).utc.to_datetime
  pokemon.latitude = pokemon_json['latitude']
  pokemon.longitude = pokemon_json['longitude']
  pokemon
end

def load_pokemons(conn)
  pokemons = JSON.parse(File.read('./pokemon-list.json'))
  pokemons.each do |pk|
    id = Integer(pk['id'].sub(/^0+/, ''))
    name = pk['name']
    image_url = pk['ThumbnailImage']
    active = (id <= 150)
    conn.exec_params('INSERT INTO pokemons (number, name, thumbnail_url, active) VALUES ($1, $2, $3, $4) ON CONFLICT DO NOTHING', [id, name, image_url, active]).first
  end
end

def fetch_pokemons(latitude, longitude)
  url = "http://pokevision.com/map/data/#{latitude}/#{longitude}"

  sleep 1
  request = HTTParty.get(url)
  begin
    body = request.body
  
    if body.start_with?('<!DOCTYPE')
       raise RuntimeError.new('maintenance')
    end 
    json = JSON.parse(request.body)
    return json['pokemon'].map do |pk_json|
      parse_pokemon(pk_json)
    end
  end
end

def persist_occurence(conn, occurence)
  pokemon_number = occurence.pokemon_number
  pokemon = conn.exec_params('SELECT * FROM pokemons WHERE number = $1', [pokemon_number]).first || raise('Unknown pokemon')
  pokemon_id = pokemon['id']

  q = <<-SQL
    INSERT INTO pokemon_occurences (
      pokemon_id,
      api_id,
      expiration_time,
      latitude,
      longitude
    )
    VALUES ($1, $2, $3, $4, $5)
    ON CONFLICT DO NOTHING
  SQL
  pokemon = conn.exec_params(q, [
    pokemon_id,
    occurence.api_id,
    occurence.expiration_time,
    occurence.latitude,
    occurence.longitude
  ])
end

def find_max_offset(conn)
  ex_latitude = 34.00872705055817
  ex_longitude = -118.49619626998903
  pokemons = fetch_pokemons(ex_latitude, ex_longitude)
  target = pokemons.max_by(&:expiration_time)
  latitude = target.latitude
  longitude = target.longitude
  min_offset = 0.0
  max_offset = 1.0
  
  puts "Centering on pokemon at (#{latitude}, #{longitude})"
  loop do
    offset = (max_offset - min_offset) / 2
    puts "Fetching with offset #{offset}"
    pokemons = fetch_pokemons(latitude, longitude + offset)
    found = pokemons.find {|p| p.api_id == target.api_id && p.expiration_time == target.expiration_time }
    if found.nil?
      max_offset = offset
    else
      min_offset = offset
    end
    break if max_offset - min_offset < 0.001
  end
  puts "Offset found: #{min_offset}"
end

def fetch_box(conn, lat1, lon1, lat2, lon2)
  from_lat, to_lat = [lat1, lat2].minmax
  from_lon, to_lon = [lon1, lon2].minmax
  # This is the 'radius', higher values may work
  latitude_offset = 0.003255195915699005 * 1.5
  longitude_offset = 0.006510417442768812 * 1.5
  lat_steps = (from_lat..(to_lat + latitude_offset)).step(latitude_offset)
  lon_steps = (from_lon..(to_lon + longitude_offset)).step(longitude_offset)
  step_count = lat_steps.count * lon_steps.count

  puts "Fetching #{step_count} locations"
  lat_steps.each do |lat|
    lon_steps.each do |lon|
      print "Fetching at (#{lat}, #{lon})... "
      pokemons = fetch_pokemons(lat, lon)
      print "found #{pokemons.length}, saving... "
      pokemons.each do |pk|
        persist_occurence(conn, pk)
      end
      puts 'ok'
    end
  end
end

conn = PG.connect(dbname: 'pokemap')

load_pokemons(conn)
loop do
  fetch_box(conn, 48.9080594, 2.2436142, 48.80912453, 2.45853424)
end

