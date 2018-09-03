//
//  Promise.swift
//  Promise
//
//  Created by lovellx on 2018/9/3.
//  Copyright © 2018年 lovellx. All rights reserved.
//

import Foundation


enum State<Value> {
    case pending
    case fullfill(value: Value)
    case reject(error: Error)
}

struct Callback<Value> {
    var onFullfilled: ((Value) -> Void)?
    var onRejected: ((Error) -> Void)?
    var onQueue: DispatchQueue = DispatchQueue.main
}

extension Callback {

    func callFullfill(value: Value) {
        onQueue.async {
            self.onFullfilled?(value)
        }
    }

    func callReject(error: Error) {
        onQueue.async {
            self.onRejected?(error)
        }
    }

}


public class Promise<T> {

    private var state: State<T> = .pending
    private var callbacks: [Callback<T>] = []
    private var serialQueue = DispatchQueue.init(label: "PromiseLocked")

    public init() {
        state = .pending
    }
    public init(value: T) {
        state = .fullfill(value: value)
    }

    public init(error: Error) {
        state = .reject(error: error)
    }

    public func fulfill(_ value: T) {
        serialQueue.sync {
            state = .fullfill(value: value)
        }
        fireCallback()
    }

    public func reject(_ error: Error) {
        serialQueue.sync {
            state = .reject(error: error)
        }
        fireCallback()
    }

    private func fireCallback() {
        serialQueue.async {
            switch self.state {
            case .pending:
                return
            case .fullfill(let value):
                self.callbacks.forEach({ (callback) in
                    callback.callFullfill(value: value)
                })
                self.callbacks.removeAll()
            case .reject(let error):
                self.callbacks.forEach({ (callback) in
                    callback.callReject(error: error)
                })
                self.callbacks.removeAll()
            }
        }
    }

    @discardableResult
    public func then(on queue:DispatchQueue = DispatchQueue.main,
              onFulfilled: @escaping (T) -> Void) -> Promise<T> {
        let callback = Callback(onFullfilled: onFulfilled, onRejected: nil, onQueue: queue)
        addCallback(callback)
        return self
    }

    @discardableResult
    public func `catch`(on queue: DispatchQueue = DispatchQueue.main,
                 onRejected: @escaping (Error) -> Void) -> Promise<T> {
        let callback = Callback<T>(onFullfilled: nil, onRejected: onRejected, onQueue: queue)
        addCallback(callback)
        return self
    }

    public func then<U>(on queue: DispatchQueue = DispatchQueue.main,
                        onFullfilled: @escaping (T) throws -> U  ) -> Promise<U> {
        let promiseU = Promise<U>()
        let callback = Callback<T>.init(onFullfilled: { (value) in
            do {
                let newValue = try onFullfilled(value)
                promiseU.fulfill(newValue)
            } catch(let error) {
                promiseU.reject(error)
            }
        }, onRejected: { (error) in
            promiseU.reject(error)
        }, onQueue: queue)
        addCallback(callback)
        return promiseU

    }

    public func then<U>(on queue: DispatchQueue = DispatchQueue.main,
                 onFullfilled: @escaping (T) throws -> Promise<U>) -> Promise<U> {
        let promiseU = Promise<U>()
        let callback = Callback<T>.init(onFullfilled: { (value) in
            do {
                let promise = try onFullfilled(value)
                promise.then(on: queue, onFulfilled: { (valueU) in
                    promiseU.fulfill(valueU)
                }).catch(on: queue, onRejected: { (error) in
                    promiseU.reject(error)
                })
            } catch(let error) {
                promiseU.reject(error)
            }
        }, onRejected: { (error) in
            promiseU.reject(error)
        }, onQueue: queue)
        addCallback(callback)
        return promiseU
    }

    private func addCallback(_ callback: Callback<T>) {
        serialQueue.async {
            self.callbacks.append(callback)
        }
        fireCallback()
    }

}

public extension DispatchQueue {

    public func promise<T>(after: TimeInterval, excute: @escaping @autoclosure ()->T) -> Promise<T> {
        let promise = Promise<T>()
        asyncAfter(deadline: .now() + after) {
            promise.fulfill(excute())
        }
        return promise
    }

    public func promise<T>(_ excute: @escaping @autoclosure ()->T) -> Promise<T> {
        let promise = Promise<T>()
        async {
            promise.fulfill(excute())
        }
        return promise
    }

}
