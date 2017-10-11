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

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var categorySearchBar: UISearchBar!
    
    let realm = try! Realm()
    
    // DB内のタスクが格納されるリスト
    // 日付の近い順でソート:降順
    // 以降内容をアップデートするとリスト内は自動的に更新される
    var taskArray = try! Realm().objects(Task.self).sorted(byKeyPath: "date", ascending: false)

    // カテゴリが格納されるリスト ★★
    var categoryArray = try! Realm().objects(Category.self).sorted(byKeyPath: "id", ascending: true)
    
    var displayTaskArray:Results<Task>? // ★
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        tableView.delegate = self
        tableView.dataSource = self
        
        categorySearchBar.delegate = self // ★
        
        displayTaskArray = taskArray // ★
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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

            if task!.category?.title != nil{
                cell.textLabel?.text = (cell.textLabel?.text)! + " [\(task!.category?.title ?? "")]"
            }
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
    
    // 以下、課題で追加
    // サーチバーで検索ボタンが押された時の処理
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        // キーボードを閉じる
        searchBar.resignFirstResponder()
        
        // categoryで絞り込み
        let predicate = NSPredicate(format: "category.title CONTAINS %@", searchBar.text!)
        displayTaskArray = realm.objects(Task.self).filter(predicate)
        
        // テーブルの再表示
        tableView.reloadData()
    }
    
    // サーチバーのキャンセルボタンが押された時の処理
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        // サーチバーの中身を空にする
        searchBar.text = ""
        
        // キーボードを閉じる
        searchBar.resignFirstResponder()
        
        // 表示用配列を元の配列と同じにする
        displayTaskArray = taskArray
 
        // テーブルの再表示
        tableView.reloadData()
    }
}

