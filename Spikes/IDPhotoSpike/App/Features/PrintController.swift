import OSLog
import PDFKit
import UIKit

/// AirPrint bridge for the sheet PDF. UIKit is used only because SwiftUI has no printing surface.
@MainActor
final class PrintController: NSObject, UIPrintInteractionControllerDelegate {
    static let shared = PrintController()
    private let logger = Logger(subsystem: "com.jarbasferro.IDPhotoSpike", category: "Print")
    private var pageSize: CGSize = .zero
    private(set) var lastPaperChoice: String?

    static var isAvailable: Bool { UIPrintInteractionController.isPrintingAvailable }

    func present(pdf: URL, jobName: String) {
        guard let document = CGPDFDocument(pdf as CFURL), let page = document.page(at: 1) else { return }
        pageSize = page.getBoxRect(.mediaBox).size
        let info = UIPrintInfo.printInfo()
        info.outputType = .photo // default paper 4x6 / A6 on photo-capable printers; simplex
        info.jobName = jobName
        info.duplex = .none
        let controller = UIPrintInteractionController.shared
        controller.printInfo = info
        controller.printingItem = pdf
        controller.showsPaperSelectionForLoadedPapers = true
        controller.showsNumberOfCopies = true
        controller.delegate = self
        controller.present(animated: true) { [weak self] _, completed, error in
            if let error { self?.logger.error("Print failed: \(error.localizedDescription, privacy: .public)") }
            self?.logger.info("Print sheet dismissed, completed: \(completed, privacy: .public)")
        }
    }

    /// Prefer a bordered paper of the right size over its borderless twin: borderless expands the image ~2 %.
    func printInteractionController(_ controller: UIPrintInteractionController,
                                    choosePaper paperList: [UIPrintPaper]) -> UIPrintPaper {
        for paper in paperList {
            let size = paper.paperSize, printable = paper.printableRect
            logger.info("Printer paper \(Self.mm(size.width), privacy: .public) × \(Self.mm(size.height), privacy: .public) mm, printable \(Self.mm(printable.width), privacy: .public) × \(Self.mm(printable.height), privacy: .public) mm")
        }
        let best = UIPrintPaper.bestPaper(forPageSize: pageSize, withPapersFrom: paperList)
        let sameSize = paperList.filter { $0.paperSize.equalTo(best.paperSize) }
        let bordered = sameSize.first { $0.printableRect.width < $0.paperSize.width - 1 || $0.printableRect.height < $0.paperSize.height - 1 }
        let chosen = bordered ?? best
        lastPaperChoice = "\(Self.mm(chosen.paperSize.width)) × \(Self.mm(chosen.paperSize.height)) mm"
        logger.info("Chosen paper \(self.lastPaperChoice ?? "", privacy: .public) for page \(Self.mm(self.pageSize.width), privacy: .public) × \(Self.mm(self.pageSize.height), privacy: .public) mm")
        return chosen
    }

    private static func mm(_ points: CGFloat) -> String {
        Double(points / 72 * 25.4).formatted(.number.precision(.fractionLength(1)))
    }
}
