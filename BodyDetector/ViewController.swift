//
//  ViewController.swift
//  BodyDetector
//
//  Created by daisy宝贝🍉 on 5/7/22.
//  Copyright © 2022 Shuting Wang. All rights reserved.
//

import RealmSwift
import Charts
import UIKit

class ViewController: UIViewController, ChartViewDelegate {

    @IBOutlet weak var ageInput: UITextField!
    @IBOutlet weak var heightInput: UITextField!
    @IBOutlet weak var weightInput: UITextField!
    @IBOutlet weak var refreshButtonn: UIButton!
    @IBOutlet weak var BMIprogress: UIProgressView!
    @IBOutlet weak var BMIlabel: UILabel!
    @IBOutlet weak var FATprogress: UIProgressView!
    @IBOutlet weak var FATlabel: UILabel!
    
    var bmiValue:Double = 20.0
    var fatValue:Double = 13.55
    
    var lineChart = LineChartView()
    
//    var realm: Realm!
    let realm = try! Realm()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // 键盘为数字键盘
        ageInput.keyboardType = UIKeyboardType.numberPad
        heightInput.keyboardType = UIKeyboardType.numberPad
        weightInput.keyboardType = UIKeyboardType.numberPad
        // 点任何地方取消键盘
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        // progress bar UI transform
        BMIprogress.transform = BMIprogress.transform.scaledBy(x: 1, y: 10)
        FATprogress.transform = FATprogress.transform.scaledBy(x: 1, y: 10)
        BMIprogress.progress  = Float(bmiProgress(bmi: bmiValue))
        FATprogress.progress = Float(fatProgress(fat: fatValue, age: Double(25.0)))
        
        realm.beginWrite()
        realm.deleteAll()
        try! realm.commitWrite()
        
        
        // 体重图
        lineChart.delegate = self
        
        
    }
    
    // 画体重图
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        lineChart.frame = CGRect(x: 40, y: 628, width: self.view.frame.size.width * 0.8, height: self.view.frame.size.width * 0.58)
        
//        lineChart.center = view.center
        
        view.addSubview(lineChart)
        
        
        let weights = try! realm.objects(WeightObj1.self)
        var entries = [ChartDataEntry]()
        var dates = [String]()
        
        if (weights.count == 0) {
            for x in 1..<11 {
                entries.append(ChartDataEntry(x:Double(x), y:Double(61-x)))
                dates.append("2022-05-" + String(x))
            }
        } else {
            for weight in weights {
                entries.append(ChartDataEntry(x:Double(weight.myDate), y:Double(weight.myWeight)))
//                dates.append(weight.myDate)
            }
        }
        

        let set = LineChartDataSet(entries:entries)
        set.colors = ChartColorTemplates.material()
        let data = LineChartData(dataSet:set)
        lineChart.data = data

        lineChart.xAxis.valueFormatter = IndexAxisValueFormatter(values: dates)
        lineChart.xAxis.avoidFirstLastClippingEnabled = true
        
    }
    
    
    
    // 专门取消键盘
    @objc func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    // 按按钮
    @IBAction func calculate(_ sender: UIButton) {
        self.dismissKeyboard()
        let dialogMessage = UIAlertController(title: "Confirm", message: "Fill in Blanks pls", preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
           print("Ok button tapped")
        })
        
        dialogMessage.addAction(ok)
        if (ageInput.text == "" || ageInput.text == "0" ) {
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        if (heightInput.text == "" || heightInput.text == "0") {
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        if (weightInput.text == "" || weightInput.text == "0") {
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        let weight = Int(weightInput.text!)!
        let height = Int(heightInput.text!)!
        let bmiValue = bmi(weight: weight, height: height)
        let fatValue = fatPercentage(bmi: bmiValue, age: Double(ageInput.text!)!)
        BMIlabel.text = "BMI: " + String(bmiValue)
        FATlabel.text = "Body Fat Percentage: " + String(fatValue) + "%"
        BMIprogress.progress  = Float(bmiProgress(bmi: bmiValue))
        FATprogress.progress = Float(fatProgress(fat: fatValue, age: Double(ageInput.text!)!))
        
//        let formatter = DateFormatter()
//        formatter.dateFormat = "yyyy-MM-dd"
//        let someDateTime = formatter.date(from: "2016/10/08 22:31")
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        print(dateFormatter.string(from: date))
        let man = WeightObj1()
        man.myWeight = Double(weight)
        man.myFat = fatValue
        man.myDate = date.timeIntervalSince1970
        realm.beginWrite()
        realm.add(man)
        try! realm.commitWrite()
        render()
        
        
    }
    
    func render() {
        let weights = try! realm.objects(WeightObj1.self)
        var entries = [ChartDataEntry]()
        var dates = [String]()
        
        
        for weight in weights {
            entries.append(ChartDataEntry(x:Double(weight.myDate), y:Double(weight.myWeight)))
        }

        let set = LineChartDataSet(entries:entries)
        set.colors = ChartColorTemplates.material()
        let data = LineChartData(dataSet:set)
        lineChart.data = data

        lineChart.xAxis.valueFormatter = IndexAxisValueFormatter(values: dates)
        lineChart.xAxis.avoidFirstLastClippingEnabled = true
    }
    
    // 计算bmi
    func bmi(weight:Int, height:Int) -> Double {
        let newHeight = height / 100
        return round(Double(weight / (newHeight^2)) * 10) / 10.0
    }
    
    func bmiProgress(bmi:Double) -> Double {
        var res: Double
        if (bmi < 18) {
            res = 0.45 / 6 * (bmi - 12)
        } else if (bmi < 24) {
            res = 0.45 + 0.1 / 6 * (bmi - 18)
        } else if (bmi < 29) {
            res = 0.55 + 0.25 / 5 * (bmi - 24)
        } else {
            res = 0.75 + 0.25 / 10 * (bmi - 29)
        }
        return res
    }
    
    // 计算脂肪
    func fatPercentage(bmi:Double, age:Double) -> Double {
        let res = (1.20 * bmi) + (0.23 * age) - 16.2
        return round(res * 100) / 100.0
    }
    
    func fatProgress(fat:Double, age: Double) -> Double {
        var res: Double
        if (age < 40) {
            res = 0.04 * fat
        } else if (age < 60) {
            res = 0.035 * fat
        } else {
            res = 0.03 * fat
        }
        return res
    }

}

class WeightObj: Object {
    @objc dynamic var myWeight: Double = 0.00
    @objc dynamic var myDate: String = ""
    @objc dynamic var myFat: Double = 0.00
}

class WeightObj1: Object {
    @objc dynamic var myWeight: Double = 0.00
    @objc dynamic var myDate: Double = 0.00
    @objc dynamic var myFat: Double = 0.00
}
