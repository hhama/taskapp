//
//  ViewController.swift
//  taskapp
//
//  Created by 濱田 一 on 2017/10/05.
//  Copyright © 2017年 濱田 一. All rights reserved.
//

import UIKit
import RealmSwift
import UserNotifications

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource,  UIPickerViewDelegate, UIPickerViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var categoryPicker: UIPickerView!

    
    let realm = try! Realm()
    
    // DB内のタスクが格納されるリスト
    // 日付の近い順でソート:降順
    // 以降内容をアップデートするとリスト内は自動的に更新される
    var taskArray = try! Realm().objects(Task.self).sorted(byKeyPath: "date", ascending: false)

    // カテゴリが格納されるリスト ★★
    var categoryArray = try! Realm().objects(Category.self).sorted(byKeyPath: "id", ascending: true)
    var categoryNameArray:[String] = []
    
    var displayTaskArray:Results<Task>? // ★
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        tableView.delegate = self
        tableView.dataSource = self
        
        categoryPicker.delegate = self // ★★
        categoryPicker.dataSource = self; // ★★
        
        displayTaskArray = taskArray // ★
        // categoryNameArrayをcategoryArrayから作成 ★★
        categoryNameArray.append("")
        for cat in categoryArray {
            categoryNameArray.append(cat.title)
        }
        categoryPicker.selectRow(0, inComponent: 0, animated: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // UIPickerViewの列の数 ★★
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    // UIPickerViewの行数 ★★
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return categoryNameArray.count
    }

    // UIPickerViewの最初の表示 ★★
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return categoryNameArray[row]
    }

    // UIPickerViewのRowが選択された時の挙動 ★★
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        // categoryで絞り込み
        if row == 0 {
            displayTaskArray = taskArray
        } else {
            // let predicate = NSPredicate(format: "category_id == %@", row)
            // displayTaskArray = realm.objects(Task.self).filter(predicate)
            displayTaskArray = realm.objects(Task.self).filter("category_id == %@", row - 1).sorted(byKeyPath: "date", ascending: false)
        }
        
        // テーブルの再表示
        tableView.reloadData()
    }
    
    

    // MARK: UITableViewDataSourceプロトコルのメソッド
    // データの数(=セルの数)を返すメソッド
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayTaskArray!.count + 1 // ★
    }

    // 各セルの内容を返すメソッド
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        // 再利用可能なcellを得る
        let cell =
            tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath as IndexPath)
        
        if indexPath.row == displayTaskArray!.count { // ★(最終行は検索結果数の表示)
            cell.textLabel?.textColor = UIColor.lightGray
            cell.textLabel?.text = "\(displayTaskArray!.count)件"
            cell.selectionStyle = .none // セルを選択不可能にする
            cell.detailTextLabel?.text = ""
        } else {
        
            // Cellに値を設定する
            let task = displayTaskArray?[indexPath.row] // ★
            cell.textLabel?.text = task!.title

            // ここから課題で追加
            // 表示色の設定
            cell.textLabel?.textColor = UIColor.black
            // print("(task?.category_id )! ... \((task?.category_id )!)")
            cell.textLabel?.text = (cell.textLabel?.text)! + " [\(categoryNameArray[(task?.category_id )! + 1])]"
            // ここまで
        
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm"
            
            let dateString:String = formatter.string(from: task!.date as Date)
            cell.detailTextLabel?.text = dateString
        }
        
        return cell
    }
    
    // MARK: UITableViewDelagateプロトコルのメソッド
    // 各セルを選択した時に実行されるメソッド
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        performSegue(withIdentifier: "cellSegue", sender: nil)
    }
    
    // セルが削除が可能なことを伝えるメソッド
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return UITableViewCellEditingStyle.delete
    }
    
    // Deleteボタンが押された時に呼ばれるメソッド
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath){
        if editingStyle == UITableViewCellEditingStyle.delete{
            
            // 削除されたタスクを取得する
            let task = self.displayTaskArray?[indexPath.row]// ★
            
            // ローカル通知をキャンセルする
            let center = UNUserNotificationCenter.current()
            center.removePendingNotificationRequests(withIdentifiers: [String(task!.id)])
            
            // データベースから削除する
            try! realm.write{
                self.realm.delete(task!)
                tableView.deleteRows(at: [indexPath as IndexPath], with: UITableViewRowAnimation.fade)
            }
            
            // 画面の再表示★
            tableView.reloadData()

            
            // 未通知のローカル通知の一覧をログ出力
            center.getPendingNotificationRequests { (requests: [UNNotificationRequest]) in
                for request in requests {
                    print("/--------------")
                    print(request)
                    print("--------------/")
                }
            }
        }
    }
    
    // segueで画面遷移する時に呼ばれる
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let inputViewController:InputViewController = segue.destination as! InputViewController
        
        if segue.identifier == "cellSegue" {
            let indexPath = self.tableView.indexPathForSelectedRow
            inputViewController.task = displayTaskArray?[indexPath!.row] // ★
        } else {
            let task = Task()
            task.date = NSDate()
            
            if taskArray.count != 0 {
                task.id = taskArray.max(ofProperty: "id")! + 1
            }
            
            inputViewController.task = task
        }
            
    }
    
    // 入力画面からもどってきた時にTableViewを更新させる
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
}

