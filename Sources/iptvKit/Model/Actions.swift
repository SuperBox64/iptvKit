//
//  Actions.swift
//  iptvKit
//
//  Created by Todd Bruss on 9/27/21.
//


import Foundation

public enum Actions: String {
    case start = "start"
    case getLiveCategoriesAction = "get_live_categories"
    case getLiveStreams = "get_live_streams"
    case getshortEpg = "get_short_epg"
    case configAction = ""
    case getSeriesCategories = "get_series_categories"
    case getSeries = "get_series"
    case getSeriesInfo = "get_series_info"
    case getVodCategories = "get_vod_categories"
    case getVodStreams = "get_vod_streams"
    case getVodInfo = "get_vod_info"
    //http://etv.wstreamzone.com/player_api.php?username=U0YSV8YOCT&password=FU56KJYJJV&action=get_vod_categories
    
    //http://etv.wstreamzone.com/player_api.php?username=U0YSV8YOCT&password=FU56KJYJJV&action=get_vod_streams&category_id=1777
    
    //http://etv.wstreamzone.com/player_api.php?username=U0YSV8YOCT&password=FU56KJYJJV&action=get_vod_info&vod_id=444939
}

func getCategories() {
    let action = Actions.getLiveCategoriesAction.rawValue
    let endpoint = api.getEndpoint(creds, iptv, action)
    
    rest.getRequest(endpoint: endpoint) { (categories) in
        guard let categories = categories else {
            print("Error: Failed to get categories data")
            LoginObservable.shared.status = "Get Categories Error"
            setCurrentStep = .CategoriesError
            awaitDone = false
            return
        }
        
        do {
            let catz = try decoder.decode(Categories.self, from: categories)
            cats = catz
            for (i,cat) in catz.enumerated() {
                let nam = cat.categoryName.components(separatedBy: " ")
                var catName = ""
                
                for x in nam {
                    if x.count > 5 {
                        catName.append(contentsOf: x.localizedCapitalized)
                    } else {
                        catName.append(contentsOf: x)
                    }
                    catName += " "
                }
                cats[i].categoryName = catName
                cats[i].categoryName.removeLast()
            }
        } catch {
            print("Error decoding categories: \(error)")
            LoginObservable.shared.status = "Categories Decode Error"
            setCurrentStep = .CategoriesError
            awaitDone = false
        }
        
        //Adult channels are not allowed
        var newCats = [Category]()
        for cat in cats {
            if !cat.categoryName.lowercased().contains("adult") {
                newCats.append(cat)
            }
        }
        
        cats = newCats.sorted(by: { $0.categoryName > $1.categoryName })
        
        //if cats.count > 3 { cats.removeLast() }
        awaitDone = true
    }
}

func getConfig() {
    let action = Actions.configAction.rawValue
    let endpoint = api.getEndpoint(creds, iptv, action)
    
    func loginError(_ message: String = "Login Error") {
        print("Configuration error: \(message)")
        LoginObservable.shared.status = message
        setCurrentStep = .ConfigurationError
        awaitDone = false
    }
    
    rest.getRequest(endpoint: endpoint) { login in
        guard let login = login else {
            loginError("No configuration data received")
            return
        }
        
        do {
            let config = try decoder.decode(Configuration.self, from: login)
            
            //print(config)
            LoginObservable.shared.config = config
            LoginObservable.shared.password = config.userInfo.password
            LoginObservable.shared.username = config.userInfo.username
            LoginObservable.shared.port = config.serverInfo.port
            LoginObservable.shared.url = config.serverInfo.url
            saveUserDefaults()
            awaitDone = true
        } catch {
            print("Error decoding configuration: \(error)")
            loginError("Configuration decode error")
        }
    }
}

