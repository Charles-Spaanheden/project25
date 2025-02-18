require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'

enable :sessions

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

get('/cards/register') do
    slim(:"cards/register")
end

post('/cards/register') do
    username = params[:username]
    password = params[:password]
    password_confirmation = params[:password_confirmation]
    if password == password_confirmation
        password_digest = BCrypt::Password.create(password)
        db = SQLite3::Database.new("db/databas.db")
        db.results_as_hash = true
        db.execute("INSERT INTO user (username,password) VALUES (?,?)",[username,password_digest])
        session[:username] = username
        p username
        p session[:username]
        redirect("/")
    else
        p "Passwords do not match"
        redirect("/cards/register")
    end
end

get('/cards/login') do
    slim(:"cards/login")
end

post('/cards/login') do
    username = params[:username]
    password = params[:password]
    db = SQLite3::Database.new("db/databas.db")
    db.results_as_hash = true
    result = db.execute("SELECT * FROM user WHERE username = ?",username).first
    pwdigest = result["password"]
    if BCrypt::Password.new(pwdigest) == password
        p "Inloggad"
        session[:username] = username
        redirect("/")
        p session[:username]
    else
        p "Fel lösenord"
        redirect("/cards/login")
    end
end