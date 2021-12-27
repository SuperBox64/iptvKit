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
    
    rest.getRequest(endpoint: endpoint) {  (categories) in
        guard let categories = categories else {
            LoginObservable.shared.status = "Get Categories Error"
            setCurrentStep = .CategoriesError
            awaitDone = false
            return
        }
        
        if let catz = try? decoder.decode(Categories.self, from: categories) {
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
    
    func loginError() {
        LoginObservable.shared.status = "Login Error"
        setCurrentStep = .ConfigurationError
        awaitDone = false
    }
    
    rest.getRequest(endpoint: endpoint) { login in
        guard let login = login else {
            loginError()
            return
        }
        
        
        do {
            let config = try decoder.decode(Configuration.self, from: login)
            LoginObservable.shared.config = config
            LoginObservable.shared.password = config.userInfo.password
            LoginObservable.shared.username = config.userInfo.username
            LoginObservable.shared.port = config.serverInfo.port
            LoginObservable.shared.url = config.serverInfo.url
            saveUserDefaults()
            awaitDone = true
        } catch {
            print(error)
            loginError()
        }
        
    }
}

public func getShortEpg(streamId: Int, channelName: String, imageURL: String) {
    let action = Actions.getshortEpg.rawValue
    let endpoint = api.getEpgEndpoint(creds, iptv, action, streamId)
    
    rest.getRequest(endpoint: endpoint) { (programguide) in
        guard let programguide = programguide else {
            LoginObservable.shared.status = "Get Short EPG Error"
            return
        }
        
        let str = String(decoding: programguide, as: UTF8.self)
        
        do {
            let epg = try decoder.decode(ShortIPTVEpg.self, from: programguide)
            shortEpg = epg
            PlayerObservable.plo.miniEpg = shortEpg?.epgListings ?? []
            
            /*  DispatchQueue.global().async {
             if let url = URL(string: imageURL) {
             let data = try? Data(contentsOf: url)
             DispatchQueue.main.async {
             
             if let data = data, let image = UIImage(data: data), !channelName.isEmpty {
             setnowPlayingInfo(channelName: channelName, image: image)
             } else if !channelName.isEmpty {
             setnowPlayingInfo(channelName: channelName, image: nil)
             }
             }
             }
             } */
            
            
        } catch {
            print(error)
        }
        
    }
}

var channelData = Data()

func getChannels() {
    let action = Actions.getLiveStreams.rawValue
    let endpoint = api.getEndpoint(creds, iptv, action)
    
    rest.getRequest(endpoint: endpoint) { (data) in
        
        guard let data = data else {
            LoginObservable.shared.status = "Get Live Streams Error"
            setCurrentStep = .ConfigurationError
            awaitDone = false
            return
        }
        

        channelData = data
        getNowPlayingHelper()
    }
}


public func getNowPlayingHelper() {
    if let channels = try? decoder.decode(Channels.self, from: channelData) {
        ChannelsObservable.shared.chan = channels
        getNowPlayingEpg()
    }
}

public func loadTVGuideScreenX() {
    DispatchQueue.global(qos: .background).async {
        let catId = PlayerObservable.plo.previousCategoryID
        var badCount = 0
        var godCount = 0

        if !ChannelsObservable.shared.chan.isEmpty {
            for (index, ch) in ChannelsObservable.shared.chan.enumerated() where ch.categoryID == catId  {
                
               if
                   let nowplaying = Optional(NowPlayingLive),
                   let chid = ch.epgChannelID, let npl = nowplaying[chid]?.first,
                   let start = npl.start.toDate()?.toString(),
                   let stop = npl.stop.toDate()?.toString()
               {
                   ChannelsObservable.shared.chan[index].nowPlaying = start + " - " + stop + "\n" + npl.title
                   godCount += 1
               } else {
                   ChannelsObservable.shared.chan[index].nowPlaying = ""
                   badCount += 1
                   if badCount > 20 && godCount < 10 { break }
               }
           }
           
      
        }
    }
}

public func getNowPlayingEpg() {
    LoginObservable.shared.status = "Mini IPTVee Guide"
    
    let endpoint = api.getNowPlayingEndpoint()
    rest.getRequest(endpoint: endpoint) { (programguide) in
        guard let programguide = programguide else {
            print("getNowPlayingEpg Error")
            return
        }
        
        do {
            let nowPlaying = try decoder.decode(NowPlaying.self, from: programguide)
            NowPlayingLive = nowPlaying
            awaitDone = true
        } catch {
            print(error)
        }
    }
}

public func getVideoOnDemandSeries() {
    let action = Actions.getSeriesCategories.rawValue
    let endpoint = api.getEndpoint(creds, iptv, action)
    rest.getRequest(endpoint: endpoint) { (data) in
        
        guard let data = data else {
            print("\(action) error")
            return
        }
        
        print(data)
        
        if let seriesCategories = try? decoder.decode([SeriesCategory].self, from: data) {
            SeriesCatObservable.shared.seriesCat = seriesCategories
        }
    }
}

public func getVideoOnDemandSeriesItems(categoryID: String) {
    let action = Actions.getSeries.rawValue
    let endpoint = api.getTVSeriesEndpoint(creds, iptv, action, categoryID)
    
    rest.getRequest(endpoint: endpoint) { (data) in
        
        guard let data = data else {
            print("\(action) error")
            return
        }
        
        
        
        if let seriesTVShows = try? decoder.decode([SeriesTVShow].self, from: data) {
            SeriesTVObservable.shared.seriesTVShows = seriesTVShows
        }
    }
}

public func getVideoOnDemandSeriesInfo(seriesID: String) {
    let action = Actions.getSeriesInfo.rawValue
    let endpoint = api.getTVSeriesInfoEndpoint(creds, iptv, action, seriesID)
    
    rest.getRequest(endpoint: endpoint) { (data) in
        
        guard let data = data else {
            print("\(action) error")
            return
        }
        
        do {
            let seriesTVShows = try decoder.decode(TVSeriesInfo.self, from: data)
            let episodes = seriesTVShows.episodes
            SeriesTVObservable.shared.episodes = episodes!
            
        }
        catch {
            print(error)
            
            
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
        
        if let movieCategories = try? decoder.decode([MovieCategory].self, from: data) {
            MoviesCatObservable.shared.movieCat = movieCategories
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
        
        if let movieCategoryInfo = try? decoder.decode([MovieInfoElement].self, from: data) {
            MoviesObservable.shared.movieCatInfo = movieCategoryInfo
        }
    }
}

public func mvp(search: String) -> String  {
    var str = "http://starplayrx.com/images/pleasestandby.png" //Please stand by
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
    var str = "http://starplayrx.com/images/pleasestandby.png" //Please stand by
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
