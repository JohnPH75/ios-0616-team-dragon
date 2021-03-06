//
//  FinanceDataViewController.swift
//  ProgrammaticTabBar
//
//  Created by John Hussain on 8/7/16.
//  Copyright © 2016 John Hussain. All rights reserved.
//

import UIKit
import SnapKit

class FinanceDataViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    // MARK: - Properties
    
    var store = DataStore.sharedInstance
    
    var tabCityDataSets: [DataSetModel] = []
    var tabUSDataSets: [DataSetModel] = []
    
    
    var myArray = ["Median Income","Unemployment Rate","etc."]
    var comparisonData: ScoreModel?
    var percentageComparisonData: ScoreModel?
    let comparisonLabel = UILabel()
    var unemployment: String = ""
    let searchedLabel = UILabel()
    let currentLabel = UILabel()
    let yourCityLabel = UILabel()
    var dataArray = [String]()
    //var originArray = [String]()
    
    // MARK: - Loading UI Elements and View
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tabCityDataSets = self.tabSets(city: true, type: Hints.economy)
        self.tabUSDataSets = self.tabSets(city: false, type: Hints.economy)
        self.view.backgroundColor = UIColor(netHex:0xFFFFFF)
        self.comparisonData = self.store.comparisonData
        self.percentageComparisonData = self.store.comparisonPercentageData
        
        
        self.navBar()
        self.resultsTableView()
        //self.ratingTextView()
        self.comparisonTextView()
        self.currentLocationLabel()
        self.yourLocationLabel()
        self.searchedLocationLabel()
    }
    
    func tabSets(city city: Bool, type: String) -> [DataSetModel] {
        var sets: [DataSetModel] = []
        
        if city {
            sets = store.cityModel.dataSets.filter({ (dataSet) -> Bool in
                dataSet.type == type
            })
        } else {
            sets = store.usModel.dataSets.filter({ (dataSet) -> Bool in
                dataSet.type == type 
            })
        }
        
        for set in sets {
            for (index, value) in set.values.enumerate() {
                if value.name == Hints.total {
                    set.values.removeAtIndex(index)
                }
            }
        }
        for set in sets {
            set.values.sortInPlace({ (valueModel1, valueModel2) -> Bool in
                valueModel1.name < valueModel2.name
            })
        }
        return sets.sort({ (dataSetModel1, dataSetModel2) -> Bool in
            dataSetModel1.name < dataSetModel2.name
        })

    }
    
    // MARK: - Setup labels for tablview
    func currentLocationLabel() {
        
        view.addSubview(currentLabel)
        currentLabel.text = "National Average"
        currentLabel.textAlignment = .Left
        currentLabel.textColor = UIColor.blackColor()
        currentLabel.font = UIFont(name:"Helvetica Light", size:12)
        currentLabel.sendSubviewToBack(currentLabel)
        currentLabel.layer.masksToBounds = true
        currentLabel.frame = CGRectMake(15, 133, self.view.bounds.width * 0.5 - 20, 30)
    }
    
    func yourLocationLabel() {
        
        view.addSubview(yourCityLabel)
        yourCityLabel.text = "Current City"
        yourCityLabel.textColor = UIColor.blackColor()
        yourCityLabel.font = UIFont(name:"Helvetica Light", size:12)
        yourCityLabel.sendSubviewToBack(currentLabel)
        yourCityLabel.layer.masksToBounds = true
        yourCityLabel.frame = CGRectMake(self.view.frame.width * 0.75, 133, self.view.bounds.width * 0.5 - 20, 30)
    }
    
    func searchedLocationLabel() {
        
        view.addSubview(searchedLabel)
        searchedLabel.text = store.cityModel.name
        searchedLabel.textAlignment = .Right
        searchedLabel.textColor = UIColor.blackColor()
        searchedLabel.font = UIFont(name:"Helvetica Light", size:17)
        searchedLabel.sendSubviewToBack(searchedLabel)
        searchedLabel.layer.masksToBounds = true
        searchedLabel.frame = CGRectMake(self.view.bounds.width * 0.28, 75, self.view.bounds.width * 0.5 - 20, 30)
        searchedLabel.textAlignment = NSTextAlignment.Center
    }
    
    func ratingTextView() {
        let ratingLabel = UILabel()
        view.addSubview(ratingLabel)
        ratingLabel.text = "N/A"
        ratingLabel.backgroundColor = UIColor(netHex:0xFFFFFF)
        ratingLabel.textColor = UIColor.blackColor()
        ratingLabel.adjustsFontSizeToFitWidth = true
        ratingLabel.font = UIFont(name:"Helvetica Light", size:33)
        ratingLabel.sendSubviewToBack(ratingLabel)
        ratingLabel.layer.masksToBounds = true
        ratingLabel.textAlignment = NSTextAlignment.Center
        ratingLabel.snp_makeConstraints { (make) -> Void in
            make.left.equalTo(view).offset(10)
            make.top.equalTo(view).offset(110)
            make.width.equalTo(66)
            make.height.equalTo(66)
        }
    }
    
    func comparisonTextView() {
        
        
        view.addSubview(comparisonLabel)
        comparisonLabel.text = self.store.cityScoresByType[Hints.economy]
        if comparisonLabel.text == "Very Low"{comparisonLabel.textColor = UIColor(netHex: 0xF25C5C)}
        else if comparisonLabel.text == "Low"{comparisonLabel.textColor = UIColor(netHex: 0xF6A6A6)}
        else if comparisonLabel.text == "Average"{comparisonLabel.textColor = UIColor(netHex: 0xFFB34D)}
        else if comparisonLabel.text == "High"{comparisonLabel.textColor = UIColor(netHex: 0xA6F6AF)}
        else if comparisonLabel.text == "Very High"{comparisonLabel.textColor = UIColor(netHex: 0x6BF67B)}
        else {comparisonLabel.textColor = UIColor.blackColor()}
        comparisonLabel.backgroundColor = UIColor(netHex:0xFFFFFF)
        //comparisonLabel.textColor = UIColor.blackColor()
        comparisonLabel.adjustsFontSizeToFitWidth = true
        comparisonLabel.font = UIFont(name:"Helvetica Light", size:25)
        comparisonLabel.sendSubviewToBack(comparisonLabel)
        comparisonLabel.layer.masksToBounds = true
        comparisonLabel.textAlignment = NSTextAlignment.Center
        comparisonLabel.frame = CGRectMake(self.view.bounds.width * 0.28, 115, self.view.bounds.width * 0.5 - 20, 30)
    }
    
    func resultsTableView() {
        let tableView = UITableView(frame: view.bounds,
                                    style: UITableViewStyle.Grouped)
        tableView.delegate = self
        tableView.dataSource = self
        self.view.addSubview(tableView)
        tableView.frame.origin.y += 166
        tableView.frame.size.height = self.view.bounds.height - 206
        tableView.backgroundColor = UIColor(netHex:0xFFFFFF)
    }
    
    func tableView(tableView: UITableView,
                   heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 115
    }
    
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return tabCityDataSets.count
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tabCityDataSets[section].values.count
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return tabCityDataSets[section].name
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = SearchResultCell(style: .Default, reuseIdentifier: "myIdentifier")
        
        let usDataSet = self.tabUSDataSets[indexPath.section]
        let cityDataSet = self.tabCityDataSets[indexPath.section]
        let usValue = usDataSet.values[indexPath.row]
        let cityValue = cityDataSet.values[indexPath.row]
        
        var usValueToDisplay = usValue.absoluteValue
        var cityValueToDisplay = cityValue.absoluteValue
        if usDataSet.displayPercent { usValueToDisplay = usValue.percentValue }
        if cityDataSet.displayPercent { cityValueToDisplay = cityValue.percentValue }
        
        cell.resultLocationNameLabel.text = tabCityDataSets[indexPath.section].values[indexPath.row].name
        cell.resultLocationNameLabel.textColor = UIColor.blackColor()
        cell.resultLocationNameLabel.textAlignment = NSTextAlignment.Center
        cell.scoreLabel.text = usValueToDisplay
        cell.scoreLabel.textColor = UIColor.blackColor()
        cell.comparisonScoreLabel.text = cityValueToDisplay
        cell.comparisonScoreLabel.textColor = UIColor.blackColor()
        
        return cell
    }
    
    
