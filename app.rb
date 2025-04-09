require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'
require_relative "model.rb"

enable :sessions

get('/') do
    slim(:home)
end

get('/cards') do
    db = databas("db/databas.db")
    result = db.execute("SELECT * FROM card")
    admin = admin(session[:id])
    logged_in = true
    if session[:id] == nil
        logged_in = false
    end
    slim(:"cards/index",locals:{cards:result,admin:admin,logged_in:logged_in}) 

end

get('/cards/new') do
    slim(:"cards/new")
end

post('/cards/new') do
    cardcreate(params[:cardname],params[:cardrarity],params[:cardimage],"db/databas.db")
    redirect("/cards")
end

get('/users/new') do
    slim(:"users/new")
end

post('/users/new') do
    usercreate(params[:username],params[:password],params[:userimage],params[:password_confirmation],session,"db/databas.db")
end

get('/login') do
    slim(:"login")
end

post('/login') do
    userlogin(params[:username],params[:password],session,"db/databas.db")
end

get('/users/user_cards') do
    result = usercards(session[:id])
    slim(:"users/user_cards", locals: { cards:result})
end

post('/users/user_cards/:card_id/:user_id') do
    usercardspost(params[:card_id],params[:user_id],"db/databas.db")
    redirect("/users/user_cards")
end

post('/cards/delete/:card_id') do
    carddelete(params[:card_id],"db/databas.db")
    redirect("/cards")
end

get('/cards/edit/:card_id') do
    db = databas("db/databas.db")
    result = selectupdatecard(params[:card_id],"db/databas.db")
    slim(:"cards/edit", locals: { card:result })
end

post('/cards/edit/:card_id') do
    updatecard(params[:card_id],params[:cardname],params[:cardrarity],params[:cardimage],"db/databas.db")
    redirect("/cards/edit/#{params[:card_id]}")
end

post('/users/user_cards/delete/:card_id/:user_id/:unique_id') do
    usercardsdelete(params[:card_id],params[:user_id],params[:unique_id],"db/databas.db")
    redirect("/users/user_cards")
end
    
get('/users') do
    result = users("db/databas.db")
    slim(:"users/index",locals:{users:result})
end

get('/cards/trading/:selected_user_id') do
    loggedin, selecteduser = selecteduser(session[:id],params[:selected_user_id],"db/databas.db")
    slim(:"cards/trading", locals: { logged_in_user_cards: loggedin, selected_user_cards: selecteduser })
end
