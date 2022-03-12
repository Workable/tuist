import Foundation
import TSCBasic
import TuistSupport
import XCTest
@testable import TuistEnvKit
@testable import TuistSupportTesting

final class InstallerTests: TuistUnitTestCase {
    var buildCopier: MockBuildCopier!
    var versionsController: MockVersionsController!
    var subject: Installer!
    var tmpDir: TemporaryDirectory!

    override func setUp() {
        super.setUp()
        buildCopier = MockBuildCopier()
        versionsController = try! MockVersionsController()
        tmpDir = try! TemporaryDirectory(removeTreeOnDeinit: true)
        subject = Installer(
            buildCopier: buildCopier,
            versionsController: versionsController
        )
    }

    override func tearDown() {
        buildCopier = nil
        versionsController = nil
        tmpDir = nil
        subject = nil
        super.tearDown()
    }

    func test_install_when_bundled_release() throws {
        let version = "3.2.1"
        let temporaryPath = try temporaryPath()
        stubLocalAndRemoveSwiftVersions()
        let temporaryDirectory = try TemporaryDirectory(removeTreeOnDeinit: true)
        let downloadURL = URL(string: "https://github.com/tuist/tuist/releases/download/3.2.1/tuist.zip")!

        versionsController.installStub = { _, closure in
            try closure(temporaryPath)
        }

        let downloadPath = temporaryDirectory
            .path
            .appending(component: Constants.bundleName)
        system.succeedCommand([
            "/usr/bin/curl",
            "-LSs",
            "--output",
            downloadPath.pathString,
            downloadURL.absoluteString,
        ])
        system.succeedCommand([
            "/usr/bin/unzip",
            "-q",
            downloadPath.pathString,
            "-d",
            temporaryPath.pathString,
        ])

        try subject.install(
            version: version,
            temporaryDirectory: temporaryDirectory.path
        )

        XCTAssertPrinterOutputContains("""
        Downloading version 3.2.1
        Installing…
        Version \(version) installed
        """)
    }

    func test_install_when_bundled_release_and_download_fails() throws {
        let temporaryPath = try temporaryPath()
        let version = "3.2.1"
        stubLocalAndRemoveSwiftVersions()
        let temporaryDirectory = try TemporaryDirectory(removeTreeOnDeinit: true)
        let downloadURL = URL(string: "https://github.com/tuist/tuist/releases/download/3.2.1/tuist.zip")!

        versionsController.installStub = { _, closure in
            try closure(temporaryPath)
        }

        let downloadPath = temporaryDirectory
            .path
            .appending(component: Constants.bundleName)
        system.errorCommand(
            [
                "/usr/bin/curl",
                "-LSs",
                "--output",
                downloadPath.pathString,
                downloadURL.absoluteString,
            ],
            error: "download_error"
        )

        XCTAssertThrowsError(try subject.install(version: version, temporaryDirectory: temporaryDirectory.path))
    }

    func test_install_when_bundled_release_when_unzip_fails() throws {
        let temporaryPath = try temporaryPath()
        let version = "3.2.1"
        stubLocalAndRemoveSwiftVersions()
        let temporaryDirectory = try TemporaryDirectory(removeTreeOnDeinit: true)
        let downloadURL = URL(string: "https://github.com/tuist/tuist/releases/download/3.2.1/tuist.zip")!

        versionsController.installStub = { _, closure in
            try closure(temporaryPath)
        }

        let downloadPath = temporaryDirectory
            .path
            .appending(component: Constants.bundleName)
        system.succeedCommand([
            "/usr/bin/curl",
            "-LSs",
            "--output",
            downloadPath.pathString,
            downloadURL.absoluteString,
        ])
        system.errorCommand(
            [
                "/usr/bin/unzip",
                downloadPath.pathString,
                "-d",
                temporaryPath.pathString,
            ],
            error: "unzip_error"
        )

        XCTAssertThrowsError(try subject.install(version: version, temporaryDirectory: temporaryDirectory.path))
    }

    // MARK: - Fileprivate

    fileprivate func stubLocalAndRemoveSwiftVersions() {
        system.swiftVersionStub = { "5.0.0" }
    }
}
