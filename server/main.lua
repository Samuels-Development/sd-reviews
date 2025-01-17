local locale = SD.Locale.T
local reviews = {} -- table to store reviews

--- Creates and loads the sd_reviews table on resource start.
CreateThread(function()
    local success, err = pcall(function()
        MySQL.query.await([[
            CREATE TABLE IF NOT EXISTS sd_reviews (
                ReviewID INT AUTO_INCREMENT,
                BusinessName VARCHAR(100) NOT NULL,
                AuthorIdentifier VARCHAR(100) DEFAULT NULL,
                AuthorName VARCHAR(100) DEFAULT 'Anonymous',
                Rating TINYINT NOT NULL,
                ReviewText TEXT DEFAULT NULL,
                CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                PRIMARY KEY (ReviewID)
            );
        ]])
    end)

    if not success then
        print("^1Error creating 'sd_reviews' table:", err)
        return
    end

    local result = MySQL.query.await('SELECT * FROM sd_reviews', {})
    if result and #result > 0 then
        for _, record in ipairs(result) do
            if not reviews[record.BusinessName] then
                reviews[record.BusinessName] = {}
            end
            table.insert(reviews[record.BusinessName], record)
        end
        print(('^2Loaded %d review(s) from sd_reviews.^0'):format(#result))
    else
        print('^1No records found or failed to query `sd_reviews` table.^0')
    end
end)

--- Function to find a business in Config.Businesses by name.
--- @param name string
--- @return boolean, table
GetBusinessDataByName = function(name)
    if not Config or not Config.Businesses then
        return false, nil
    end
    for _, biz in pairs(Config.Businesses) do
        if biz.name == name then
            return true, biz
        end
    end
    return false, nil
end

--- Function to retrieve player coordinates on the server side.
--- @param src number Player source ID.
--- @return vector3|nil The player's coords, or nil if unavailable.
GetPlayerCoords = function(src)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then
        return nil
    end
    local coords = GetEntityCoords(ped)
    return coords
end

--- Event to save a new review to both the database and the in-memory reviews table.
--- Checks star rating validity, verifies business data, and compares player location.
--- @param businessName string The name of the business.
--- @param starRating number The star rating (1-5).
--- @param reviewText string The body of the review.
--- @param isAnonymous boolean Whether the review is posted anonymously.
RegisterNetEvent('sd-reviews:server:saveReview', function(businessName, starRating, reviewText, isAnonymous)
    local src = source
    local ratingNum = tonumber(starRating)

    if not ratingNum or ratingNum < 1 or ratingNum > 5 then
        print(("^1[sd-reviews] Player %d submitted an invalid rating: %s^0"):format(src, tostring(starRating)))
        TriggerClientEvent('sd_bridge:notification', src, locale('notifications.invalid_rating'), 'error')
        return
    end

    local foundBusiness, businessData = GetBusinessDataByName(businessName)
    if not foundBusiness then
        print(("^1[sd-reviews] Business '%s' not found in Config.Businesses^0"):format(businessName))
        TriggerClientEvent('sd_bridge:notification', src, locale('notifications.business_not_found'), 'error')
        return
    end

    local playerCoords = GetPlayerCoords(src)
    if not playerCoords then
        print(("^1[sd-reviews] Could not get player %d coords. Aborting.^0"):format(src))
        TriggerClientEvent('sd_bridge:notification', src, locale('notifications.coords_not_found'), 'error')
        return
    end

    local dist = #(playerCoords - businessData.coords)
    if dist > (businessData.radius or 3.0) then
        print(("^1[sd-reviews] Player %d is too far from '%s' (%.2fm) to submit a review.^0"):format(src, businessName, dist))
        TriggerClientEvent('sd_bridge:notification', src, locale('notifications.too_far'), 'error')
        return
    end

    local identifier = SD.GetIdentifier(src)
    local fullName = SD.Name.GetFullName(src)
    if isAnonymous then
        fullName = "Anonymous"
    end

    MySQL.insert(
        'INSERT INTO sd_reviews (BusinessName, AuthorIdentifier, AuthorName, Rating, ReviewText) VALUES (?, ?, ?, ?, ?)',
        { businessName, identifier, fullName, ratingNum, reviewText or "" },
        function(insertId)
            if insertId then
                print(("^2Inserted new review for '%s' with ID: %d^0"):format(businessName, insertId))

                if not reviews[businessName] then
                    reviews[businessName] = {}
                end
                table.insert(reviews[businessName], {
                    ReviewID = insertId,
                    BusinessName = businessName,
                    AuthorIdentifier = identifier,
                    AuthorName = fullName,
                    Rating = ratingNum,
                    ReviewText = reviewText or "",
                    CreatedAt = os.date('%Y-%m-%d %H:%M:%S')
                })

                -- Success notification, referencing the placeholder {businessName} in the locale
                TriggerClientEvent('sd_bridge:notification', src, locale('notifications.review_submitted_success', { businessName = businessName }), 'success')
            else
                print(("^1Review insertion failed for business '%s'^0"):format(businessName))
                TriggerClientEvent('sd_bridge:notification', src, locale('notifications.review_submitted_fail'), 'error')
            end
        end
    )
end)

--- Callback to retrieve reviews from the in-memory reviews table.
--- @param businessName string The name of the business to get reviews for.
SD.Callback.Register('sd-reviews:server:getReviewsForBusiness', function(source, businessName)
    return reviews[businessName] or {}
end)

--- Callback to calculate the overall rating for a given business.
--- Also returns how many total reviews that business has.
SD.Callback.Register('sd-reviews:server:getAverageRating', function(source, businessName)
    local businessReviews = reviews[businessName] or {}
    local reviewCount = #businessReviews

    if reviewCount == 0 then
        return { average = 0, count = 0 }
    end

    local sum = 0
    for _, review in ipairs(businessReviews) do
        sum = sum + (review.Rating or 0)
    end

    local avg = sum / reviewCount
    return { average = avg, count = reviewCount }
end)

--- Callback to check if a player has already submitted a review for a specific business.
--- Returns { hasReview = true, reviewId = 123 } if found, or { hasReview = false } otherwise.
--- @param businessName string
SD.Callback.Register('sd-reviews:server:hasPlayerReviewedBusiness', function(source, businessName)
    local identifier = SD.GetIdentifier(source)
    local businessReviews = reviews[businessName] or {}

    for _, rev in ipairs(businessReviews) do
        if rev.AuthorIdentifier == identifier then
            return { hasReview = true, reviewId = rev.ReviewID }
        end
    end

    return { hasReview = false }
end)

SD.CheckVersion('sd-versions/sd-reviews') -- Check version of specified resource