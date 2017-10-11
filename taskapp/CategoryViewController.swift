//
//  CategoryViewController.swift
//  taskapp
//
//  Created by 濱田 一 on 2017/10/09.
//  Copyright © 2017年 濱田 一. All rights reserved.
//

import UIKit
import RealmSwift

class CategoryViewController: UIViewController {

    @IBOutlet weak var categoryTextField: UITextField!
    
    var category: Category!
    let realm = try! Realm()
    
    // カテゴリが格納されるリスト ★★
    var categoryArray = try! Realm().objects(Category.self).sorted(byKeyPath: "id", ascending: true)

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        // 背景をタップしたらdismissKeyboardメソッドを呼ぶように設定する
        let tapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action:#selector(dismissKeyboard))
        self.view.addGestureRecognizer(tapGesture)

    }

    func dismissKeyboard(){
        // キーボードを閉じる
        view.endEditing(true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillDisappear(_ animated: Bool) {

        // 同じカテゴリ名がないか探す
        var write_flag = true
        for cat in self.categoryArray {
            if cat.title == self.categoryTextField.text!{
                write_flag = false
                break
            }
        }
        
        // 同じカテゴリ名がなければ書き込み
        if write_flag {
            try! realm.write {
                self.category.title = self.categoryTextField.text!
                self.realm.add(self.category, update: true)
            }
        }
        
        super.viewWillDisappear(animated)
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
