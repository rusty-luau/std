<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="assets/logo-white.svg">
    <img src="assets/logo-black.svg" alt="rusty-luau" width="200" />
  </picture>
</p>

<p align="center">
  <a href="README.ko.md">한국어</a>
</p>

# rusty-luau/std

The Rust-inspired standard library for Luau, built on top of [Lute](https://github.com/luau-lang/lute).

## Overview

Luau is sandboxed by default and primarily embedded in larger hosts such as Roblox, so its ecosystem of free-standing utilities is thin compared to a language like Rust. Some Rust building blocks — `Result`, `Option`, `Future` — already have community ports, but deeper machinery such as `Iter<T>` and the broader standard-library surface has been missing. This repository attempts to fill that gap by porting Rust's standard library to Luau in an idiomatic way.

## Goals

Provide Rust-flavored building blocks, written with Rust-inspired conventions: `snake_case` methods, `Result`-based error handling, exhaustive case coverage, and so on. The long-term aim is to cover most of what a Rust developer would reach for in `std` — starting with the algebraic data types and growing outward into iterators, collections, and beyond.

The project is intentionally ambitious. Whether the result turns out practical for production or game development is an open question; the value is in giving Luau developers familiar abstractions and giving Rust developers a less foreign on-ramp into Luau.

## Status

Pre-`0.1.0`. The library has not yet been tagged for a minor release. Until things stabilize there is no installation guide, no quickstart, and no rendered documentation site (e.g. `rusty-luau.github.io`).

## Documentation

In-source doc comments are written in the [moonwave](https://eryn.io/moonwave/) format for now. A dedicated docgen targeting rusty-luau conventions may be developed later if moonwave proves insufficient for what we want to express.

## About AI

This project uses AI agents. We use them only for:

- Writing test cases
- Authoring and consulting on complex types and type functions
- Documentation
- Translation

All output from AI agents goes through additional human review.
