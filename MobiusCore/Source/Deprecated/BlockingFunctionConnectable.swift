// Copyright (c) 2020 Spotify AB.
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

/// Base class for creating a function based `connectable`.
///
/// Invoking the `connection` functions will block the current thread until done.
// swiftlint:disable:next line_length
@available(*, deprecated, message: "BlockingFunctionConnectable will be removed before Mobius 1.0. If you’re using it with EffectRouter, you probably don’t need an explicit connectable, just route to your fire-and-forget function.")
open class BlockingFunctionConnectable<Input, Output>: Connectable {
    private var innerConnectable: ClosureConnectable<Input, Output>

    /// Initialise with a function (input, output).
    ///
    /// - Parameter function: Called when the `connection`’s `accept` function is called.
    public init(_ function: @escaping (Input) -> Output) {
        innerConnectable = ClosureConnectable(function)
    }

    public func connect(_ consumer: @escaping Consumer<Output>) -> Connection<Input> {
        return innerConnectable.connect(consumer)
    }
}