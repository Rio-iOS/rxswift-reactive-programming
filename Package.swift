// swift-tools-version: 5.9
import PackageDescription
let package = Package(name: "RepositoryActivityCore", platforms: [.macOS(.v12)], dependencies: [
    .package(url: "https://github.com/ReactiveX/RxSwift.git", exact: "6.7.1"),
], targets: [
    .target(name: "RepositoryActivityCore", dependencies: [
        .product(name: "RxSwift", package: "RxSwift"), .product(name: "RxCocoa", package: "RxSwift"),
    ], path: "RxSwiftExample/RxSwiftExample/Chapter08", exclude: ["Chapter08ActivityController.swift", "Chapter08Activity.storyboard"], sources: ["Chapter08Repository.swift", "RepositoryActivityViewModel.swift"]),
    .target(name: "EventCategoriesCore", dependencies: [
        .product(name: "RxSwift", package: "RxSwift"), .product(name: "RxCocoa", package: "RxSwift"),
    ], path: "RxSwiftExample/RxSwiftExample/Chapter10", exclude: ["Chapter10CategoriesViewController.swift", "Chapter10EventsViewController.swift", "Chapter10EventCell.swift", "Chapter10CategoriesView.storyboard", "Chapter10EventsView.storyboard"], sources: ["Model", "EventCategoriesViewModel.swift"]),
    .testTarget(name: "RepositoryActivityTests", dependencies: ["RepositoryActivityCore", "EventCategoriesCore"]),
])
