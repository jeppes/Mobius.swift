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

public struct EffectRouter<Effect, Event> {
    public let handlers: [EffectHandler<Effect, Event>]

    public init(handlers: [EffectHandler<Effect, Event>] = []) {
        self.handlers = handlers
    }

    public var asEffectHandler: EffectHandler<Effect, Event> {
        return compositionStrategy(handlers: handlers)
    }

    public func routePayload<Payload>(
        _ extractPayload: @escaping (Effect) -> Payload?,
        to handler: EffectHandler<Payload, Event>
    ) -> EffectRouter<Effect, Event> {
        let newHandler = EffectHandler<Effect, Event>(
            handle: { effect, dispatch in
                if let payload = extractPayload(effect) {
                    return handler.handle(payload, dispatch)
                } else {
                    return false
                }
            },
            stopHandling: handler.disposable
        )
        return EffectRouter(handlers: handlers + [newHandler])
    }
}

public extension EffectRouter where Effect: Equatable {
    func routeConstant(
        _ handledEffect: Effect,
        to handler: EffectHandler<Effect, Event>
    ) -> EffectRouter {
        let newHandler = EffectHandler<Effect, Event>(
            handle: { effect, dispatch in
                if effect == handledEffect {
                    return handler.handle(effect, dispatch)
                } else {
                    return false
                }
            },
            stopHandling: handler.disposable
        )
        return EffectRouter(handlers: handlers + [newHandler])
    }
}

private func compositionStrategy<Effect, Event>(
    handlers: [EffectHandler<Effect, Event>]
) -> EffectHandler<Effect, Event> {
    return EffectHandler(
        handle: { effect, dispatch in
            let relevantHandlers = handlers
                .map { $0.handle(effect, dispatch) }
                .filter { $0 }
            switch relevantHandlers.count {
            case 1:
                return true
            default:
                MobiusHooks.onError("Error: \(relevantHandlers.count) EffectHandlers could be found for effect: \(effect). Exactly 1 is required.")
                return false
            }
        },
        stopHandling: {
            handlers.forEach {
                $0.disposable.dispose()
            }
        }
    )
}
