//
//  Category.swift
//  taskapp
//
//  Created by 濱田 一 on 2017/10/09.
//  Copyright © 2017年 濱田 一. All rights reserved.
//

import RealmSwift

class Category: Object{
    // 管理用ID。プライマリーキー
    dynamic var id = 0
    
    // カテゴリ名
    dynamic var title = ""
    /**
     idをプライマリーキーとして設定
     */
    override static func primaryKey() -> String? {
        return "id"
    }
}
