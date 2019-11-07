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

private enum Effect: Equatable {
    // Effect 1 is handled
    case effect1
    // Effect 2 is not handled
    case effect2
}

private enum Event {
    case eventForEffect1
}

// swiftlint:disable type_body_length file_length

class EffectHandlerTests: QuickSpec {
    // swiftlint:disable function_body_length
    override func spec() {
        describe("Handling effects with EffectHandler") {
            var effectHandler: EffectHandler<Effect, Event>!
            var executeEffect: ((Effect) -> Bool)!
            var receivedEvents: [Event]!

            beforeEach {
                effectHandler = EffectHandler(handle: handleEffect)
                receivedEvents = []
                let output = { (event: Event) in receivedEvents.append(event) }
                executeEffect = { effect in
                    effectHandler.handle(effect, output)
                }
            }
            afterEach {
                effectHandler.disposable.dispose()
            }

            context("When executing effects") {
                it("dispatches the expected event for an effect which can be handled") {
                    _ = executeEffect(.effect1)
                    expect(receivedEvents).to(equal([.eventForEffect1]))
                }

                it("dispatches no effects for events which cannot be handled") {
                    _ = executeEffect(.effect2)
                    expect(receivedEvents).to(beEmpty())
                }

                it("returns true for effects which are executed") {
                    let didExecute = executeEffect(.effect1)
                    expect(didExecute).to(beTrue())
                }

                it("returns false for effects which are executed") {
                    let didExecute = executeEffect(.effect2)
                    expect(didExecute).to(beFalse())
                }
            }
        }
        describe("Disposing EffectHandler") {
            var effectHandler: EffectHandler<Effect, Event>!
            var isDisposed: Bool!

            beforeEach {
                isDisposed = false
                effectHandler = EffectHandler(
                    handle: { _, _ in true },
                    stopHandling: {
                        isDisposed = true
                    }
                )
            }

            it("calls `stopHandling` when disposed") {
                effectHandler.disposable.dispose()
                expect(isDisposed).to(beTrue())
            }


            it("disposing is idempotent") {
                expect(isDisposed).to(beFalse())

                effectHandler.disposable.dispose()
                effectHandler.disposable.dispose()
                effectHandler.disposable.dispose()

                expect(isDisposed).to(beTrue())
            }
        }
    }
}

private func handleEffect(effect: Effect, output: Consumer<Event>) -> Bool {
    switch effect {
    case .effect1:
        output(.eventForEffect1)
        return true
    case .effect2:
        return false
    }
}