public func getShortEpg(streamId: Int, channelName: String, imageURL: String) {
    let action = Actions.getshortEpg.rawValue
    let endpoint = api.getEpgEndpoint(creds, iptv, action, streamId)
    
    rest.getRequest(endpoint: endpoint) { (programguide) in
        guard let programguide = programguide else {
            print("Error: Failed to get EPG data for stream ID: \(streamId)")
            LoginObservable.shared.status = "Get Short EPG Error"
            return
        }
        
        do {
            let epg = try decoder.decode(ShortIPTVEpg.self, from: programguide)
            shortEpg = epg
            PlayerObservable.plo.miniEpg = shortEpg?.epgListings ?? []
        } catch {
            print("Error decoding EPG data: \(error)")
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .keyNotFound(let key, let context):
                    print("Missing key: \(key.stringValue), context: \(context.debugDescription)")
                case .typeMismatch(let type, let context):
                    print("Type mismatch: expected \(type), context: \(context.debugDescription)")
                case .valueNotFound(let type, let context):
                    print("Value missing: expected \(type), context: \(context.debugDescription)")
                case .dataCorrupted(let context):
                    print("Data corrupted: \(context.debugDescription)")
                @unknown default:
                    print("Unknown decoding error: \(decodingError)")
                }
            }
        }
    }
}

