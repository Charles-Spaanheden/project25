require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'
require_relative "./model/model.rb"

enable :sessions

include Model

##
# Home page route
#
# @return [Slim::Template] renders the home view
get('/') do
    slim(:home)
end

##
# Display all cards
#
# @return [Slim::Template] renders cards/index view with all cards and user session info
get('/cards') do
    db = databas("db/databas.db")
    result = db.execute("SELECT * FROM card")
    admin = admin(session[:id])
    logged_in = true
    if session[:id] == nil
        logged_in = false
    end
    slim(:"cards/index", locals: { cards: result, admin: admin, logged_in: logged_in }) 
end

##
# Display form to create a new card
#
# @return [Slim::Template] renders cards/new view
get('/cards/new') do
    slim(:"cards/new")
end

##
# Create a new card and redirect to card list
#
# @param [String] cardname the name of the card
# @param [String] cardrarity the rarity of the card
# @param [String] cardimage the image URL of the card
post('/cards/new') do
    cardcreate(params[:cardname], params[:cardrarity], params[:cardimage], "db/databas.db")
    redirect("/cards")
end

##
# Display user registration form
#
# @return [Slim::Template] renders users/new view
get('/users/new') do
    slim(:"users/new")
end

##
# Create a new user account
#
# @param [String] username the username
# @param [String] password the password
# @param [String] userimage the image URL for the user
# @param [String] password_confirmation password confirmation
post('/users/new') do
    usercreate(params[:username], params[:password], params[:userimage], params[:password_confirmation], session, "db/databas.db")
end

##
# Display login form
#
# @return [Slim::Template] renders login view
get('/login') do
    slim(:"login")
end

##
# Handle login form submission
#
# @param [String] username the user's username
# @param [String] password the user's password
post('/login') do
    userlogin(params[:username], params[:password], session, "db/databas.db")
end

##
# Display logged-in user's cards
#
# @return [Slim::Template] renders users/user_cards view
get('/users/user_cards') do
    result = usercards(session[:id])
    slim(:"users/user_cards", locals: { cards: result })
end

##
# Assign a card to a user
#
# @param [Integer] card_id the card's ID
# @param [Integer] user_id the user's ID
post('/users/user_cards/:card_id/:user_id') do
    usercardspost(params[:card_id], params[:user_id], "db/databas.db")
    redirect("/users/user_cards")
end

##
# Delete a card
#
# @param [Integer] card_id the ID of the card to delete
post('/cards/delete/:card_id') do
    carddelete(params[:card_id], "db/databas.db")
    redirect("/cards")
end

##
# Display edit form for a card
#
# @param [Integer] card_id the ID of the card to edit
# @return [Slim::Template] renders cards/edit view
get('/cards/edit/:card_id') do
    db = databas("db/databas.db")
    result = selectupdatecard(params[:card_id], "db/databas.db")
    slim(:"cards/edit", locals: { card: result })
end

##
# Update an existing card
#
# @param [Integer] card_id the card's ID
# @param [String] cardname updated card name
# @param [String] cardrarity updated rarity
# @param [String] cardimage updated image URL
post('/cards/edit/:card_id') do
    updatecard(params[:card_id], params[:cardname], params[:cardrarity], params[:cardimage], "db/databas.db")
    redirect("/cards/edit/#{params[:card_id]}")
end

##
# Delete a user's card from their collection
#
# @param [Integer] card_id the ID of the card
# @param [Integer] user_id the ID of the user
# @param [Integer] unique_id the unique instance ID of the card
post('/users/user_cards/delete/:card_id/:user_id/:unique_id') do
    usercardsdelete(params[:card_id], params[:user_id], params[:unique_id], "db/databas.db")
    redirect("/users/user_cards")
end

##
# Display list of all users
#
# @return [Slim::Template] renders users/index view
get('/users') do
    result = users("db/databas.db")
    slim(:"users/index", locals: { users: result })
end

##
# Display trading interface between logged-in user and selected user
#
# @param [Integer] selected_user_id the ID of the user to trade with
# @return [Slim::Template] renders cards/trading view
get('/cards/trading/:selected_user_id') do
    loggedin, selecteduser = selecteduser(session[:id], params[:selected_user_id], "db/databas.db")
    slim(:"cards/trading", locals: { logged_in_user_cards: loggedin, selected_user_cards: selecteduser })
end
