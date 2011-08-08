require 'rubygems'
require 'sinatra'
require 'sqlite3'
require 'json'

db = SQLite3::Database.new("words.db")
db.type_translation = true
autocomplete_lookup = db.prepare("select word from words where word glob ? order by id limit 10") # we've done the histogram and chosen IDs specifically
ngram_lookups = {}
['gb','us'].each {|c|
  ngram_lookups[c] = {}
 ['0','1','2','3'].each {|y|
    db.execute("attach '/dbs/#{c}-#{y}.db' as #{c}#{y}")
    ngram_lookups[c][y] = db.prepare("select we.word, count from words wa, words wb, words wc, words wd cross join #{c}#{y}.ngrams, words we where wa.word = ? and wb.word = ? and wc.word = ? and wd.word = ? and wa.id = a and wb.id = b and wc.id = c and wd.id = d and we.id = e order by count desc limit 50" )
  }
}

get('/autocomplete') {
  pass unless params['term']
  autocomplete_lookup.execute(params['term']+'*').map {|row| row[0] }.sort.to_json
}

get('/5gram-histo') {
  country = ngram_lookups[params['usgb']]
  pass unless country
  year = country[params['year']]
  pass unless year
  year.execute(params['a'],params['b'],params['c'],params['d']).map {|row| [row[0],row[1]] }.to_json
}

get('/') {
  erb :page, :locals => {:good_to_go => ['a','b','c','d'].all? {|w| !params[w].to_s.empty? } }
}