func getChannels() {
    let action = Actions.getLiveStreams.rawValue
    let endpoint = api.getEndpoint(creds, iptv, action)
    
    //MARK: search channels to patch
    enum search: String, CaseIterable {
        case actionMaxEast       = "USA CINEMAX ACTION MAX EAST"
        case actionMax           = "USA CINEMAX ACTIONMAX"
        case starzWest           = "USA Starz West"
        case animalPlanetWest    = "USA Animal Planet West"
        case betWest             = "USA BET West"
        case coziTV              = "USA Cozi TV"
        case coziTVLHD           = "USA COZI TV LHD"
        case motorTrend          = "USA Motor Trend"
        case eWest               = "USA E! Entertainment West"
        case freeformWest        = "USA Freeform West"
        case fX                  = "USA FX"
        case westFX              = "USA FX West"
        case westFXX             = "USA FXX West"
        case syfyWest            = "USA Syfy West"
        case tlcWest             = "USA TLC West"
        case retroPlexWest       = "USA RetroPlex West"
        case foodNetworkWest     = "USA Food Network West"
        case tvLand              = "USA TVLand UHD"
        case hgtvWest            = "USA HGTV West"
        case smile               = "USA Smile Child"
        case foxSoul             = "USA FOX Soul"
        case starzEncoreEast     = "USA Starz Encore East"
        case showtimeEast        = "USA Showtime East"
    }
    
    enum display: String, CaseIterable {
        case actionMaxEast       = "Cinemax ActionMax East"
        case actionMax           = "Cinemax ActionMax"
        case starzWest           = "Starz West"
        case animalPlanetWest    = "Animal Planet West"
        case betWest             = "BET West"
        case coziTV              = "Cozi TV"
        case coziTVLHD           = "Cozi TV LHD"
        case motorTrend          = "Motor Trend"
        case eWest               = "E! West"
        case freeformWest        = "Freeform West"
        case fX                  = "FX"
        case westFX              = "FX West"
        case westFXX             = "FXX West"
        case syfyWest            = "Syfy West"
        case tlcWest             = "TLC West"
        case retroPlexWest       = "RetroPlex West"
        case foodNetworkWest     = "Food Network West"
        case tvLand              = "TVLand UHD"
        case hgtvWest            = "HGTV West"
        case smile               = "Smile"
        case foxSoul             = "FOX Soul"
        case starzEncoreEast     = "Starz Encore East"
        case showtimeEast        = "Showtime East"
    }
    
    enum ids: String, CaseIterable {
        case actionMaxEast       = "actionmaxwest.us"
        case actionMax           = "Actionmaxwest.us"
        case starzWest           = "starzwest.us"
        case animalPlanetWest    = "animalplanetwest.us"
        case betWest             = "betwest.us"
        case coziTV              = "cozitv.us"
        case coziTVLHD           = "Cozitv.us"
        case motorTrend          = "motortrend.it"
        case eWest               = "ewest.us"
        case freeformWest        = "freeformwest.us"
        case fX                  = "fx.us"
        case westFX              = "fxwest.us"
        case westFXX             = "fxxwest.us"
        case syfyWest            = "syfywest.us"
        case tlcWest             = "tlcwest.us"
        case retroPlexWest       = "retroplexwest.us"
        case foodNetworkWest     = "foodnetworkwest.us"
        case tvLand              = "tvlandeast.us"
        case hgtvWest            = "HGTVWest.us"
        case smile               = "smiletv.us"
        case foxSoul             = "foxsoul.us"
        case starzEncoreEast     = "starzencoreeast.us"
        case showtimeEast        = "showtimeeast.us"
    }
    
    if ids.allCases.count != search.allCases.count && search.allCases.count != display.allCases.count {
        print("Enumeration Error with allCases!")
        return
    }
    
    var filter = [String]()
    var idz = [String]()
    var disp = [String]()
    
    for channel in search.allCases {
        filter.append(channel.rawValue)
    }
    
    for dis in display.allCases {
        disp.append(dis.rawValue)
    }
    
    for ident in ids.allCases {
        idz.append(ident.rawValue.lowercased())
    }
    
    var epgChannelID = [String:[String]]()
    
    for (index,ident) in filter.enumerated() {
        epgChannelID[ident] = [disp[index],idz[index]]
    }
        
    let file = getDocumentsDirectory().appendingPathComponent("channels.dat")
    
    var channelsData = Data()
    
    let clearCache = Data()

    do {
        channelsData = try Data(contentsOf: file)
    } catch {
        print("Error reading channels cache: \(error)")
    }
    
    if channelsData.count == 0 {
        rest.getRequest(endpoint: endpoint) { data in
            guard let data = data else {
                print("Error: Failed to get channels data")
                LoginObservable.shared.status = "Get Live Streams Error"
                setCurrentStep = .ConfigurationError
                awaitDone = false
                return
            }
            
            do {
                try data.write(to: file)
            } catch {
                print("Error writing channels cache: \(error)")
            }

            do {
//                let jsonObject = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
//                print(jsonObject)
                
                ChannelsObservable.shared.chan = try decoder.decode(Channels.self, from: data).sorted { $0.name < $1.name }
                for (index, ch) in ChannelsObservable.shared.chan.enumerated() where filter.contains(ch.name) {
                    
                    if let first = epgChannelID[ChannelsObservable.shared.chan[index].name]?.first,
                       let last  = epgChannelID[ChannelsObservable.shared.chan[index].name]?.last {
                        ChannelsObservable.shared.chan[index].name = first
                        ChannelsObservable.shared.chan[index].epgChannelID = last
                    }
                }
                
            } catch {
                print("Error decoding channels data: \(error)")
                if let decodingError = error as? DecodingError {
                    switch decodingError {
                    case .keyNotFound(let key, let context):
                        print("Missing key: \(key.stringValue), context: \(context.debugDescription)")
                    case .typeMismatch(let type, let context):
                        print("Type mismatch: expected \(type), context: \(context.debugDescription)")
                    case .valueNotFound(let type, let context):
                        print("Value missing: expected \(type), context: \(context.debugDescription)")
                    case .dataCorrupted(let context):
                        print("Data corrupted: \(context.debugDescription)")
                    @unknown default:
                        print("Unknown decoding error: \(decodingError)")
                    }
                }
                try? clearCache.write(to: file)
                awaitDone = false
                LoginObservable.shared.status = "Get Streams Error"
                setCurrentStep = .ConfigurationError
            }
            
           // refreshNowPlayingEpg()
            
            awaitDone = true
            lock = false

        }
    } else {
        guard let data = channelsData as Data? else {
            try? clearCache.write(to: file)
            LoginObservable.shared.status = "Get Live Streams Error"
            setCurrentStep = .ConfigurationError
            awaitDone = false
            return
        }
                
        do {
            ChannelsObservable.shared.chan = try decoder.decode(Channels.self, from: data).sorted { $0.name < $1.name }
            for (index, ch) in ChannelsObservable.shared.chan.enumerated() where filter.contains(ch.name) {
                
                if let first = epgChannelID[ChannelsObservable.shared.chan[index].name]?.first,
                   let last  = epgChannelID[ChannelsObservable.shared.chan[index].name]?.last {
                    ChannelsObservable.shared.chan[index].name = first
                    ChannelsObservable.shared.chan[index].epgChannelID = last
                }
            }
            
            //refreshNowPlayingEpg()
            
            awaitDone = true
            lock = false
        } catch {
            
            try? clearCache.write(to: file)

            awaitDone = false
            LoginObservable.shared.status = "Get Streams Error"
            setCurrentStep = .ConfigurationError
            print(error)
        }
    }
}

