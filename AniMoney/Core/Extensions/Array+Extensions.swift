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

