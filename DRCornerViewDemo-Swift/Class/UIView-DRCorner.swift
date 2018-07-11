//
//  UIView-DRCorner.swift
//  DRCornerViewDemo-Swift
//
//  Created by DR_Kun on 2018/7/11.
//  Copyright © 2018年 DR_Kun. All rights reserved.
//

import UIKit

//[swift中的集合选项](http://swift.gg/2016/10/25/swift-option-sets/)
struct DRRectCorner: OptionSet {
    let rawValue: UInt
//    static let topLeft = DRRectCorner(rawValue: UIRectCorner.topLeft.rawValue)
//    static let topRight = DRRectCorner(rawValue: UIRectCorner.topRight.rawValue)
//    static let bottomLeft = DRRectCorner(rawValue: UIRectCorner.bottomLeft.rawValue)
//    static let bottomRight = DRRectCorner(rawValue: UIRectCorner.bottomRight.rawValue)
    static let allCorners = DRRectCorner(rawValue: UIRectCorner.allCorners.rawValue)
    static let allTop = DRRectCorner(rawValue: UIRectCorner([UIRectCorner.topRight, UIRectCorner.topLeft]).rawValue)
    static let allBottom = DRRectCorner(rawValue: UIRectCorner([UIRectCorner.bottomLeft, UIRectCorner.bottomRight]).rawValue)
    func convertToUIRectCorner() -> UIRectCorner {
        return UIRectCorner(rawValue: self.rawValue)
    }
}

struct DRCornerStyle {
    let corenerType: DRRectCorner
    let cornerRadius: CGFloat
    let superBGColor: UIColor
    let borderColor: UIColor?

//    func isEqual(style: DRCornerStyle) -> Bool {
//        guard style.corenerType == corenerType else {
//            return false
//        }
//        guard style.cornerRadius == cornerRadius else {
//            return false
//        }
//        guard style.superBGColor == superBGColor else {
//            return false
//        }
//        guard style.borderColor == borderColor else {
//            return false
//        }
//        return true
//    }
}

/*
extension DRCornerStyle: Equatable {
//    static func ==(lhs: DRCornerStyle, rhs: DRCornerStyle) -> Bool {
//
//    }
}
//[swift中的equal](http://swifter.tips/equal/)  这很*swift*
func ==(lhs: DRCornerStyle, rhs: DRCornerStyle) -> Bool {
    guard lhs.corenerType == rhs.corenerType else {
        return false
    }
    guard lhs.cornerRadius == rhs.cornerRadius else {
        return false
    }
    guard lhs.superBGColor == rhs.superBGColor else {
        return false
    }
    guard lhs.borderColor == rhs.borderColor else {
        return false
    }
    return true
}
*/

extension UIView {
    //MARK: 添加属性的 key
    fileprivate struct DRCornenrRuntimeKey {
        static let drCornerLayerName: UnsafeRawPointer! = UnsafeRawPointer.init(bitPattern: "DRCornerShapeLayer".hashValue)
        static let drCornerModelName: UnsafeRawPointer! = UnsafeRawPointer.init(bitPattern: "DRCornerModelName".hashValue)
    }