public func refreshNowPlayingEpg() {
    DispatchQueue.global(qos: .background).async {
        getNowPlayingEpg()
    }
}

public func refreshNowPlayingEpgBytes() {
    DispatchQueue.global(qos: .background).async {
        getNowPlayingEpgBytes()
    }
}


public func getNowPlayingEpgBytes() {
    awaitDone = true
    lock = false
    //return
    
    let endpoint = api.getNowPlayingEndpointBytes()
    rest.getRequest(endpoint: endpoint) { (bytes) in
        guard let bytes = bytes else {
            LoginObservable.shared.status = "get bytes error"
            print("get bytes error")
            return
        }
        
        if let bytez = Int(String(decoding: bytes, as: UTF8.self)) {
            if bytez > 100000 && bytez != nowPlayingBytes {
                nowPlayingBytes = bytez
                refreshNowPlayingEpg()
            }
        }
    }
}

public func getNowPlayingEpg() {
    
//    if lock {
//        awaitDone = true
//        lock = false
//        return }
//    
//    lock = true
    
    LoginObservable.shared.status = "Mini IPTVee Guide"
    
    let endpoint = api.getNowPlayingEndpoint()
    
    rest.getRequest(endpoint: endpoint) { (programguide) in
        guard let programguide = programguide else {
            print("getNowPlayingEpg Error")
            awaitDone = true
            lock = false
            return
        }
        
        do {
            ChannelsObservable.shared.nowPlayingLive = try decoder.decode(NowPlaying.self, from: programguide)
        } catch {
            LoginObservable.shared.status = "Mini Guide Error"
            print(error)
        }
        
        awaitDone = true
        lock = false
    }
}

public func getVideoOnDemandSeries() {
    let action = Actions.getSeriesCategories.rawValue
    let endpoint = api.getEndpoint(creds, iptv, action)
    rest.getRequest(endpoint: endpoint) { (data) in
        
        guard let data = data else {
            print("Error: Failed to get video on demand series data")
            return
        }
        
        do {
            SeriesCatObservable.shared.seriesCat = try decoder.decode([SeriesCategory].self, from: data)
        } catch {
            print("Error decoding series categories: \(error)")
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .keyNotFound(let key, let context):
                    print("Missing key: \(key.stringValue), context: \(context.debugDescription)")
                case .typeMismatch(let type, let context):
                    print("Type mismatch: expected \(type), context: \(context.debugDescription)")
                case .valueNotFound(let type, let context):
                    print("Value missing: expected \(type), context: \(context.debugDescription)")
                case .dataCorrupted(let context):
                    print("Data corrupted: \(context.debugDescription)")
                @unknown default:
                    print("Unknown decoding error: \(decodingError)")
                }
            }
        }
    }
}

public func getVideoOnDemandSeriesItems(categoryID: String) {
    let action = Actions.getSeries.rawValue
    let endpoint = api.getTVSeriesEndpoint(creds, iptv, action, categoryID)
    rest.getRequest(endpoint: endpoint) { (data) in
        guard let data = data else {
            print("Error: Failed to get series items for category ID: \(categoryID)")
            return
        }
        
        do {
            SeriesTVObservable.shared.seriesTVShows = try decoder.decode([SeriesTVShow].self, from: data)
        } catch {
            print("Error decoding series items: \(error)")
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .keyNotFound(let key, let context):
                    print("Missing key: \(key.stringValue), context: \(context.debugDescription)")
                case .typeMismatch(let type, let context):
                    print("Type mismatch: expected \(type), context: \(context.debugDescription)")
                case .valueNotFound(let type, let context):
                    print("Value missing: expected \(type), context: \(context.debugDescription)")
                case .dataCorrupted(let context):
                    print("Data corrupted: \(context.debugDescription)")
                @unknown default:
                    print("Unknown decoding error: \(decodingError)")
                }
            }
        }
    }
}

