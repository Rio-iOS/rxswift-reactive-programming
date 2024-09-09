//
//  Chapter04UIImage+Collage.swift
//  RxSwiftExample
//
//  Created by 藤門莉生 on 2024/09/09.
//

import Foundation
import UIKit

extension Array where Element == UIImage {
    func collage(size: CGSize) -> UIImage {
        // 行数の決定
        // 配列の要素数が3未満の場合、行数は1、それ以外は行数は2として画像を配置
        let rows = self.count < 3 ? 1 : 2
        // 列数の決定
        // 行数に応じて計算される。
        // 画像の数を行数で割り、最も近い整数に丸めて列数を決定
        let columns = Int(round(Double(self.count) / Double(rows)))
        // タイルのサイズを計算
        // 画像を描画するためのタイルサイズを計算
        // コラージュ全体のサイズを列数と行数で割り、
        // 1つの画像が占める領域（タイル）の大きさを求める
        let tileSize = CGSize(
            width: round(size.width / CGFloat(columns)),
            height: round(size.height / CGFloat(rows))
        )
       
        // 描画準備
        // UIGraphicsBeginImageContextWithOptionsを使って、
        // 新しい画像の描画コンテキストを作成
        UIGraphicsBeginImageContextWithOptions(size, true, 0)
        // 背景を白く塗り潰す
        UIColor.white.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
       
        // 配列に格納された画像を順に取り出し、指定したタイルサイズにスケーリングして、
        // 適切な位置（CGPoint）に描画する。
        // この位置は、現在の画像が何列目かと何行目かによって計算される。
        //
        // index % columnsは、現在の画像がどの列に属するかを示す
        // (ex)列数3の場合
        // index = 0 -> index % 3 = 0
        // index = 1 -> index % 3 = 1
        // index = 2 -> index % 3 = 2
        //
        // index / columnsは、現在の画像がどの行に属するかを示す
        // index = 0 -> index / 3 = 0
        // index = 3 -> index / 3 = 1 -> tileSize.height
        // index = 6 -> index / 3 = 2 -> 2 * tileSize.height
        for (index, image) in self.enumerated() {
            image.scaled(tileSize).draw(
                at: CGPoint(
                    x: CGFloat(index % columns) * tileSize.width,
                    y: CGFloat(index / columns) * tileSize.height
                )
            )
        }
       
        // コラージュ画像の生成
        // 描画が終了した後に、UIGraphicsGetImageFromCurrentImageContextで生成された画像を取得し、UIGraphicsEndImageContextを終了する。
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        // 取得した画像を返す。
        return image ?? UIImage()
    }
}

extension UIImage {
    /// 画像のサイズを新しいサイズにスケーリングする
    func scaled(_ newSize: CGSize) -> UIImage {
        // 元の画像のサイズと指定された画像サイズを比較する
        // サイズが同じ場合はスケーリング不要なため、リターンする
        guard size != newSize else {
            return self
        }
       
        // スケーリング比率の取得
        // 最大となる比率を取得
        let ratio = max(newSize.width / size.width, newSize.height / size.height)
        let width = size.width * ratio
        let height = size.height * ratio
       
        // スケーリング後の　サイズと位置の計算
        // スケーリング後の画像の幅と高さを計算し、
        // 新しいサイズに対して中央に配置するように、
        // 描画領域の座標を計算する
        // 余白ができる場合は、中心に配置されるように調整する。
        let scaledRect = CGRect(
            x: (newSize.width - width) / 2.0,
            y: (newSize.height - height) / 2.0,
            width: width,
            height: height
        )
       
        // 新しい画像を描画するために、UIGraphicsBeginImageContextWithOptionsを使用
        UIGraphicsBeginImageContextWithOptions(scaledRect.size, false, 0)
        defer {
            UIGraphicsEndImageContext()
        }
        
        draw(in: scaledRect)
        
        return UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
    }
}
