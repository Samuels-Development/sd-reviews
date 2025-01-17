local locale = SD.Locale.T

--- Function to submit a review.
--- Opens an input dialog allowing the player to choose their star rating,
--- provide an optional short review (max 120 chars), and choose anonymity.
--- @param businessName string The name of the business for reference.
local SubmitReview = function(businessName)
    local reviewData = lib.inputDialog(
        locale('context_menu.write_review_title'), 
        {
            {
                type = 'select',
                label = locale('context_menu.review_star_rating_label'),
                options = {
                    { value = '1', label = '1 ⭐️' },
                    { value = '2', label = '2 ⭐️' },
                    { value = '3', label = '3 ⭐️' },
                    { value = '4', label = '4 ⭐️' },
                    { value = '5', label = '5 ⭐️' },
                },
                required = true,
                default = '5'
            },
            {
                type = 'textarea',
                label = locale('context_menu.review_text_label'),
                placeholder = locale('context_menu.review_text_placeholder'),
                max = 120,
                required = false
            },
            {
                type = 'checkbox',
                label = locale('context_menu.review_anonymous_label'),
                checked = false
            }
        }, 
        { allowCancel = true }
    )

    if not reviewData then return end

    local starRating = reviewData[1]
    local shortReview = reviewData[2]
    local isAnonymous = reviewData[3]

    TriggerServerEvent('sd-reviews:server:saveReview', businessName, starRating, shortReview, isAnonymous)
end

--- Function to retrieve reviews for a given business from the server.
--- Displays them in a new context menu. If no reviews are found, shows a context menu with a message.
--- @param businessName string The business name to fetch reviews for.
ShowBusinessReviews = function(businessName)
    SD.Callback('sd-reviews:server:getReviewsForBusiness', false, function(data)
        local options = {}

        if not data or #data == 0 then
            options[#options + 1] = {
                title = locale('context_menu.no_reviews_found_title'),
                icon = 'fas fa-exclamation-circle',
                description = locale('context_menu.no_reviews_found_description'),
                disabled = true
            }

            options[#options + 1] = {
                title = locale('context_menu.return_main_menu_title'), 
                icon = 'fas fa-arrow-left',
                description = locale('context_menu.return_main_menu_description'),
                onSelect = function()
                    ShowReviewsMenu(businessName)
                end
            }

            lib.registerContext({
                id = 'business_reviews_menu_empty',
                title = locale('context_menu.read_reviews_title'),
                options = options
            })

            lib.showContext('business_reviews_menu_empty')
            return
        end

        for _, review in ipairs(data) do
            local rating = review.Rating or 0
            local author = review.AuthorName or "Anonymous"
            local text = review.ReviewText ~= "" and review.ReviewText or locale('context_menu.review_no_comment')

            options[#options + 1] = {
                title = string.format("%d ⭐️ — %s", rating, author),
                icon = 'fas fa-user',
                description = text
            }
        end

        options[#options + 1] = {
            title = locale('context_menu.return_main_menu_title'), 
            icon = 'fas fa-arrow-left',
            description = locale('context_menu.return_main_menu_description'),
            onSelect = function()
                ShowReviewsMenu(businessName)
            end
        }

        lib.registerContext({
            id = 'business_reviews_menu',
            title = locale('context_menu.read_reviews_title'),
            options = options
        })

        lib.showContext('business_reviews_menu')
    end, businessName)
end

--- Function to show the reviews menu.
--- If the business has zero reviews, displays a "no reviews yet" message.
--- Otherwise, shows the average rating and total review count.
--- @param businessName string The name of the business (for display).
ShowReviewsMenu = function(businessName)
    SD.Callback('sd-reviews:server:getAverageRating', false, function(ratingData)
        local avg = (ratingData and ratingData.average) or 0
        local count = (ratingData and ratingData.count) or 0

        SD.Callback('sd-reviews:server:hasPlayerReviewedBusiness', false, function(reviewStatus)
            local starRating = string.format("%.1f", avg)
            local ratingDescription

            if count == 0 then
                ratingDescription = locale('context_menu.no_rating_yet')
            else
                ratingDescription = locale('context_menu.rating_placeholder_count', {
                    rating = starRating,
                    count = count
                })
            end

            local options = {}

            options[#options + 1] = {
                title = locale('context_menu.reviews_title', { businessName = businessName or "Unknown Business" }),
                icon = 'fas fa-utensils',
                description = ratingDescription
            }

            options[#options + 1] = {
                title = locale('context_menu.read_reviews_title'),
                icon = 'fas fa-comments',
                description = locale('context_menu.read_reviews_description'),
                onSelect = function()
                    ShowBusinessReviews(businessName)
                end
            }

            if not reviewStatus.hasReview then
                options[#options + 1] = {
                    title = locale('context_menu.write_review_title'),
                    icon = 'fas fa-pen',
                    description = locale('context_menu.write_review_description'),
                    onSelect = function()
                        SubmitReview(businessName)
                    end
                }
            else
                options[#options + 1] = {
                    title = locale('context_menu.already_submitted_review_title'),
                    icon = 'fas fa-ban',
                    description = locale('context_menu.already_submitted_review_description'),
                    disabled = true
                }
            end

            lib.registerContext({
                id = 'reviews_menu',
                title = locale('context_menu.reviews_header', { businessName = businessName or "Unknown Business" }),
                options = options,
                onExit = function()
                end
            })

            lib.showContext('reviews_menu')
        end, businessName)
    end, businessName)
end

--- Function to create circle zones for all configured businesses.
--- Each zone directly calls ShowReviewsMenu() when interacted with.
CreateThread(function()
    for index, business in pairs(Config.Businesses) do
        SD.Interaction.AddCircleZone(
            'target',
            "reviews_" .. index, 
            business.coords, 
            business.radius, 
            {
                options = {
                    {
                        label = locale('target.open_reviews_title'), 
                        icon = "fa-solid fa-comments", 
                        action = function()
                            ShowReviewsMenu(business.name)
                        end,
                        canInteract = function()
                            return true
                        end
                    }
                }
            }, 
            business.debug
        )
    end
end)