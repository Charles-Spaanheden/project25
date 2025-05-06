require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'
require_relative "./model/model.rb"

enable :sessions

include Model

PROTECTED_ROUTES = [
  /^\/$/,                                      # Home
  /^\/login$/,                                 # Login page
  /^\/users\/new$/,                            # New user form
  /^\/users$/,                                 # Create user (POST)
  /^\/users\/user_cards$/,                     # Logged-in user's cards
  /^\/users\/user_cards\/\d+\/\d+$/,           # Assign card to user (POST)
  /^\/users\/user_cards\/\d+\/\d+\/\d+\/delete$/, # Delete user's card (POST)
  /^\/users\/?$/,                              # List users
  /^\/cards\/?$/,                              # All cards (GET)
  /^\/cards$/,                                 # Create card (POST)
  /^\/cards\/new$/,  
  /^\/users\/new\/?$/,   # New card form
  /^\/cards\/\d+\/edit$/,                      # Edit form and update (GET & POST)
  /^\/cards\/\d+\/delete$/,                    # Delete card (POST)
  /^\/cards\/\d+\/trading$/                    # Trading page
]

LOGGED_IN_SLIMS = [
  /^\/$/,
  /^\/cards\/new$/,
  /^\/users\/user_cards$/,
  /^\/cards\/\d+\/trading$/
]

before do
    unless PROTECTED_ROUTES.any? { |route| route.match?(request.path_info) }
      p "Stay away"
      redirect("/login")
    end
  end
  
  before do
    if LOGGED_IN_SLIMS.any? { |route| route.match?(request.path_info) }
      if session[:id].nil?
        p "Session ID is nil"
        redirect("/login")
      end
    end
  end
  

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
get('/cards/') do
    db = databas("db/databas.db")
    result = card()
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
post('/cards') do
    cardcreate(params[:cardname], params[:cardrarity], params[:cardimage], "db/databas.db")
    redirect("/cards/")
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
post('/users') do
    if usercreate(params[:username], params[:password], params[:userimage], params[:password_confirmation], session, "db/databas.db")
        redirect("/login")
    else
        redirect("/users/new")
    end

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
    if cooldown(session[:last_time]) == false
        session[:last_time] = Time.now.to_i
        p "Cooldown time is up"
        sleep(2)
        redirect("/")
    end
    session[:last_time] = Time.now.to_i

    if userlogin(params[:username], params[:password], session, "db/databas.db")
        redirect("/")
    else
        redirect("/login")
    end
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
post('/cards/:card_id/delete') do
    carddelete(params[:card_id], "db/databas.db")
    redirect("/cards/")
end

##
# Display edit form for a card
#
# @param [Integer] card_id the ID of the card to edit
# @return [Slim::Template] renders cards/edit view
get('/cards/:card_id/edit') do
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
post('/cards/:card_id/edit') do
    updatecard(params[:card_id], params[:cardname], params[:cardrarity], params[:cardimage], "db/databas.db")
    redirect("/cards/#{params[:card_id]}/edit")
end

##
# Delete a user's card from their collection
#
# @param [Integer] card_id the ID of the card
# @param [Integer] user_id the ID of the user
# @param [Integer] unique_id the unique instance ID of the card
post('/users/user_cards/:card_id/:user_id/:unique_id/delete') do
    usercardsdelete(params[:card_id], params[:user_id], params[:unique_id], "db/databas.db")
    redirect("/users/user_cards")
end

##
# Display trading interface between logged-in user and selected user
#
# @param [Integer] selected_user_id the ID of the user to trade with
# @return [Slim::Template] renders cards/trading view
get('/cards/:selected_user_id/trading') do
    loggedin, selecteduser = selecteduser(session[:id], params[:selected_user_id], "db/databas.db")
    slim(:"cards/trading", locals: { logged_in_user_cards: loggedin, selected_user_cards: selecteduser })
end


##
# Display list of all users
#
# @return [Slim::Template] renders users/index view
get('/users/') do
    result = users("db/databas.db")
    slim(:"users/index", locals: { users: result })
end