//    func tableView(tableView: UITableView,
//                   numberOfRowsInSection section: Int) -> Int {
//        
//        guard let economicComparisonData = self.comparisonData?.getEconomicScore() else { fatalError() }
//        //return economicComparisonData.0
//        return economicComparisonData.1.count
//    
////        guard let economicComparisonData = else { fatalError() }
////        return economicComparisonData.1.keys.count
//    }
    
//    func tableView(tableView: UITableView,
//                   cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
//        let cell = SearchResultCell(style: UITableViewCellStyle.Default,
//                                    reuseIdentifier: "myIdentifier")
//        
//        if let economicComparisonData = self.comparisonData {
//            var economicComparisonDataMutable = economicComparisonData
//            print("----------------------")
//            //print(economicComparisonData)
//            var economicDataScore = economicComparisonDataMutable.getEconomicScore()
//            let economicDetails = economicDataScore.1
//            
//            var economicKeys =  Array(economicDetails.keys)
//        if let economicComparisonData = self.comparisonData {
//            var economicComparisonDataMutable = economicComparisonData
////            print("----------------------")
//            //print(economicComparisonData)
//            let economicDataScore = economicComparisonDataMutable.getEconomicScore()
//            let economicDetails = economicDataScore.1
//            
//            var economicKeys =  Array(economicDetails.keys)

