module Model

    def databas(fil)
        db = SQLite3::Database.new("#{fil}")
        db.results_as_hash = true
        return db
    end

   

    def card()
        db = databas("db/databas.db")
        result = db.execute("SELECT * FROM card")
        return result
    end

    def cardcreate(cardname,cardrarity,cardimage,db)
        db = databas(db)
        if cardname.length <= 0 || cardrarity.length <= 0
            p "Card name and rarity cannot be empty"
            return false
        end
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
        if username.length <= 0 || password.length <= 0 || password_confirmation.length <= 0
            p "Username, password, and password confirmation cannot be empty"
            return false
        end
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
            return true
        else
            p "Passwords do not match"
            return false
        end
    end

    def userlogin(username,password,session,db)
        db = databas(db)
        db.results_as_hash = true
        result = db.execute("SELECT * FROM user WHERE username = ?",username).first
        if result.nil?
            return false
        end
        pwdigest = result["password"]
        if BCrypt::Password.new(pwdigest) == password
            session[:username] = username
            session[:id] = result["userid"]
            return true
        else
            return false
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

    def cooldown(time)
        if time.nil?
            return true
        end
        current_time = Time.now.to_i
        if current_time.to_f - time.to_f >= 6
            return true
        else
            p "too fast, try again later"
            return false
        end
    end

    def carddelete(card_id,db)
        db = databas(db)
        file = db.execute("SELECT img FROM card WHERE id = ?", [card_id]).first
        if file && file["img"]
            path = "./public/img/#{file["img"]}"
            File.delete(path) if File.exist?(path)
        end
        db.execute("DELETE FROM card WHERE id = ?", [card_id])
        db.execute("DELETE FROM card_user_ownership WHERE card_id = ?", [card_id])
        
    end

    # def ownership(session,unique_id)
    #     if session[:id] == unique_id
    #         return true
    #     else
    #         return false
    #     end
    # end

        

    def usercardsdelete(card_id, user_id, unique_id, db)
        db = databas(db)
    
        ownership = db.execute("SELECT * FROM card_user_ownership WHERE unique_id = ? AND user_id = ?", [unique_id, session[:id]]).first
    
        if ownership
            db.execute("DELETE FROM card_user_ownership WHERE unique_id = ?", [unique_id])
        else
            pp "Don't tamper with other users cards"
        end
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
        if cardname.nil? || cardrarity.nil?
            p "Card name and rarity cannot be empty"
            return false
        end
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