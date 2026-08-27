// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————
//
// HomeScreenRootTests.swift
//
//
// Created by Steven Marcotte on 2026-Aug-27
// Copyright (c) 1996 - 2026 Steven Marcotte, All Rights Reserved
//
// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

import Testing
import SwiftUI

@testable import PaletteMonkey


// MARK: -
// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

@Suite("HomeScreenRoot")
struct HomeScreenRootTests {

    @Test("Builds a body without trapping")
    func buildsBody() {
        let screen = HomeScreenRoot()
        #expect(type(of: screen.body) != Never.self)
    }
}
