//
//  File.swift
//  
//
//  Created by Todd Bruss on 9/26/21.
//

import Foundation

func endpoint(_ creds: Credentials, iptv: IPTV, actn: String) -> URLComponents {
    var endpoint = URLComponents()
    
    endpoint.scheme = iptv.scheme
    endpoint.host = iptv.host
    endpoint.port = iptv.port
    endpoint.path = iptv.path
    
    endpoint.queryItems = [
        URLQueryItem(name: "username", value: creds.username),
        URLQueryItem(name: "password", value: creds.password),
        URLQueryItem(name: "action", value: actn)
    ]
    
    return endpoint
}

func epgEndpoint(_ creds: Credentials, iptv: IPTV, actn: String, streamId: Int) -> URLComponents {
    var epgEndpoint = URLComponents()
    
    epgEndpoint.scheme = iptv.scheme
    epgEndpoint.host = iptv.host
    epgEndpoint.port = iptv.port
    epgEndpoint.path = iptv.path

    epgEndpoint.queryItems = [
        URLQueryItem(name: "username", value: creds.username),
        URLQueryItem(name: "password", value: creds.password),
        URLQueryItem(name: "action", value: actn),
        URLQueryItem(name: "stream_id", value: "\(streamId)")
    ]
    
    return epgEndpoint
}

func tvSeriesEndpoint(_ creds: Credentials, iptv: IPTV, actn: String, categoryID: String) -> URLComponents {
    var epgEndpoint = URLComponents()
    
    epgEndpoint.scheme = iptv.scheme
    epgEndpoint.host = iptv.host
    epgEndpoint.port = iptv.port
    epgEndpoint.path = iptv.path

    epgEndpoint.queryItems = [
        URLQueryItem(name: "username", value: creds.username),
        URLQueryItem(name: "password", value: creds.password),
        URLQueryItem(name: "action", value: actn),
        URLQueryItem(name: "category_id", value: "\(categoryID)")
    ]
    
    return epgEndpoint
}


func tvSeriesInfoEndpoint(_ creds: Credentials, iptv: IPTV, actn: String, seriesID: String) -> URLComponents {
    var epgEndpoint = URLComponents()
    
    epgEndpoint.scheme = iptv.scheme
    epgEndpoint.host = iptv.host
    epgEndpoint.port = iptv.port
    epgEndpoint.path = iptv.path

    epgEndpoint.queryItems = [
        URLQueryItem(name: "username", value: creds.username),
        URLQueryItem(name: "password", value: creds.password),
        URLQueryItem(name: "action", value: actn),
        URLQueryItem(name: "series_id", value: "\(seriesID)")
    ]
    
    return epgEndpoint
}

func movieInfoEndpoint(_ creds: Credentials, iptv: IPTV, actn: String, vodID: String) -> URLComponents {
    var epgEndpoint = URLComponents()
    
    epgEndpoint.scheme = iptv.scheme
    epgEndpoint.host = iptv.host
    epgEndpoint.port = iptv.port
    epgEndpoint.path = iptv.path

    epgEndpoint.queryItems = [
        URLQueryItem(name: "username", value: creds.username),
        URLQueryItem(name: "password", value: creds.password),
        URLQueryItem(name: "action", value: actn),
        URLQueryItem(name: "vod_id", value: "\(vodID)")
    ]
    
    return epgEndpoint
}



func nowPlayingEndpoint(path: String) -> URLComponents {
    var epgEndpoint = URLComponents()
    
    epgEndpoint.scheme = "http"
    epgEndpoint.host = "www.starplayrx.com"
    epgEndpoint.port = 9999
    epgEndpoint.path = path
    
    return epgEndpoint
}