    fileprivate var drCornerLayer: CAShapeLayer? {
        set {
            objc_setAssociatedObject(self, UIView.DRCornenrRuntimeKey.drCornerLayerName, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            let obj = objc_getAssociatedObject(self, UIView.DRCornenrRuntimeKey.drCornerLayerName) as? CAShapeLayer
            return obj
        }
    }

    fileprivate var drCornerStyle: DRCornerStyle? {
        set {
            objc_setAssociatedObject(self, UIView.DRCornenrRuntimeKey.drCornerModelName, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
        get {
            let obj = objc_getAssociatedObject(self, UIView.DRCornenrRuntimeKey.drCornerModelName) as? DRCornerStyle
            return obj
        }
    }
    //MARK: 添加圆角处理
    func drCornerd(style: DRCornerStyle?) {
        changeMethod()
        drCornerStyle = style
        registDRCornerLayer()
        setNeedsDisplay()
    }
    //MARK: 移除圆角处理
    func removeDRCorner() {
        if let _ = drCornerStyle {
            drCornerStyle = nil
        }
        guard let shapeLayer = drCornerLayer else {
            return
        }
        shapeLayer.removeFromSuperlayer()
        drCornerLayer = nil
        setNeedsDisplay()
    }
    //MARK: 交换方法
    fileprivate func changeMethod() {
        DispatchQueue.once(token: "DRCornered") {
            let originalSelector = #selector(UIView.layoutSublayers(of:))
            let swizzledSelector = #selector(UIView.dr_layoutSublayers(of:))

            let originalLayoutSublayer = class_getInstanceMethod(UIView.classForCoder(), originalSelector)
            let swizzledLayoutSublayer = class_getInstanceMethod(UIView.classForCoder(), swizzledSelector)

            let didAddMethod = class_addMethod(UIView.classForCoder(), originalSelector, method_getImplementation(swizzledLayoutSublayer!), method_getTypeEncoding(swizzledLayoutSublayer!))
            if didAddMethod {
                class_replaceMethod(UIView.classForCoder(), swizzledSelector, method_getImplementation(originalLayoutSublayer!), method_getTypeEncoding(originalLayoutSublayer!))
            }else {
                method_exchangeImplementations(originalLayoutSublayer!, swizzledLayoutSublayer!)
            }
        }
    }

    func defaultCornerStyle() -> DRCornerStyle {
        if let supBGColor = superview?.backgroundColor {
            return DRCornerStyle(corenerType: .allCorners, cornerRadius: 4.0, superBGColor: supBGColor, borderColor: nil)
        }else {
            return DRCornerStyle(corenerType: .allCorners, cornerRadius: 4.0, superBGColor: .white, borderColor: nil)
        }
    }

    @objc fileprivate func dr_layoutSublayers(of layer: CALayer) {
        self.dr_layoutSublayers(of: layer)
        if hasDRCornered() {
            resetCornerLayer()
        }
    }

    //MARK: 判断是否已经有圆角处理
    fileprivate func hasDRCornered() -> Bool {
        return drCornerLayer != nil
    }

    fileprivate func registDRCornerLayer() {
        if drCornerLayer == nil {
            let shapeLayer = CAShapeLayer()
            drCornerLayer = shapeLayer
            layer.insertSublayer(shapeLayer, at: UInt32.max)
        }
    }
    //MARK: 布局shapeLayer
    fileprivate func resetCornerLayer() {
        var style = defaultCornerStyle()
        if let cornerStyle = drCornerStyle {
            style = cornerStyle
        }
        let cornerSize = CGSize.init(width: style.cornerRadius, height: style.cornerRadius)
        let shapeLayer = drCornerLayer!
        let path = UIBezierPath.init(rect: bounds)
        let cornerPath = UIBezierPath.init(roundedRect: bounds, byRoundingCorners: style.corenerType.convertToUIRectCorner(), cornerRadii: cornerSize)
        path.append(cornerPath)
        shapeLayer.path = path.cgPath
        shapeLayer.fillRule = kCAFillRuleEvenOdd
        shapeLayer.fillColor = UIColor.white.cgColor
        if let boderColor = style.borderColor {
            //描边
            print("\(boderColor)")
            let cornerPathLength = lengthOFCGPath(cornerType: style.corenerType, radius: style.cornerRadius, size: bounds.size)
            let totolPathLength = 2.0 * (bounds.height + bounds.width) + cornerPathLength
            shapeLayer.strokeStart = (totolPathLength-cornerPathLength) / totolPathLength
            shapeLayer.strokeEnd = 1.0
            shapeLayer.strokeColor = boderColor.cgColor
        }
    }

    //MARK: -计算描边的length
    private func lengthOFCGPath(cornerType: DRRectCorner, radius: CGFloat, size: CGSize) -> CGFloat {
        var totalLength: CGFloat = 0.0
        switch cornerType {
        case .allTop:
            fallthrough
        case .allBottom:
            totalLength = 2.0 * (size.width + size.height) - 4.0 * radius + (CGFloat.pi * radius);
            break
        case .allCorners:
            totalLength = 2.0 * (size.width + size.height) - 8.0 * radius + (CGFloat.pi * radius) * 2.0;
            break
        default:
            break
        }

        return totalLength;
    }

}

//MARK: 这里可以移出为单独的 swift 文件
extension DispatchQueue {
    fileprivate static var onceTracker = [String]()
    open class func once(token: String, block:() -> Void) {
        objc_sync_enter(self)
        defer {
            objc_sync_exit(self)
        }
        if onceTracker.contains(token) {
            return
        }
        onceTracker.append(token)
        block()
    }
}

