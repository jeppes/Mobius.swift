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

class EffectRouterTests: QuickSpec {
    // swiftlint:disable function_body_length
    override func spec() {
        context("Routing to effect handlers with an EffectRouter") {
            var receivedEffect1: Int?
            var receivedEffect2: Int?
            var disposed1: Bool!
            var disposed2: Bool!
            var effectHandler1: EffectHandler<Int, Int>!
            var effectHandler2: EffectHandler<Int, Int>!
            var composedEffectHandler: EffectHandler<Int, Int>!

            beforeEach {
                receivedEffect1 = nil
                receivedEffect2 = nil
                disposed1 = false
                disposed2 = false
                effectHandler1 = EffectHandler<Int, Int>(
                    handle: { effect, _ in
                        receivedEffect1 = effect
                    },
                    stopHandling: {
                        disposed1 = true
                    }
                )
                effectHandler2 = EffectHandler<Int, Int>(
                    handle: { effect, _ in
                        receivedEffect2 = effect
                    },
                    stopHandling: {
                        disposed2 = true
                    }
                )
                composedEffectHandler = EffectRouter<Int, Int>()
                    .routeConstant(1, to: effectHandler1)
                    .routePayload(
                        { effect in effect == 2 ? 2 : nil },
                        to: effectHandler2
                    )
                    .routeConstant(3, to: effectHandler1)
                    .routeConstant(3, to: effectHandler1)
                    .asEffectHandler
            }

            it("should be able to route to a constant effect handler") {
                _ = composedEffectHandler.handle(1, { _ in })
                expect(receivedEffect1).to(equal(1))
            }

            it("should be able to route to an effect handler with an extract function") {
                _ = composedEffectHandler.handle(2, { _ in })
                expect(receivedEffect2).to(equal(2))
            }

            it("should crash if more than 1 effect handler could be found") {
                var didCrash = false
                MobiusHooks.setErrorHandler { _, _, _ in
                    didCrash = true

                }

                composedEffectHandler.handle(3, { _ in })

                expect(didCrash).to(beTrue())
            }

            it("should crash if no effect handlers could be found") {
                var didCrash = false
                MobiusHooks.setErrorHandler { _, _, _ in
                    didCrash = true
                }

                composedEffectHandler.handle(4, { _ in })

                expect(didCrash).to(beTrue())
            }

            it("should dispose all existing effect handlers when router is disposed") {
                composedEffectHandler.disposable.dispose()
                expect(disposed1).to(beTrue())
                expect(disposed2).to(beTrue())
            }
        }
    }
}
