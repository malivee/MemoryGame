import UIKit

/// Computes page breaks without constructing textures or scene nodes.
struct JournalPaginator {
    let textRect: CGRect
    let illustratedTextRect: CGRect
    let textAttributes: [NSAttributedString.Key: Any]

    func paginate() -> [JournalPage] {
        var pages: [JournalPage] = []
        for entry in IsoldeJournalEntry.entries {
            if entry.localLanguage {
                pages.append(JournalPage(entry: entry, scribbles: true))
                pages.append(JournalPage(entry: entry, illustration: entry.illustration, scribbles: true))
            } else if entry.journal.isEmpty {
                pages.append(JournalPage(entry: entry))
                pages.append(JournalPage(entry: entry, illustration: entry.illustration))
            } else {
                var remaining = entry.journal
                var first = true
                while !remaining.isEmpty {
                    let illustration = !first && pages.count % 2 == 1 ? entry.illustration : nil
                    let rect = illustration == nil ? textRect : illustratedTextRect
                    let chunk = takeText(from: &remaining, fitting: rect)
                    pages.append(JournalPage(entry: entry, text: chunk, illustration: illustration, heading: first))
                    first = false
                    // Illustration appears once, on the first right-hand page.
                    if pages.count % 2 == 0 { break }
                }
                while !remaining.isEmpty {
                    pages.append(JournalPage(entry: entry, text: takeText(from: &remaining, fitting: textRect)))
                }
                if pages.last?.heading == true, let illustration = entry.illustration {
                    pages.append(JournalPage(entry: entry, illustration: illustration))
                }
            }
            // Start each new record on a fresh spread.
            if pages.count % 2 != 0 { pages.append(JournalPage(entry: entry)) }
        }
        return pages
    }


    private func takeText(from remaining: inout String, fitting rect: CGRect) -> String {
        let words = remaining.components(separatedBy: " ")
        var chunk = ""
        var consumed = 0
        for word in words {
            let candidate = chunk.isEmpty ? word : chunk + " " + word
            let height = (candidate as NSString).boundingRect(
                with: CGSize(width: rect.width, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: textAttributes, context: nil).height
            if ceil(height) > rect.height && consumed > 0 { break }
            chunk = candidate
            consumed += 1
        }
        remaining = words.dropFirst(consumed).joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        return chunk.trimmingCharacters(in: .whitespacesAndNewlines)
    }

}
