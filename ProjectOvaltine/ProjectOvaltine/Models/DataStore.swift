//
//  CitySDKDataStore.swift
//  ProjectOvaltine
//
//  Created by Christopher Webb-Orenstein on 8/5/16.
//  Copyright © 2016 Christopher Webb-Orenstein. All rights reserved.
//

import Foundation

class DataStore {
    static let sharedInstance = DataStore()
    
    let cityAPI = CitySDKAPIClient.sharedInstance
    let govDataAPI = GovDataAPIClient.sharedInstance
    let laborStatisticsAPI = LaborStatisticsAPIClient.sharedInstance
    let USAJobsAPI = USAJobsAPIClient.sharedInstance
    
    var cityDataPoints:[citySDKData] = []
    var laborDataPoints:[LaborStatisticsData] = []
    var USAJobsDataPoints:[USAJobsData] = []
    
    
    func getCitySDKData(name: String, completion: () -> ()) {
        cityAPI.sendAPIRequest("county", zip: "10001", api: "acs5", year: "2014") { (cityData) in
            self.cityDataPoints = cityData
            completion()
        }
    }
}