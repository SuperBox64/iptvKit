//
//  File.swift
//  
//
//  Created by M1 on 11/22/21.
//

import Foundation

// MARK: - SeriesTVShow
public struct TVSeriesInfo: Codable {
    public let info: SeriesTVShowInfo?
    public let episodes: [String: [Episode]]?
    
    // MARK: - Episode
    public struct Episode: Codable {
        public let id: String
        public let episodeNum: SuperInt
        public let title: String
        public let containerExtension: String
        public let info: EpisodeInfo
        public let added: String
        public let season: Int
        public let uuid: UUID = UUID()
        
        enum CodingKeys: String, CodingKey {
            case id = "id"
            case episodeNum = "episode_num"
            case title = "title"
            case containerExtension = "container_extension"
            case info = "info"
            case added = "added"
            case season = "season"
        }
    }
    
    enum ContainerExtension: String, Codable {
        case mkv = "mkv"
    }
    
    // MARK: - EpisodeInfo
    public struct EpisodeInfo: Codable {
        public let durationSecs: Int
        public let duration: String
        public let bitrate: Int
        
        enum CodingKeys: String, CodingKey {
            case durationSecs = "duration_secs"
            case duration = "duration"
            case bitrate = "bitrate"
        }
    }
    
    // MARK: - SeriesTVShowInfo
    public struct SeriesTVShowInfo: Codable {
        public let name: String
        public let cover: String
        public let plot: String?
        public let cast: String?
        public let director: String?
        public let genre: String?
        public let releaseDate: String?
        public let lastModified: String?
        public let rating: String?
        public let rating5Based: Double?
        public let episodeRunTime: String?
        public let categoryID: String
        
        enum CodingKeys: String, CodingKey {
            case name = "name"
            case cover = "cover"
            case plot = "plot"
            case cast = "cast"
            case director = "director"
            case genre = "genre"
            case releaseDate = "releaseDate"
            case lastModified = "last_modified"
            case rating = "rating"
            case rating5Based = "rating_5based"
            case episodeRunTime = "episode_run_time"
            case categoryID = "category_id"
        }
    }
}

public enum StringInt: Codable {
    case integer(Int)
    case string(String)
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let int1 = try? container.decode(Int.self) {
            self = .integer(int1)
            return
        } else if let str1 = try? container.decode(String.self) {
            self = .string(str1)
            return
        }
        
        throw DecodingError.typeMismatch(StringInt.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for StringInt"))
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .integer(let x):
            try container.encode(x)
        case .string(let x):
            try container.encode(x)
        }

    }
}
