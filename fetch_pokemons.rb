require 'httparty'
require 'awesome_print'
require 'byebug'

def get_json(url)
  JSON.parse(HTTParty.get(url).body)
end

output_file = ARGV[0] || raise('No output file')
list_url = 'http://pokeapi.co/api/v2/pokemon?limit=40000&offset=0'
pokemons = get_json(list_url)['results']
transformed = pokemons.map do |pk|
  pk_url = pk['url']
  puts "Fetching #{pk_url}"
  pk_json = get_json(pk_url)
  id = Integer(pk_json['id'])
  image_url = "http://assets.pokemon.com/assets/cms2/img/pokedex/detail/#{id.to_s.rjust(3, '0')}.png"

  {
    api_id: id,
    name: pk_json['name'],
    image_url: image_url
  }
end

File.write(output_file, JSON.generate({ 
  pokemons: transformed
}))
