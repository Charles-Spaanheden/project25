module Model

    def databas(fil)
        db = SQLite3::Database.new("#{fil}")
        db.results_as_hash = true
        return db
    end

    def cardcreate(cardname,cardrarity,cardimage,db)
        db = databas(db)
        if cardimage && cardimage[:filename]
            filename = cardimage[:filename]
            file = cardimage[:tempfile]
            path = "./public/img/#{filename}"
            File.open(path, 'wb') do |f|
                f.write(file.read)
            end
        end
        db.execute("INSERT INTO card (name,type,img) VALUES (?,?,?)",[cardname,cardrarity,filename])
    end

    def usercreate(username,password,userimage,password_confirmation,session,db)
        db = databas(db)
        if password == password_confirmation
            password_digest = BCrypt::Password.create(password)
            if userimage && userimage[:filename]
                filename = userimage[:filename]
                file = userimage[:tempfile]
                path = "./public/profileimg/#{filename}"
                File.open(path, 'wb') do |f|
                    f.write(file.read)
                end
                db.execute("INSERT INTO user (username, password, profileimg) VALUES (?, ?, ?)", [username, password_digest, filename])
            else
                db.execute("INSERT INTO user (username, password) VALUES (?, ?)", [username, password_digest])
            end
            session[:username] = username
            username
            redirect("/")
        else
            p "Passwords do not match"
            redirect("/user/new")
        end
    end

    def userlogin(username,password,session,db)
        db = databas(db)
        db.results_as_hash = true
        result = db.execute("SELECT * FROM user WHERE username = ?",username).first
        pwdigest = result["password"]
        if BCrypt::Password.new(pwdigest) == password
            session[:username] = username
            session[:id] = result["userid"]
            redirect("/")
        else
            redirect("/login")
        end
    end

    def showcards(userid,db)
        db = databas(db)
        result = db.execute("SELECT * FROM card_user_ownership INNER JOIN card ON card_user_ownership.card_id = card.id WHERE card_user_ownership.user_id = ?", [userid])
        return result
    end

    def usercards(userid)
        db = databas("db/databas.db")
        result = db.execute("SELECT * FROM card_user_ownership INNER JOIN card ON card_user_ownership.card_id = card.id WHERE card_user_ownership.user_id = ?", [userid])
        return result
    end

    def usercardspost(card_id,user_id,db)
        db = databas(db)
        db.execute("INSERT INTO card_user_ownership (card_id,user_id) VALUES (?,?)",[card_id,user_id])
    end

    def carddelete(card_id,db)
        db = databas(db)
        db.execute("DELETE FROM card WHERE id = ?", [card_id])
    end

    def usercardsdelete(card_id,user_id,unique_id,db)
        db = databas(db)
        db.execute("DELETE FROM card_user_ownership WHERE card_id = ? AND user_id = ? AND unique_id = ?", [card_id,user_id,unique_id])
    end

    def users(db)
        db = databas(db)
        db.execute("SELECT * FROM user")
    end

    def selecteduser(id,selectedid,db)
        db = databas(db)

        logged_in_user_cards = showcards(id,"db/databas.db")
        selected_user_cards = showcards(selectedid,"db/databas.db")    
        return logged_in_user_cards, selected_user_cards
    end

    def admin(id)
        db = databas("db/databas.db")
        result = db.execute("SELECT userid FROM user WHERE userid = ?", id).first
        if result && result["userid"] == 1
            return true
        else
            return false
        end
    end

    def updatecard(card_id, cardname, cardrarity, cardimage, db)
        db = databas(db)
        if cardimage && cardimage[:filename]
            filename = cardimage[:filename]
            file = cardimage[:tempfile]
            path = "./public/img/#{filename}"
            File.open(path, 'wb') do |f|
                f.write(file.read)
            end
            db.execute("UPDATE card SET name = ?, type = ?, img = ? WHERE id = ?", [cardname, cardrarity, filename, card_id])
        else
            db.execute("UPDATE card SET name = ?, type = ? WHERE id = ?", [cardname, cardrarity, card_id])
        end
    end

    def selectupdatecard(card_id, db)
        db = databas(db)
        result = db.execute("SELECT * FROM card WHERE id = ?", [card_id]).first
        return result
    end
    
end