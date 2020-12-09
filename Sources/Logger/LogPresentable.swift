//
//  LogPresentable.swift
//  
//
//  Created by Madimo on 2020/12/8.
//

import Foundation

public protocol LogListener: AnyObject {
    func receive(_ log: SerializedLog)
}

public protocol LogPresentable {

    func addLogListener(_ listener: LogListener)
    func removeLogListener(_ listener: LogListener)

    func getLogCount(_ completion: @escaping (Int) -> Void)
    func getLogs(filter: ConditionLogFilter, before: SerializedLog?, count: Int, completion: @escaping ([SerializedLog]) -> Void)
    func getAllTags(completion: @escaping ([Tag]) -> Void)
    func deleteLogs(_ logs: [SerializedLog])
    func deleteAllLogs()
    func export(completion: @escaping (URL) -> Void)

}
