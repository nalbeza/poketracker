require 'rubygems'
require 'sinatra'
require 'pg'
require 'byebug'
require 'json'

get '/' do
  File.read(File.join('public', 'index.html'))
end

get '/data' do
  conn = PG.connect(dbname: 'pokemap')
  target = params[:name]

  q = <<-SQL
    SELECT p.name, p.thumbnail_url, t.latitude, t.longitude, t.count FROM (
      SELECT pokemon_id, latitude, longitude, count(*) AS count
      FROM pokemon_occurences
      GROUP BY pokemon_id, latitude, longitude
    ) t
    LEFT JOIN pokemons p ON p.id = t.pokemon_id
    WHERE p.name = $1
    ORDER BY count DESC
  SQL
  res = conn.exec_params(q, [target])
  JSON.generate({
    data: res.map do |e|
      {
        name: e['name'],
        latitude: Float(e['latitude']),
        longitude: Float(e['longitude']),
        thumbnail_url: e['thumbnail_url'],
        count: Integer(e['count']),
      }
    end
  })
end