//            print(economicKeys[indexPath.row])
//            print(economicKeys)
//            print("-------")
            //let economicScoreItem = economicKeys[indexPath.row]
//            print(economicScoreItem)

//            print("____________")
//            print(economicDetails[economicKeys[indexPath.row]])
//            print(economicKeys[indexPath.row])
//            print(economicKeys)
//            print("-------")
//            var economicScoreItem = economicKeys[indexPath.row]
//            print(economicScoreItem)
//            var newKey = economicKeys[indexPath.row]
//            var ecoScore = economicDetails[newKey]! / 10
//            cell.scoreLabel.text = String(ecoScore)
//            cell.scoreLabel.textColor = UIColor.blackColor()
//            cell.resultLocationNameLabel.text = String(economicKeys[indexPath.row])
//            //print(ecoData)
//            cell.resultLocationNameLabel.adjustsFontSizeToFitWidth = true
//            cell.selectionStyle = UITableViewCellSelectionStyle.None
//        }

//            cell.resultLocationNameLabel.text = String(economicKeys[indexPath.row])
            //print(ecoData)
//            cell.resultLocationNameLabel.adjustsFontSizeToFitWidth = true
//            cell.selectionStyle = UITableViewCellSelectionStyle.None
//        }
        //guard let economicComparisonData = self.comparisonData?.getEconomicScore() else { fatalError() }
        
        
        ///var keyDict: [String] = []
        
        
        
//        print("\(economicComparisonData.1)\n\n\n\n\n\n\n\n")
//        var newArray = economicComparisonData.1
//        let score = newArray.popLast()
//        let scoretext = score!.0
//        let scorenum = score!.1
//        print("SCORE -------------------- \(score)")
//        print(scorenum)
        //cell.comparisonScoreLabel.text = String(scorenum)
        //cell.comparisonScoreLabel.text = String(economicComparisonData.1[indexPath.row].1)
       //cell.resultLocationNameLabel.text = scoretext
//        cell.resultLocationNameLabel.adjustsFontSizeToFitWidth = true
//        cell.selectionStyle = UITableViewCellSelectionStyle.None
        
        
//        print("TABLE VIEW \(economicComparisonData)\n\n\n\n\n\n")
        
        //let economicDataKeys = economicComparisonData.1.keys
