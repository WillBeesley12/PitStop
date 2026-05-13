//
//  CuisineAliases.swift
//  PitStop
//
//  Maps user-spoken cuisine words to Google Places `types` and name keywords.
//  Google's place types are coarse (e.g. "japanese_restaurant" covers ramen,
//  sushi, izakaya, etc.) so we expand a single spoken cuisine into all the
//  types AND name-keywords that should count as a match.
//

import Foundation

enum CuisineAliases {
    
    /// Maps a spoken cuisine to (Google place types, name keywords) that should match.
    /// Lowercase everything. Order doesn't matter — we just check membership.
    private static let map: [String: (types: [String], keywords: [String])] = [
        
        // MARK: - Asian
        
        "ramen":          (["japanese_restaurant", "ramen_restaurant", "noodle_shop"],                ["ramen", "noodle"]),
        "sushi":          (["japanese_restaurant", "sushi_restaurant"],                                ["sushi", "sashimi", "omakase"]),
        "japanese":       (["japanese_restaurant", "sushi_restaurant", "ramen_restaurant"],            ["japanese", "ramen", "sushi", "udon", "izakaya", "donburi", "tempura"]),
        "teriyaki":       (["japanese_restaurant"],                                                    ["teriyaki"]),
        "tempura":        (["japanese_restaurant"],                                                    ["tempura"]),
        "udon":           (["japanese_restaurant", "noodle_shop"],                                     ["udon", "soba"]),
        "poke":           (["seafood_restaurant", "hawaiian_restaurant"],                              ["poke", "poké"]),
        
        "chinese":        (["chinese_restaurant"],                                                     ["chinese", "dim sum", "szechuan", "sichuan", "cantonese", "hunan", "peking"]),
        "dim sum":        (["chinese_restaurant"],                                                     ["dim sum", "dimsum"]),
        "dumplings":      (["chinese_restaurant"],                                                     ["dumpling", "potsticker", "xiaolongbao", "soup dumpling"]),
        "chinese food":   (["chinese_restaurant"],                                                     ["chinese"]),
        
        "thai":           (["thai_restaurant"],                                                        ["thai", "pad thai", "tom yum", "tom kha", "curry"]),
        "vietnamese":     (["vietnamese_restaurant"],                                                  ["vietnamese", "pho", "banh mi", "bun"]),
        "pho":            (["vietnamese_restaurant"],                                                  ["pho"]),
        "banh mi":        (["vietnamese_restaurant", "sandwich_shop"],                                 ["banh mi"]),
        
        "korean":         (["korean_restaurant", "barbecue_restaurant"],                               ["korean", "kbbq", "k-bbq", "bibimbap", "bulgogi", "galbi"]),
        "korean bbq":     (["korean_restaurant", "barbecue_restaurant"],                               ["korean", "kbbq", "k-bbq"]),
        
        "indian":         (["indian_restaurant"],                                                      ["indian", "curry", "tandoori", "biryani", "naan", "masala"]),
        "curry":          (["indian_restaurant", "thai_restaurant"],                                   ["curry"]),
        "biryani":        (["indian_restaurant"],                                                      ["biryani"]),
        "pakistani":      (["pakistani_restaurant", "indian_restaurant"],                              ["pakistani", "halal"]),
        
        "filipino":       (["filipino_restaurant"],                                                    ["filipino", "lumpia", "adobo"]),
        "malaysian":      (["malaysian_restaurant", "asian_restaurant"],                               ["malaysian"]),
        "indonesian":     (["indonesian_restaurant", "asian_restaurant"],                              ["indonesian", "nasi"]),
        "singaporean":    (["asian_restaurant"],                                                       ["singapore", "hainan"]),
        "asian":          (["asian_restaurant", "japanese_restaurant", "chinese_restaurant", "thai_restaurant", "vietnamese_restaurant", "korean_restaurant"], ["asian", "noodle"]),
        
        // MARK: - American
        
        "burger":         (["hamburger_restaurant", "american_restaurant", "fast_food_restaurant"],   ["burger", "patty"]),
        "burgers":        (["hamburger_restaurant", "american_restaurant", "fast_food_restaurant"],   ["burger"]),
        "cheeseburger":   (["hamburger_restaurant", "fast_food_restaurant"],                           ["burger"]),
        
        "steak":          (["steak_house", "american_restaurant", "barbecue_restaurant"],              ["steak", "chophouse", "prime rib"]),
        "steakhouse":     (["steak_house"],                                                            ["steak", "chophouse"]),
        
        "bbq":            (["barbecue_restaurant", "american_restaurant"],                             ["bbq", "barbecue", "smokehouse", "brisket", "ribs"]),
        "barbecue":       (["barbecue_restaurant"],                                                    ["bbq", "barbecue", "smokehouse", "brisket"]),
        "ribs":           (["barbecue_restaurant"],                                                    ["ribs", "bbq", "barbecue"]),
        "brisket":        (["barbecue_restaurant"],                                                    ["brisket", "bbq", "smokehouse"]),
        
        "fried chicken":  (["chicken_restaurant", "fast_food_restaurant", "american_restaurant"],     ["fried chicken", "chicken", "wings", "tenders"]),
        "chicken":        (["chicken_restaurant", "fast_food_restaurant"],                             ["chicken", "wings", "tenders", "nuggets"]),
        "wings":          (["chicken_restaurant", "fast_food_restaurant", "bar_and_grill"],            ["wings", "buffalo", "hot wings"]),
        "chicken wings":  (["chicken_restaurant", "fast_food_restaurant"],                             ["wings", "chicken"]),
        "rotisserie":     (["chicken_restaurant", "american_restaurant"],                              ["rotisserie", "chicken"]),
        
        "american":       (["american_restaurant", "diner"],                                            ["american", "diner", "grill"]),
        "diner":          (["diner", "american_restaurant"],                                            ["diner"]),
        "comfort food":   (["american_restaurant", "diner"],                                            ["comfort", "diner", "home"]),
        "soul food":      (["american_restaurant", "southern_restaurant"],                              ["soul food", "southern"]),
        "southern":       (["southern_restaurant", "american_restaurant"],                              ["southern", "soul food"]),
        "cajun":          (["cajun_restaurant", "american_restaurant"],                                 ["cajun", "creole", "gumbo", "jambalaya"]),
        "creole":         (["cajun_restaurant"],                                                        ["creole", "cajun"]),
        
        // MARK: - Sandwiches & quick bites
        
        "sandwich":       (["sandwich_shop", "deli", "fast_food_restaurant"],                          ["sandwich", "sub", "deli", "panini", "hoagie", "grinder"]),
        "sandwiches":     (["sandwich_shop", "deli"],                                                  ["sandwich", "sub", "deli"]),
        "sub":            (["sandwich_shop"],                                                          ["sub", "sandwich", "hoagie"]),
        "subs":           (["sandwich_shop"],                                                          ["sub", "sandwich"]),
        "deli":           (["deli", "sandwich_shop"],                                                  ["deli", "sandwich", "pastrami"]),
        "panini":         (["sandwich_shop", "italian_restaurant", "cafe"],                            ["panini", "sandwich"]),
        "wrap":           (["sandwich_shop", "fast_food_restaurant"],                                  ["wrap"]),
        
        "hot dog":        (["fast_food_restaurant", "american_restaurant"],                            ["hot dog", "frankfurter", "weenie"]),
        "hotdog":         (["fast_food_restaurant"],                                                   ["hot dog", "hotdog"]),
        
        // MARK: - Pizza & Italian
        
        "italian":        (["italian_restaurant"],                                                     ["italian", "pasta", "trattoria", "ristorante", "osteria"]),
        "pizza":          (["pizza_restaurant", "italian_restaurant"],                                  ["pizza", "pizzeria", "slice"]),
        "pasta":          (["italian_restaurant"],                                                     ["pasta", "italian", "spaghetti", "lasagna", "ravioli"]),
        
        // MARK: - European
        
        "french":         (["french_restaurant"],                                                      ["french", "bistro", "brasserie", "patisserie"]),
        "bistro":         (["french_restaurant", "restaurant"],                                        ["bistro", "brasserie"]),
        "german":         (["german_restaurant"],                                                      ["german", "schnitzel", "bratwurst", "biergarten"]),
        "spanish":        (["spanish_restaurant", "tapas_restaurant"],                                 ["spanish", "tapas", "paella"]),
        "tapas":          (["tapas_restaurant", "spanish_restaurant"],                                 ["tapas"]),
        "british":        (["british_restaurant", "pub"],                                              ["british", "english", "pub", "fish and chips"]),
        "irish":          (["irish_pub", "pub"],                                                       ["irish", "pub"]),
        "pub":            (["pub", "bar_and_grill"],                                                   ["pub", "tavern", "alehouse"]),
        
        "greek":          (["greek_restaurant", "mediterranean_restaurant"],                            ["greek", "gyro", "souvlaki"]),
        "gyro":           (["greek_restaurant", "mediterranean_restaurant"],                            ["gyro", "souvlaki"]),
        "mediterranean":  (["mediterranean_restaurant", "middle_eastern_restaurant"],                   ["mediterranean", "kebab", "shawarma", "falafel", "hummus"]),
        "middle eastern": (["middle_eastern_restaurant", "mediterranean_restaurant"],                   ["middle eastern", "kebab", "shawarma", "falafel", "hummus"]),
        "lebanese":       (["lebanese_restaurant", "middle_eastern_restaurant"],                       ["lebanese", "shawarma", "kebab"]),
        "turkish":        (["turkish_restaurant", "middle_eastern_restaurant"],                        ["turkish", "kebab", "doner"]),
        "kebab":          (["middle_eastern_restaurant", "mediterranean_restaurant"],                  ["kebab", "shawarma"]),
        "shawarma":       (["middle_eastern_restaurant"],                                              ["shawarma", "kebab"]),
        "falafel":        (["middle_eastern_restaurant", "mediterranean_restaurant"],                  ["falafel"]),
        "persian":        (["persian_restaurant", "middle_eastern_restaurant"],                        ["persian", "iranian", "kebab"]),
        "iranian":        (["persian_restaurant"],                                                     ["persian", "iranian"]),
        "afghan":         (["afghan_restaurant", "middle_eastern_restaurant"],                         ["afghan", "kebab"]),
        "moroccan":       (["moroccan_restaurant", "mediterranean_restaurant"],                        ["moroccan", "tagine", "couscous"]),
        "ethiopian":      (["ethiopian_restaurant", "african_restaurant"],                             ["ethiopian", "injera"]),
        "african":        (["african_restaurant"],                                                     ["african"]),
        
        // MARK: - Latin American
        
        "mexican":        (["mexican_restaurant"],                                                     ["mexican", "taco", "burrito", "quesadilla", "enchilada"]),
        "tacos":          (["mexican_restaurant"],                                                     ["taco", "taqueria"]),
        "taco":           (["mexican_restaurant"],                                                     ["taco", "taqueria"]),
        "burrito":        (["mexican_restaurant", "fast_food_restaurant"],                             ["burrito", "mexican"]),
        "taqueria":       (["mexican_restaurant"],                                                     ["taqueria", "taco"]),
        "tex-mex":        (["mexican_restaurant"],                                                     ["tex-mex", "tex mex", "mexican"]),
        "latin":          (["latin_american_restaurant", "mexican_restaurant"],                        ["latin", "latino"]),
        "cuban":          (["cuban_restaurant", "latin_american_restaurant"],                          ["cuban", "ropa vieja"]),
        "peruvian":       (["peruvian_restaurant", "latin_american_restaurant"],                       ["peruvian", "ceviche", "lomo saltado"]),
        "brazilian":      (["brazilian_restaurant"],                                                   ["brazilian", "churrasco", "feijoada"]),
        "argentinian":    (["argentinian_restaurant", "steak_house"],                                  ["argentinian", "argentine", "asado"]),
        "salvadoran":     (["latin_american_restaurant"],                                              ["salvadoran", "pupusa"]),
        "colombian":      (["latin_american_restaurant"],                                              ["colombian", "arepa"]),
        "pupusa":         (["latin_american_restaurant"],                                              ["pupusa"]),
        
        // MARK: - Seafood
        
        "seafood":        (["seafood_restaurant"],                                                     ["seafood", "fish", "lobster", "crab", "oyster", "shrimp"]),
        "fish":           (["seafood_restaurant"],                                                     ["fish", "seafood"]),
        "lobster":        (["seafood_restaurant"],                                                     ["lobster"]),
        "oysters":        (["seafood_restaurant"],                                                     ["oyster", "raw bar"]),
        "fish and chips": (["seafood_restaurant", "british_restaurant"],                               ["fish and chips", "chippy"]),
        "sushi rolls":    (["sushi_restaurant", "japanese_restaurant"],                                ["sushi", "roll"]),
        "raw bar":        (["seafood_restaurant"],                                                     ["raw bar", "oyster"]),
        
        // MARK: - Dietary
        
        "vegan":          (["vegan_restaurant", "vegetarian_restaurant"],                              ["vegan", "plant"]),
        "vegetarian":     (["vegetarian_restaurant", "vegan_restaurant"],                              ["vegetarian", "vegan"]),
        "plant-based":    (["vegan_restaurant", "vegetarian_restaurant"],                              ["plant", "vegan", "vegetarian"]),
        "gluten-free":    (["restaurant"],                                                             ["gluten-free", "gluten free", "gf"]),
        "kosher":         (["restaurant"],                                                             ["kosher"]),
        "halal":          (["middle_eastern_restaurant", "pakistani_restaurant", "indian_restaurant"], ["halal"]),
        "healthy":        (["health_food_restaurant", "salad_shop", "vegetarian_restaurant"],          ["healthy", "salad", "fresh", "bowl"]),
        "salad":          (["salad_shop", "health_food_restaurant"],                                   ["salad", "bowl", "greens"]),
        "bowl":           (["health_food_restaurant", "vegetarian_restaurant"],                        ["bowl", "buddha bowl"]),
        
        // MARK: - Breakfast & cafe
        
        "breakfast":      (["breakfast_restaurant", "brunch_restaurant", "cafe", "diner"],             ["breakfast", "brunch", "pancake", "waffle", "eggs"]),
        "brunch":         (["brunch_restaurant", "breakfast_restaurant", "cafe"],                      ["brunch", "breakfast"]),
        "pancakes":       (["breakfast_restaurant", "diner"],                                          ["pancake", "flapjack"]),
        "waffles":        (["breakfast_restaurant", "diner"],                                          ["waffle"]),
        "bagel":          (["bagel_shop", "bakery", "cafe"],                                           ["bagel"]),
        "bagels":         (["bagel_shop", "bakery"],                                                   ["bagel"]),
        "donuts":         (["donut_shop", "bakery"],                                                   ["donut", "doughnut"]),
        "doughnuts":      (["donut_shop", "bakery"],                                                   ["doughnut", "donut"]),
        
        "coffee":         (["cafe", "coffee_shop"],                                                    ["coffee", "cafe", "espresso", "latte", "starbucks", "peets"]),
        "cafe":           (["cafe", "coffee_shop", "bakery"],                                          ["cafe", "coffee", "bakery"]),
        "tea":            (["cafe", "tea_house"],                                                      ["tea", "boba", "matcha", "bubble tea"]),
        "boba":           (["tea_house", "cafe"],                                                      ["boba", "bubble tea", "milk tea"]),
        "bubble tea":     (["tea_house", "cafe"],                                                      ["bubble tea", "boba", "milk tea"]),
        "smoothie":       (["juice_shop", "cafe"],                                                     ["smoothie", "juice", "shake"]),
        "juice":          (["juice_shop", "cafe"],                                                     ["juice", "smoothie"]),
        
        "bakery":         (["bakery", "cafe"],                                                         ["bakery", "pastry", "bread", "croissant"]),
        "pastry":         (["bakery", "cafe"],                                                         ["pastry", "bakery", "croissant", "danish"]),
        "bread":          (["bakery"],                                                                 ["bread", "bakery", "boulangerie"]),
        
        // MARK: - Dessert
        
        "dessert":        (["dessert_shop", "ice_cream_shop", "bakery"],                               ["dessert", "ice cream", "frozen yogurt", "gelato", "cake", "cupcake"]),
        "desserts":       (["dessert_shop", "ice_cream_shop", "bakery"],                               ["dessert", "sweet"]),
        "ice cream":      (["ice_cream_shop"],                                                         ["ice cream", "gelato", "creamery"]),
        "gelato":         (["ice_cream_shop"],                                                         ["gelato", "ice cream"]),
        "frozen yogurt":  (["ice_cream_shop"],                                                         ["frozen yogurt", "froyo"]),
        "froyo":          (["ice_cream_shop"],                                                         ["froyo", "frozen yogurt"]),
        "cupcakes":       (["bakery", "dessert_shop"],                                                 ["cupcake"]),
        "cake":           (["bakery", "dessert_shop"],                                                 ["cake", "bakery"]),
        "candy":          (["candy_store", "dessert_shop"],                                            ["candy", "chocolate", "sweet"]),
        "chocolate":      (["candy_store", "dessert_shop", "bakery"],                                  ["chocolate", "chocolatier"]),
        
        // MARK: - Fast food & casual
        
        "fast food":      (["fast_food_restaurant"],                                                   ["fast food"]),
        "drive-thru":     (["fast_food_restaurant"],                                                   ["drive-thru", "drive thru"]),
        "drive through":  (["fast_food_restaurant"],                                                   ["drive-thru", "drive through"]),
        
        // MARK: - Drinks / bars
        
        "bar":            (["bar", "pub", "bar_and_grill"],                                            ["bar", "tavern", "saloon"]),
        "cocktails":      (["bar", "wine_bar"],                                                        ["cocktail", "mixology", "lounge"]),
        "wine":           (["wine_bar"],                                                               ["wine", "winery"]),
        "beer":           (["bar", "pub", "brewery"],                                                  ["beer", "brewery", "ale", "pub"]),
        "brewery":        (["brewery", "bar"],                                                         ["brewery", "brewing", "taproom"]),
        "sports bar":     (["bar_and_grill", "sports_bar"],                                            ["sports bar", "pub"]),
        
        // MARK: - Misc
        
        "buffet":         (["buffet_restaurant"],                                                      ["buffet", "all you can eat"]),
        "all you can eat": (["buffet_restaurant"],                                                     ["buffet", "all you can eat"]),
        "fine dining":    (["fine_dining_restaurant"],                                                 ["fine dining", "tasting menu"]),
        "tasting menu":   (["fine_dining_restaurant"],                                                 ["tasting menu", "omakase", "prix fixe"]),
        "food court":     (["food_court"],                                                             ["food court"]),
        "food truck":     (["meal_takeaway"],                                                          ["food truck"]),
        "hawaiian":       (["hawaiian_restaurant"],                                                    ["hawaiian", "poke", "loco moco", "luau"]),
        "soup":           (["soup_restaurant", "restaurant"],                                          ["soup", "broth", "ramen", "pho"]),
        "noodles":        (["noodle_shop", "asian_restaurant"],                                        ["noodle", "ramen", "udon", "pho"]),
    ]
    
    /// Returns true if the place matches the requested cuisine.
    /// Checks both Google's `types` array and the place's name.
    /// Falls back to a generic substring search if the cuisine isn't in the map.
    static func matches(cuisine: String, placeTypes: [String], placeName: String) -> Bool {
        let cuisineLower = cuisine.lowercased().trimmingCharacters(in: .whitespaces)
        let typesLower = placeTypes.map { $0.lowercased() }
        let nameLower = placeName.lowercased()
        
        // Known cuisine: check the alias entry
        if let entry = map[cuisineLower] {
            // Match if any of the place's types matches one of the aliased types
            for aliasType in entry.types {
                if typesLower.contains(aliasType) { return true }
            }
            // Or if any keyword appears in the place's name
            for keyword in entry.keywords {
                if nameLower.contains(keyword) { return true }
            }
            return false
        }
        
        // Unknown cuisine: fall back to generic substring match
        if typesLower.contains(where: { $0.contains(cuisineLower) }) { return true }
        if nameLower.contains(cuisineLower) { return true }
        return false
    }
}
