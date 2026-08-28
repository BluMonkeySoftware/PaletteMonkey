// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————
//
// PreviewMode.swift
//
//
// Created by Steven Marcotte on 2026-Aug-27
// Copyright (c) 1996 - 2026 Steven Marcotte, All Rights Reserved
//
// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

import Foundation


// MARK: -
// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

enum PreviewMode: String, CaseIterable, Identifiable {

    case chips  = "Chips"
    case rule   = "60·30·10"
    case mantia = "Mantia grid"

    var id: String { rawValue }
    var label: String { rawValue }
}
