// Copyright (c) 2019 Spotify AB.
//
// Licensed to the Apache Software Foundation (ASF) under one
// or more contributor license agreements.  See the NOTICE file
// distributed with this work for additional information
// regarding copyright ownership.  The ASF licenses this file
// to you under the Apache License, Version 2.0 (the
// "License"); you may not use this file except in compliance
// with the License.  You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import Foundation


/// `EffectRouter` is used to compose a group of `EffectHandler`s into a single `EffectHandler`.
///
/// `asEffectHandler` can be called to collapse all the routes defined in `routePayload` and `routeConstant` into a single `EffectHandler`.
/// This `EffectHandler` must have __exactly 1__ route for every `Effect` it receives. Handling an effect is more than 1 route, or in 0 routes, will result in
/// a runtime error.
public struct EffectRouter<Effect, Event> {
    private let routes: [Route<Effect, Event>]

    public init() {
        routes = []
    }

    fileprivate init(routes: [Route<Effect, Event>] = []) {
        self.routes = routes
    }

    /// Collapse this `EffectRouter` into a single effect handler.
    public var asEffectHandler: AnyConnectable<Effect, Event> {
        return compose(routes: routes)
    }

    /// Add a route for `handler`. This route will be taken if `extractPayload` returns a non-`nil` value for the effect in question.
    /// The value returned by `extractPayload` will be the input to the `EffectHandler`.
    ///
    /// - Parameter extractPayload: A function which returns a non-`nil` value if this route should be taken. The non-`nil` value which is returned
    /// becomes the input to the `handler`
    /// - Parameter handler: The effect handler which should be used if `extractPayload` returns a non-`nil` value.
    public func routePayload<Payload>(
        _ extractPayload: @escaping (Effect) -> Payload?,
        to handler: EffectHandler<Payload, Event>
    ) -> EffectRouter<Effect, Event> {
        let route = Route<Effect, Event>(
            handle: { effect, dispatch in
                if let payload = extractPayload(effect) {
                    handler.handle(payload, dispatch)
                    return true
                } else {
                    return false
                }
            },
            disposable: handler.disposable
        )
        return EffectRouter(routes: routes + [route])
    }
}

public extension EffectRouter where Effect: Equatable {

    /// Add a route for `handler`. This route will be taken if the effect in question is equal to `handledEffect`
    ///
    /// - Parameter handledEffect: The effect handled by `handler`.
    /// - Parameter handler: The handler which should handle the `handledEffect`.
    func routeConstant(
        _ handledEffect: Effect,
        to handler: EffectHandler<Effect, Event>
    ) -> EffectRouter<Effect, Event> {
        routePayload(
            { effect in handledEffect == effect ? effect : nil },
            to: handler
        )
    }
}


private struct Route<Effect, Event> {
    let handle: (Effect, @escaping Consumer<Event>) -> Bool
    let disposable: Disposable
}

private func compose<Effect, Event>(
    routes: [Route<Effect, Event>]
) -> AnyConnectable<Effect, Event> {
    return AnyConnectable { dispatch in
        let routeConnections = routes
            .map { route in toSafeConnection(route: route, dispatch: dispatch) }

        return Connection(
            acceptClosure: { effect in
                let handledCount = routeConnections
                    .map { $0.handle(effect) }
                    .filter { $0 }
                    .count

                if handledCount != 1 {
                    MobiusHooks.onError("Error: \(handledCount) EffectHandlers could be found for effect: \(handledCount). Exactly 1 is required.")
                }
            },
            disposeClosure: {
                routeConnections.forEach { route in
                    route.dispose()
                }
            }
        )
    }
}

private func toSafeConnection<Effect, Event>(
    route: Route<Effect, Event>,
    dispatch: @escaping Consumer<Event>
) -> RouteConnection<Effect, Event> {
    return RouteConnection(
        handleInput: route.handle,
        output: dispatch,
        dispose: route.disposable
    )
}