//        for i in economicDataKeys.enumerate() {
//            var key  = i.element
//            keyDict.append(key)
//            
//        }
        
 //       var economicKeys = economicComparisonData.1
   //     print(economicKeys)
        //let params = economicKeys.popFirst()
        //cell.resultLocationNameLabel.text = self.unemployment
  
        //cell.resultLocationNameLabel.text = params!.0
        
//        print(economicKeys.popFirst())
//        for (i, n) in economicKeys.enumerate() {
//            print(n)
//        }
        
        
       // cell.resultLocationNameLabel.text = economicDataKeys[keyDict[indexPath.row]]
//        if let comparisonData = self.comparisonData {
//            let economicFactors = comparisonData.economicScoreFactors
//            print("\n\n COMPARISON DATA \(comparisonData.economicScoreFactors)")
//            let originEconomicData = economicFactors["Median household income"]
//            let comparisonEconomicData = economicFactors["Median household income"]
//            print("\n\n ORIGIN ECONOMICDATA \(originEconomicData)")
//            print("\n\n COMPARISON ECONOMICDATA \(comparisonEconomicData)")
//        }
        
        
//        if let dataDict = self.comparisonData?.getEconomicScore() {
//            print("DATADICT \(dataDict.1)")
//            //self.unemployment = dataDict.1
//        }
//        
//        self.comparisonLabel.text = self.unemployment
        
        //self.unemployment.append(["Origin unemployed level"])
//        if let economicComparisonData = {
//            // = self.economicComparisonData.1[]!
//        }
        
//            self.economicScoreFactors["Comparison Median household income"] = originMedianHouseIncome
//            self.economicScoreFactors["Origin Median household income"] = originMedianHouseIncome
//            self.economicScoreFactors["Origin Poverty level"] = originPovertyLevel
//            self.economicScoreFactors["Origin unemployed level"] = originUnemployed

        ///self.comparisonLabel.text = self.comparisonData.economicScoreFactors["Comparison Median household income"]
       

//        if (indexPath.row % 2 == 0) {
//            cell.backgroundColor = UIColor.clearColor()
//        } else {
//            cell.backgroundColor = UIColor.clearColor()
//        }
//        return cell
//    }
    
    func pressedButton1(sender: UIButton) {
        print("Pressed Button 1")
    }
    
    func pressedButton2(sender: UIButton) {
        print("Pressed Button 2")
    }
    
//    func tableView(tableView: UITableView,
//                   didSelectRowAtIndexPath indexPath: NSIndexPath) {
//        print(myArray[indexPath.row])
//    }
    
    func navBar() {
        let financeNavBar = NavBar().setup()
        self.view.addSubview(financeNavBar)
        financeNavBar.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(view).offset(20)
            make.width.equalTo(view)
        }
        financeNavBar.barTintColor = UIColor(red:0.36, green:0.49, blue:0.55, alpha:1.0)
        
        let navItem = UINavigationItem(title: "Finance")
        let homeItem = UIBarButtonItem.init(title: "Home", style: .Done, target: nil, action: #selector(dismissView))
        homeItem.tintColor = UIColor(netHex:0xFFFFFF)
        navItem.leftBarButtonItem = homeItem
        financeNavBar.setItems([navItem], animated: false)
     
        
        let button: UIButton = UIButton(type: .Custom)
        //button.setImage(UIImage(named: "settings-4.png"), forState: UIControlState.Normal)
//        button.addTarget(self, action: #selector(settingButtonPushed), forControlEvents: UIControlEvents.TouchUpInside)
        button.frame = CGRectMake(3, 3, 25, 25)
        
        let barButton = UIBarButtonItem(customView: button)
        self.navigationItem.rightBarButtonItem = barButton
        navItem.rightBarButtonItem = barButton
    }
    
    func dismissView() {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
//    func settingButtonPushed() {
//        print("Settings Pushed")
//    }
}