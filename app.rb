require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'

get('/') do
    # db = SQLite3::Database.new("db/databas.db")
    # @image = db.execute("SELECT img FROM card")
    # @info = db.execute("SELECT * FROM card")

    slim(:home)
end

get('/cards') do
    db = SQLite3::Database.new("db/databas.db")
    db.results_as_hash = true
    result = db.execute("SELECT * FROM card")
    slim(:"cards/cards",locals:{cards:result}) 

end

get('/cards/create') do
    slim(:"cards/create")
end

post('/cards/create') do
    cardname = params[:cardname]
    cardrarity = params[:cardrarity]
    cardimage = params[:cardimage]
    db = SQLite3::Database.new("db/databas.db")
    db.results_as_hash = true
    if params[:cardimage] && params[:cardimage][:filename]
        filename = params[:cardimage][:filename]
        file = params[:cardimage][:tempfile]
        path = "./public/img/#{filename}"
        File.open(path, 'wb') do |f|
            f.write(file.read)
        end
    end
    db.execute("INSERT INTO card (name,type,img) VALUES (?,?,?)",[cardname,cardrarity,filename])
    redirect("/cards")
end

