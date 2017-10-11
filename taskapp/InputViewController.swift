//
//  InputViewController.swift
//  taskapp
//
//  Created by 濱田 一 on 2017/10/05.
//  Copyright © 2017年 濱田 一. All rights reserved.
//

import UIKit
import RealmSwift
import UserNotifications

class InputViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {

    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var contentsTextView: UITextView!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var categoryPicker: UIPickerView! // ★★

    var task: Task!
    let realm = try! Realm()
    
    // カテゴリが格納されるリスト ★★
    var categoryArray = try! Realm().objects(Category.self).sorted(byKeyPath: "id", ascending: true)
    
    // 選択されたカテゴリ名が入る変数 ★★
    var selectedCategoryTitle = ""
    
    // カテゴリ作成画面に行く時にセットするフラグ
    var categoryViewFlag = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        // 背景をタップしたらdismissKeyboardメソッドを呼ぶように設定する
        let tapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action:#selector(dismissKeyboard))
        self.view.addGestureRecognizer(tapGesture)
        
        categoryPicker.delegate = self;
        categoryPicker.dataSource = self;
        
        titleTextField.text = task.title
        contentsTextView.text = task.contents
        datePicker.date = task.date as Date
        
    }
    
    func dismissKeyboard(){
        // キーボードを閉じる
        view.endEditing(true)
    }

    // UIPickerViewの列の数 ★★
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    // UIPickerViewの行数 ★★
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return categoryArray.count
    }
    
    // UIPickerViewの最初の表示 ★★
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return categoryArray[row].title
    }
    
    // UIPickerViewのRowが選択された時の挙動 ★★
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.selectedCategoryTitle = self.categoryArray[row].title
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillDisappear(_ animated: Bool) {

        if !categoryViewFlag {
            try! realm.write {
                self.task.title = self.titleTextField.text!
                self.task.category?.title = self.selectedCategoryTitle // ★★
                self.task.contents = self.contentsTextView.text
                self.task.date = self.datePicker.date as NSDate
                self.realm.add(self.task, update: true)
            }
        }
        
        setNotification(task: task)
        
        super.viewWillDisappear(animated)
    }
    
    // segueで画面遷移する時に呼ばれる ★★
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let categoryViewController:CategoryViewController = segue.destination as! CategoryViewController
        let category = Category()
        
        if categoryArray.count != 0 {
            category.id = categoryArray.max(ofProperty: "id")! + 1
        }
        
        categoryViewController.category = category

        categoryViewFlag = true
    }
    
    // カテゴリ入力画面からもどってきた時にPickerを更新する ★★
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        categoryPicker.reloadAllComponents()
        categoryViewFlag = false
    }
    


    func setNotification(task: Task){
        let content = UNMutableNotificationContent()
        content.title = task.title
        content.body = task.contents    // bodyが空だと音しか出ない
        content.sound = UNNotificationSound.default()
        
        // ローカル通知が発動するtrigger(日付マッチ)を作成
        let calendar = NSCalendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: task.date as Date)
        let trigger = UNCalendarNotificationTrigger.init(dateMatching: dateComponents, repeats: false)
        
 
    
        // identifier, content, triggerからローカル通知を作成(identifierが同じだとローカル通知を上書き保存)
        let request = UNNotificationRequest.init(identifier: String(task.id), content: content, trigger: trigger)
        
        // ローカル通知を登録
        let center = UNUserNotificationCenter.current()
        center.add(request) {(error) in
            print(error ?? "ローカル通知登録 OK") // errorがnilならローカル通知の登録に成功したと表示、errorが存在すればerrorを表示
        }
        
        // 未通知のローカル通知一覧をログ出力
        center.getPendingNotificationRequests { (requests: [UNNotificationRequest]) in
            for request in requests {
                print("/---------------")
                print(request)
                print("---------------/")
            }
        }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    }
}
