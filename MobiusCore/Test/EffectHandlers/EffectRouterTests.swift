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

import MobiusCore
import Nimble
import Quick

// swiftlint:disable type_body_length file_length

private enum Effect {
    case effect1
    case effect2
    case multipleHandlersForThisEffect
    case noHandlersForThisEffect
}

private enum Event {
    case eventForEffect1
    case eventForEffect2
}

class EffectRouterTests: QuickSpec {
    // swiftlint:disable function_body_length
    override func spec() {
        context("Routing to effect handlers with an EffectRouter") {
            var receivedEvents: [Event]!
            var disposed1: Bool!
            var disposed2: Bool!
            var composedEffectHandler: Connection<Effect>!

            beforeEach {
                receivedEvents = []
                disposed1 = false
                disposed2 = false
                let effectHandler1 = EffectHandler<Effect, Event>(
                    handle: { effect, dispatch in
                        dispatch(.eventForEffect1)
                    },
                    stopHandling: {
                        disposed1 = true
                    }
                )
                let extractEffect2: (Effect) -> Effect? = {
                    return $0 == .effect2 ? .effect2 : nil
                }
                let effectHandler2 = EffectHandler<Effect, Event>(
                    handle: { effect, dispatch in
                        dispatch(.eventForEffect2)
                    },
                    stopHandling: {
                        disposed2 = true
                    }
                )
                composedEffectHandler = EffectRouter<Effect, Event>()
                    .routeConstant(.effect1, toHandler: effectHandler1)
                    .routePayload(extractEffect2, toHandler: effectHandler2)
                    .routeConstant(.multipleHandlersForThisEffect, toHandler: effectHandler1)
                    .routeConstant(.multipleHandlersForThisEffect, toHandler: effectHandler1)
                    .asConnectable
                    .connect { event in
                        receivedEvents.append(event)
                    }
            }

            it("should be able to route to a constant effect handler") {
                _ = composedEffectHandler.accept(.effect1)
                expect(receivedEvents).to(equal([.eventForEffect1]))
            }

            it("should be able to route to an effect handler with an extract function") {
                _ = composedEffectHandler.accept(.effect2)
                expect(receivedEvents).to(equal([.eventForEffect2]))
            }

            it("should crash if more than 1 effect handler could be found") {
                var didCrash = false
                MobiusHooks.setErrorHandler { _, _, _ in
                    didCrash = true

                }

                composedEffectHandler.accept(.multipleHandlersForThisEffect)

                expect(didCrash).to(beTrue())
            }

            it("should crash if no effect handlers could be found") {
                var didCrash = false
                MobiusHooks.setErrorHandler { _, _, _ in
                    didCrash = true
                }

                composedEffectHandler.accept(.noHandlersForThisEffect)

                expect(didCrash).to(beTrue())
            }

            it("should dispose all existing effect handlers when router is disposed") {
                composedEffectHandler.dispose()
                expect(disposed1).to(beTrue())
                expect(disposed2).to(beTrue())
            }
        }
    }
}


