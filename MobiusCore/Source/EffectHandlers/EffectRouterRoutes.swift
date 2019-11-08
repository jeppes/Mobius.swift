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

extension EffectRouter {
    /// Add a route for to an effect handling function. This route will be taken if `extractPayload` returns a non-`nil` value for the effect in question.
    /// The value returned by `extractPayload` will be the input to the handling function.
    ///
    /// - Parameter extractPayload: A function which returns a non-`nil` value if this route should be taken. The non-`nil` value which is returned
    /// becomes the input to the `handlerFunction`
    /// - Parameter handlerFunction: The function which should be called if `extractPayload` returns a non-`nil` value.
    public func routePayload<Payload>(
        _ extractPayload: @escaping (Effect) -> Payload?,
        to handlerFunction: @escaping (Payload) -> [Event]
    ) -> EffectRouter<Effect, Event> {
        return routePayload(
            extractPayload,
            toHandler: EffectHandler(handle: { payload, dispatch in
                let events = handlerFunction(payload)
                events.forEach { dispatch($0) }
            })
        )
    }

    /// Add a route for to an effect handling function which produces no events.
    /// This route will be taken if `extractPayload` returns a non-`nil` value for the effect in question. The value returned by `extractPayload` will be
    /// the input to the handling function.
    ///
    /// - Parameter extractPayload: A function which returns a non-`nil` value if this route should be taken. The non-`nil` value which is returned
    /// becomes the input to the `handlerFunction`
    /// - Parameter handlerFunction: The function which should be called if `extractPayload` returns a non-`nil` value.
    public func routePayload<Payload>(
        _ extractPayload: @escaping (Effect) -> Payload?,
        to fireAndForgetFunction: @escaping (Payload) -> Void
    ) -> EffectRouter<Effect, Event> {
        return routePayload(
            extractPayload,
            toHandler: EffectHandler(handle: { payload, _ in
                fireAndForgetFunction(payload)
            })
        )
    }
}

public extension EffectRouter where Effect: Equatable {
    /// Add a route for `handler`. This route will be taken if the effect in question is equal to `handledEffect`
    ///
    /// - Parameter handledEffect: The effect handled by `handler`.
    /// - Parameter handler: The handler which should handle the `handledEffect`.
    func routeConstant(
        _ handledEffect: Effect,
        toHandler handler: EffectHandler<Effect, Event>
    ) -> EffectRouter<Effect, Event> {
        routePayload(
            { effect in handledEffect == effect ? effect : nil },
            toHandler: handler
        )
    }

    /// Add a route for an effect handling function which produces events. This route will be taken if the effect in question is equal to `handledEffect`
    ///
    /// - Parameter handledEffect: The effect handled by `handler`.
    /// - Parameter handler: The handler which should handle the `handledEffect`.
    func routeConstant(
        _ handledEffect: Effect,
        to handlingFunction: @escaping (Effect) -> [Event]
    ) -> EffectRouter<Effect, Event> {
        routePayload(
            { effect in handledEffect == effect ? effect : nil },
            to: handlingFunction
        )
    }

    /// Add a route for an effect handling function which produces events. This route will be taken if the effect in question is equal to `handledEffect`
    ///
    /// - Parameter handledEffect: The effect handled by `handler`.
    /// - Parameter handler: The handler which should handle the `handledEffect`.
    func routeConstant(
        _ handledEffect: Effect,
        to fireAndForgetFunction: @escaping (Effect) -> Void
    ) -> EffectRouter<Effect, Event> {
        routePayload(
            { effect in handledEffect == effect ? effect : nil },
            to: fireAndForgetFunction
        )
    }
}
