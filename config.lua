Config = {}

SD.Locale.LoadLocale('en') -- Load the locale language, if available. You can change 'en' to any other available language in the locales folder.

--- Configuration for businesses where reviews can be accessed.
--- Each entry in this table should contain at least:
---   name: the business name
---   coords: a vector3 coordinate for the target
---   radius: how large the interaction zone is
---   debug: whether to enable debug drawing for the circle zone
Config.Businesses = {
    [1] = {
        name = "Bean Machine",
        coords = vector3(-627.20, 239.04, 82.07),
        radius = 2.0,
        debug = false
    }
    -- Add more businesses here as needed
}
