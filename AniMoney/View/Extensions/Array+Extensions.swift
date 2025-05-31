import Foundation

// MARK: - Transaction 日期篩選擴展
extension Array where Element == Transaction {
    func filtered(from startDate: Date?, to endDate: Date?) -> [Transaction] {
        guard let start = startDate, let end = endDate else {
            return self
        }
        
        return self.filter { transaction in
            transaction.date >= start && transaction.date <= end
        }
    }
}

// MARK: - String 擴展
extension String {
    func ranges(of searchString: String, options: CompareOptions = []) -> [Range<String.Index>] {
        var ranges: [Range<String.Index>] = []
        var searchStartIndex = self.startIndex
        
        while searchStartIndex < self.endIndex,
              let range = self.range(of: searchString, options: options, range: searchStartIndex..<self.endIndex) {
            ranges.append(range)
            searchStartIndex = range.upperBound
        }
        
        return ranges
    }
}
