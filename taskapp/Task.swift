//
//  Task.swift
//  taskapp
//
//  Created by 濱田 一 on 2017/10/06.
//  Copyright © 2017年 濱田 一. All rights reserved.
//

import RealmSwift

class Task: Object{
    // 管理用ID。プライマリーキー
    dynamic var id = 0
    
    // タイトル
    dynamic var title = ""
    
    // 内容
    dynamic var contents = ""
    
    // 日時
    dynamic var date = NSDate()
    
    // カテゴリID ★★
    dynamic var category_id = 0
    
    /**
      idをプライマリーキーとして設定
    */
    override static func primaryKey() -> String? {
        return "id"
    }
}