public func getVideoOnDemandSeriesInfo(seriesID: String) {
    let action = Actions.getSeriesInfo.rawValue
    let endpoint = api.getTVSeriesInfoEndpoint(creds, iptv, action, seriesID)
    
    rest.getRequest(endpoint: endpoint) { data in
        guard let data = data else {
            print("Error: Failed to get series info for ID: \(seriesID)")
            return
        }
        
        do {
            let seriesTVShows = try decoder.decode(TVSeriesInfo.self, from: data)
            if let episodes = seriesTVShows.episodes {
                SeriesTVObservable.shared.episodes = episodes
            }
        } catch {
            print("Error decoding series info: \(error)")
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .keyNotFound(let key, let context):
                    print("Missing key: \(key.stringValue), context: \(context.debugDescription)")
                case .typeMismatch(let type, let context):
                    print("Type mismatch: expected \(type), context: \(context.debugDescription)")
                case .valueNotFound(let type, let context):
                    print("Value missing: expected \(type), context: \(context.debugDescription)")
                case .dataCorrupted(let context):
                    print("Data corrupted: \(context.debugDescription)")
                @unknown default:
                    print("Unknown decoding error: \(decodingError)")
                }
            }
        }
    }
}

public func getVideoOnDemandMovies() {
    let action = Actions.getVodCategories.rawValue
    let endpoint = api.getEndpoint(creds, iptv, action)
    rest.getRequest(endpoint: endpoint) { (data) in
        
        guard let data = data else {
            print("\(action) error")
            return
        }
        
        do {
            try MoviesCatObservable.shared.movieCat = decoder.decode([MovieCategory].self, from: data)
        } catch {
            print(error)
        }
    }
}

public func getVideoOnDemandMoviesItems(categoryID: String) {
    let action = Actions.getVodStreams.rawValue
    let endpoint = api.getTVSeriesEndpoint(creds, iptv, action, categoryID)
    rest.getRequest(endpoint: endpoint) { (data) in
        guard let data = data else {
            print("\(action) error")
            return
        }
        
        do {
            try MoviesObservable.shared.movieCatInfo = decoder.decode([MovieInfoElement].self, from: data)
        } catch {
            print(error)
        }
    }
}


public func mvp(search: String) -> String  {
    var str = "https://starplayrx.com/images/pleasestandby.png" //Please stand by
    do {
        let scheme = "http"
        let host = "api.themoviedb.org"
        let path = "/3/search/movie"
        let queryItemA = URLQueryItem(name: "api_key", value: "fcaa164488c826d694895a6a0d27f726")
        let queryItemB = URLQueryItem(name: "query", value: search)
        
        var urlComponents = URLComponents()
        urlComponents.scheme = scheme
        urlComponents.host = host
        urlComponents.path = path
        urlComponents.queryItems = [queryItemA,queryItemB]
        
        if let url = urlComponents.url {
            let data = try Data(contentsOf: url)
            if let moviePoster = try? decoder.decode(MoviePoster.self, from: data) {
                if let movp = moviePoster.results.first?.posterPath {
                    str = "http://image.tmdb.org/t/p/w400" + movp
                    return str
                }
            }
        }
    }
    catch {
        print(error)
    }
    return str
}

public func tvc(search: String) -> String  {
    var str = "https://starplayrx.com/images/pleasestandby.png" //Please stand by
    do {
        let scheme = "http"
        let host = "api.themoviedb.org"
        let path = "/3/search/tv"
        let queryItemA = URLQueryItem(name: "api_key", value: "fcaa164488c826d694895a6a0d27f726")
        let queryItemB = URLQueryItem(name: "query", value: search)
        
        var urlComponents = URLComponents()
        urlComponents.scheme = scheme
        urlComponents.host = host
        urlComponents.path = path
        urlComponents.queryItems = [queryItemA,queryItemB]
        
        if let url = urlComponents.url {
            let data = try Data(contentsOf: url)
            if let tvPoster = try? decoder.decode(TVPoster.self, from: data) {
                if let tvp = tvPoster.results.first?.posterPath {
                    str = "http://image.tmdb.org/t/p/w400" + tvp
                    return str
                }
            }
        }
    }
    catch {
        print(error)
    }
    return str
}

public extension String {
    func deletingPrefix(_ prefix: String) -> String {
        guard self.hasPrefix(prefix) else { return self }
        return String(self.dropFirst(prefix.count))
    }
}

func getDocumentsDirectory() -> URL {
    // find all possible documents directories for this user
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)

    // just send back the first one, which ought to be the only one
    return paths[0]
}
