//
//  Swizzle.swift
//  SwizzleDemo
//
//  Created by Yi Zhang on 2019/6/20.
//  Copyright © 2019 Yi Zhang. All rights reserved.
//

import ObjectiveC
import Foundation
import UIKit

protocol SwizzleProtocol: class {
    
    static func awake()
    static func swizzle(_ forClass: AnyClass, originalSelector: Selector, swizzledSelector: Selector)
    
}


extension SwizzleProtocol {
    
    static func swizzle(_ forClass: AnyClass, originalSelector: Selector, swizzledSelector: Selector) {
        
        let originalMethod = class_getInstanceMethod(forClass, originalSelector)
        let swizzledMethod = class_getInstanceMethod(forClass, swizzledSelector)
        
        guard (originalMethod != nil && swizzledMethod != nil) else {
            return
        }
        
        if class_addMethod(forClass, originalSelector, method_getImplementation(swizzledMethod!), method_getTypeEncoding(originalMethod!)) {
            class_replaceMethod(forClass, swizzledSelector, method_getImplementation(originalMethod!), method_getTypeEncoding(originalMethod!))
        } else {
            method_exchangeImplementations(originalMethod!, swizzledMethod!)
        }
        
    }
    
}


class Swizzle {
    
    static func performOnce() {
        let count = Int(objc_getClassList(nil, 0))
        let classes = UnsafeMutablePointer<AnyClass?>.allocate(capacity: count)
        let autoreleaseClasses = AutoreleasingUnsafeMutablePointer<AnyClass>(classes)
        objc_getClassList(autoreleaseClasses, Int32(count))
        for index in 0..<count {
            (classes[index] as? SwizzleProtocol.Type)?.awake()
        }
        classes.deallocate()
    }
    
}


extension UIApplication {

    private static let runOnce: Void = {
        Swizzle.performOnce()
    }()

    open override var next: UIResponder? {
        UIApplication.runOnce
        return super.next
    }

}


extension UIViewController: SwizzleProtocol {
    
    static func awake() {
        swizzleViewWillAppear
    }
    
    private static let swizzleViewWillAppear: Void = {
        let originalSelector = #selector(viewWillAppear(_:))
        let swizzledSelector = #selector(swizzled_viewWillAppear(_:))
        
        swizzle(UIViewController.self, originalSelector: originalSelector, swizzledSelector: swizzledSelector)
    }()
    
    
    @objc func swizzled_viewWillAppear(_ animated: Bool) {
        swizzled_viewWillAppear(animated)
        print("swizzled_viewWillAppear")
    }
    
    // TODO:- Add more swizzleMethod
    
}
