//
//  File.swift
//  
//
//  Created by M1 on 10/14/21.
//

import Foundation

public let api = Api()

public var lock = false
public var nowPlayingBytes = -1

public var creds = Creds (
    username: "",
    password: ""
)

public var iptv = IPTV (
    scheme: "http",
    host: "",
    path: "/player_api.php",
    port: 826) 

public let rest = Rest()
public let decoder = JSONDecoder()
public var cats: Categories = Categories()
public var conf: Configuration? = nil
public var chan: Channels = Channels()
public var shortEpg: iptvShortEpg? = nil
public let userSettings = "userSettings2022"
public let userSwitches = "userSwitches"

public func saveUserDefaults() {
    UserDefaults.standard.set(try? PropertyListEncoder().encode(LoginObservable.shared.config), forKey:userSettings)
}

public class CurrentDevice {
    public static let shared = CurrentDevice()
}
