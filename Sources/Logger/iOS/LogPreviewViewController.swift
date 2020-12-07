//
//  LogPreviewViewController.swift
//  Logger
//
//
//  Created by Madimo on 2019/12/11.
//  Copyright © 2019 Madimo. All rights reserved.
//

#if canImport(UIKit)

import UIKit

open class LogsViewController: UIViewController {

    private let presentable: LogPresentable
    private var viewModels = [ViewModel]()
    private lazy var displaying = viewModels

    private lazy var tableView: UITableView = {
        let view = UITableView(frame: .zero, style: .plain)
        view.keyboardDismissMode = .interactive
        view.register(LogCell.self, forCellReuseIdentifier: NSStringFromClass(LogCell.self))
        view.refreshControl = UIRefreshControl()
        view.refreshControl?.addTarget(
            self,
            action: #selector(onRefresh),
            for: .valueChanged
        )
        view.dataSource = self
        view.delegate = self
        return view
    }()

    private lazy var filterController: FilterViewController = {
        let controller = FilterViewController(allTags: Set(viewModels.map { $0.log.tag }))
        controller.onSelectionChanged = { [weak self] in
            self?.reloadData()
        }
        return controller
    }()

    private lazy var searchController: UISearchController = {
        let controller = UISearchController()
        controller.obscuresBackgroundDuringPresentation = false
        controller.searchBar.showsSearchResultsButton = true
        controller.searchBar.delegate = self
        controller.delegate = self
        controller.searchResultsUpdater = self
        return controller
    }()

    public init(presentable: LogPresentable) {
        self.presentable = presentable

        super.init(nibName: nil, bundle: nil)
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override open func viewDidLoad() {
        super.viewDidLoad()

        setupViews()
        onRefresh()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleKeyboardNotification(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
    }

    private func setupViews() {
        title = "Logs"

        view.addSubview(tableView)

        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
            tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        if #available(iOS 11.0, *) {
            navigationItem.searchController = searchController
        } else {
            tableView.tableHeaderView = searchController.view
        }
    }

    @objc private func handleKeyboardNotification(_ notification: NSNotification) {
        guard let keyboardFrame = notification
                .userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
        else { return }

        let realFrame = view.convert(keyboardFrame, from: nil)
        var height = view.bounds.height - realFrame.origin.y

        if #available(iOS 11.0, *) {
            height -= tableView.adjustedContentInset.bottom - tableView.contentInset.bottom
        }

        height = max(height, 0)

        tableView.contentInset.bottom = height
        tableView.scrollIndicatorInsets.bottom = height
    }

    @objc private func onRefresh() {
        viewModels = presentable.logs.map { ViewModel(log: $0) }
        reloadData()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.tableView.refreshControl?.endRefreshing()
        }
    }

    private func reloadData() {
        let filteredViewModels = viewModels
            .filter {
                filterController.selectedLevels.contains($0.log.level) &&
                    filterController.selectedTags.contains($0.log.tag)
            }

        guard let text = searchController.searchBar.text?.lowercased(), !text.isEmpty else {
            displaying = filteredViewModels
            tableView.reloadData()
            return
        }

        displaying = filteredViewModels
            .filter {
                $0.log.message.lowercased().contains(text) ||
                    $0.log.tag.name.lowercased().contains(text) ||
                    $0.log.file.lowercased().contains(text) ||
                    $0.log.function.lowercased().contains(text)
            }

        tableView.reloadData()
    }

}

// MARK: UITableViewDataSource & UITableViewDelegate

extension LogsViewController: UITableViewDataSource, UITableViewDelegate {

    public func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        displaying.count
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let width: CGFloat = {
            if #available(iOS 11.0, *) {
                return tableView.safeAreaLayoutGuide.layoutFrame.width
            } else {
                return tableView.bounds.width
            }
        }()

        return displaying[indexPath.row].height(forContainerWidth: width)
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(LogCell.self), for: indexPath) as! LogCell
        cell.viewModel = displaying[indexPath.row]
        return cell
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        displaying[indexPath.row].isExpanded.toggle()

        tableView.reloadRows(at: [[0, indexPath.row]], with: .automatic)
    }

    @available(iOS 13.0, *)
    public func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let viewModel = displaying[indexPath.row]

        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            return UIMenu(title: "", children: [
                UIAction(title: "Copy", image: UIImage(systemName: "doc.on.doc")) { _ in
                    UIPasteboard.general.string = viewModel.messageText.string
                },
            ])
        }
    }

}

// MARK: UISearchControllerDelegate & UISearchResultsUpdating

extension LogsViewController: UISearchControllerDelegate, UISearchBarDelegate, UISearchResultsUpdating {

    public func willPresentSearchController(_ searchController: UISearchController) {
        searchController.searchBar.setShowsCancelButton(true, animated: true)
    }

    public func willDismissSearchController(_ searchController: UISearchController) {
        searchController.searchBar.setShowsCancelButton(false, animated: true)
    }

    public func searchBarResultsListButtonClicked(_ searchBar: UISearchBar) {
        filterController.modalPresentationStyle = .popover
        filterController.popoverPresentationController?.sourceView = searchController.searchBar
        filterController.popoverPresentationController?.delegate = self
        present(filterController, animated: true, completion: nil)
    }

    public func updateSearchResults(for searchController: UISearchController) {
        reloadData()
    }

}

// MARK: UIPopoverPresentationControllerDelegate

extension LogsViewController: UIPopoverPresentationControllerDelegate {

    public func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        .none
    }

}

// MARK: -

extension LogsViewController {

    private class LogCell: UITableViewCell {

        var viewModel: ViewModel? {
            didSet {
                guard let viewModel = viewModel else { return }

                messageLabel.attributedText = viewModel.messageText
                middleTextLabel.text = viewModel.middleText
                middleTextLabel.isHidden = !viewModel.isExpanded
                levelLabel.text = viewModel.levelText
                levelLabel.backgroundColor = viewModel.levelBackgroundColor
                dateLabel.text = viewModel.dateText
                tagLabel.text = viewModel.tagText

                messageContainerView.layer.mask = !viewModel.isExpanded && viewModel.shouldMaskMessage ? messageMaskLayer : nil

                if viewModel.isExpanded {
                    lastLineToMessageConstraint.isActive = false
                    lastLineToMiddleTextConstraint.isActive = true
                } else {
                    lastLineToMessageConstraint.isActive = true
                    lastLineToMiddleTextConstraint.isActive = false
                }
            }
        }

        private var lastLineToMessageConstraint: NSLayoutConstraint!
        private var lastLineToMiddleTextConstraint: NSLayoutConstraint!

        private lazy var messageContainerView: UIView = {
            let view = UIView()
            return view
        }()

        private lazy var messageLabel: UILabel = {
            let view = UILabel()
            view.numberOfLines = 0
            return view
        }()

        private lazy var messageMaskLayer: CAGradientLayer = {
            let layer = CAGradientLayer()
            layer.colors = [UIColor.white.cgColor, UIColor.clear.cgColor]
            layer.startPoint = CGPoint(x: 0.5, y: 0.8)
            layer.endPoint = CGPoint(x: 0.5, y: 1)
            return layer
        }()

        private lazy var middleTextLabel: UILabel = {
            let view = UILabel()
            view.font = UIFont(name: "Verdana", size: 11)
            view.textColor = .systemGray
            view.numberOfLines = 1
            view.lineBreakMode = .byTruncatingTail
            view.setContentHuggingPriority(.required, for: .vertical)
            view.setContentCompressionResistancePriority(.required, for: .vertical)
            return view
        }()

        private lazy var lastLineContentView: UIStackView = {
            let view = UIStackView()
            view.axis = .horizontal
            view.distribution = .fillProportionally
            view.alignment = .fill
            view.spacing = 6
            view.setContentHuggingPriority(.required, for: .vertical)
            view.setContentCompressionResistancePriority(.required, for: .vertical)
            return view
        }()

        private lazy var levelLabel: UILabel = {
            let view = UILabel()
            view.textColor = .white
            view.font = monoFont(ofSize: 10, weight: .medium)
            view.textAlignment = .center
            view.layer.cornerRadius = 4
            view.layer.masksToBounds = true
            view.widthAnchor.constraint(equalToConstant: 44).isActive = true
            view.heightAnchor.constraint(equalToConstant: 14).isActive = true
            return view
        }()

        private lazy var dateLabel: UILabel = {
            let view = UILabel()
            view.font = .systemFont(ofSize: 12)
            view.textColor = .systemGray
            view.setContentHuggingPriority(.required, for: .horizontal)
            view.setContentCompressionResistancePriority(.required, for: .horizontal)
            return view
        }()

        private lazy var tagLabel: UILabel = {
            let view = UILabel()
            view.font = .systemFont(ofSize: 12)
            view.textColor = .systemGray
            view.textAlignment = .right
            return view
        }()

        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)

            setupViews()
        }

        required init?(coder: NSCoder) {
            super.init(coder: coder)

            setupViews()
        }

        private func setupViews() {
            selectionStyle = .none
            contentView.clipsToBounds = true

            contentView.addSubview(messageContainerView)
            contentView.addSubview(middleTextLabel)
            contentView.addSubview(lastLineContentView)
            messageContainerView.addSubview(messageLabel)
            lastLineContentView.addArrangedSubview(levelLabel)
            lastLineContentView.addArrangedSubview(dateLabel)
            lastLineContentView.addArrangedSubview(tagLabel)

            messageContainerView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                messageContainerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
                messageContainerView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16),
                messageContainerView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -16)
            ])

            messageLabel.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                messageLabel.topAnchor.constraint(equalTo: messageContainerView.topAnchor),
                messageLabel.leftAnchor.constraint(equalTo: messageContainerView.leftAnchor),
                messageLabel.rightAnchor.constraint(equalTo: messageContainerView.rightAnchor)
            ])

            middleTextLabel.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                middleTextLabel.topAnchor.constraint(equalTo: messageContainerView.bottomAnchor, constant: 8),
                middleTextLabel.leftAnchor.constraint(equalTo: messageContainerView.leftAnchor),
                middleTextLabel.rightAnchor.constraint(equalTo: messageContainerView.rightAnchor)
            ])

            lastLineContentView.translatesAutoresizingMaskIntoConstraints = false
            lastLineToMessageConstraint = lastLineContentView.topAnchor.constraint(equalTo: messageContainerView.bottomAnchor, constant: 8)
            lastLineToMiddleTextConstraint = lastLineContentView.topAnchor.constraint(equalTo: middleTextLabel.bottomAnchor, constant: 6)

            NSLayoutConstraint.activate([
                lastLineContentView.leftAnchor.constraint(equalTo: messageContainerView.leftAnchor),
                lastLineContentView.rightAnchor.constraint(equalTo: messageContainerView.rightAnchor),
                lastLineContentView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6)
            ])
        }

        override func layoutSubviews() {
            super.layoutSubviews()

            messageContainerView.layoutIfNeeded()
            messageMaskLayer.frame = messageContainerView.bounds
        }

        private func monoFont(ofSize size: CGFloat, weight: UIFont.Weight = .regular) -> UIFont? {
            if #available(iOS 13.0, *) {
                return UIFont.monospacedSystemFont(ofSize: size, weight: weight)
            } else {
                return UIFont(name: "Verdana", size: size)
            }
        }

    }

}

// MARK: -

extension LogsViewController {

    private class ViewModel {

        private static let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy.MM.dd HH:mm:ss.SSS"
            return formatter
        }()

        private static let messageFont: UIFont = {
            return UIFont(name: "Verdana", size: 12)!
        }()

        private static let messageLineSpacing: CGFloat = 3

        private static let messageAttributes: [NSAttributedString.Key : Any] = {
            let style = NSMutableParagraphStyle()
            style.lineSpacing = messageLineSpacing

            return [
                .font: messageFont,
                .paragraphStyle: style
            ]
        }()

        var id = UUID()
        var log: Log
        var messageText: NSAttributedString
        var middleText: String
        var levelText: String
        var levelBackgroundColor: UIColor
        var dateText: String
        var tagText: String

        var isExpanded = false
        var shouldMaskMessage = false

        init(log: Log) {
            self.log = log

            switch log.level {
            case .trace: levelBackgroundColor = .systemGray
            case .info: levelBackgroundColor = .systemPurple
            case .debug: levelBackgroundColor = .systemBlue
            case .warning: levelBackgroundColor = .systemOrange
            case .error: levelBackgroundColor = .systemPink
            case .fatal: levelBackgroundColor = .systemRed
            }

            var message = log.message.trimmingCharacters(in: .whitespacesAndNewlines)
            message = message.isEmpty ? "<Empty>" : message
            messageText = NSAttributedString(string: message, attributes: Self.messageAttributes)

            middleText = "\(log.file):\(log.line) - \(log.function)"
            levelText = log.level.description
            dateText = Self.dateFormatter.string(from: log.date)
            tagText = log.tag == .default ? "" : log.tag.name.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        private var containerWidth: CGFloat = 0
        private var compressHeight: CGFloat = 0
        private var expendedHeight: CGFloat = 0

        func height(forContainerWidth width: CGFloat) -> CGFloat {
            if containerWidth == width {
                if isExpanded {
                    if expendedHeight != 0 {
                        return expendedHeight
                    }
                } else {
                    if compressHeight != 0 {
                        return compressHeight
                    }
                }
            }

            caculateHeight(forContainerWidth: width)
            return height(forContainerWidth: width)
        }

        private func caculateHeight(forContainerWidth width: CGFloat) {
            let expendedMessageHeight = ceil(messageText.boundingRect(
                    with: CGSize(width: width - 32, height: .infinity),
                    options: [.usesFontLeading, .usesLineFragmentOrigin],
                    context: nil
                ).height)
            var compressMessageHeight: CGFloat

            let ctFrame = CTFramesetterCreateFrame(
                CTFramesetterCreateWithAttributedString(messageText),
                CFRangeMake(0, messageText.length),
                CGPath(rect: CGRect(origin: .zero, size: CGSize(width: width, height: expendedMessageHeight)), transform: nil),
                nil
            )

            let maxLine = 6
            if CFArrayGetCount(CTFrameGetLines(ctFrame)) > maxLine {
                compressMessageHeight = Self.messageFont.lineHeight * CGFloat(maxLine) + Self.messageLineSpacing * CGFloat(maxLine - 1)
                shouldMaskMessage = true
            } else {
                compressMessageHeight = expendedMessageHeight
            }

            var height: CGFloat = 0
            height += 8 // message.top
            height += 8 // message.bottom
            height += 14 // lastLine.height
            height += 6 // lastLine.bottom

            compressHeight = compressMessageHeight + height
            expendedHeight = expendedMessageHeight + height
            expendedHeight += 14 // middleText.height
            expendedHeight += 6 // middleText.bottom

            containerWidth = width
        }

    }

}

// MARK: -

extension LogsViewController {

    private class FilterViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

        private static let levelsFilterUserDefaultsKey = "com.Madimo.Logger.LogsViewController.Filter.Levels"
        private static let tagsFilterUserDefaultsKey = "com.Madimo.Logger.LogsViewController.Filter.Tags"

        private(set) var selectedLevels: Set<Level> = {
            if let rawLevels = UserDefaults.standard.array(forKey: levelsFilterUserDefaultsKey) as? [Int] {
                let levels = Set(rawLevels.compactMap { Level(rawValue: $0) })

                if !levels.isEmpty {
                    return levels
                }
            }

            return Set(Level.allCases)
        }() {
            didSet {
                UserDefaults.standard.set(selectedLevels.map { $0.rawValue }, forKey: Self.levelsFilterUserDefaultsKey)
            }
        }

        private(set) var selectedTags: Set<Tag> = {
            if let rawTags = UserDefaults.standard.array(forKey: tagsFilterUserDefaultsKey) as? [String] {
                let tags = Set(rawTags.compactMap { Tag(name: $0) })

                if !tags.isEmpty {
                    return tags
                }
            }

            return []
        }() {
            didSet {
                UserDefaults.standard.set(selectedTags.map { $0.name }, forKey: Self.tagsFilterUserDefaultsKey)
            }
        }

        var onSelectionChanged: (() -> Void)?

        private let allTags: [Tag]

        private(set) lazy var tableView: UITableView = {
            let view = UITableView(frame: .zero, style: .grouped)
            view.clipsToBounds = true
            view.rowHeight = 44
            view.sectionHeaderHeight = 32
            view.sectionFooterHeight = 8
            view.register(UITableViewCell.self, forCellReuseIdentifier: NSStringFromClass(UITableViewCell.self))
            view.dataSource = self
            view.delegate = self
            return view
        }()

        init(allTags: Set<Tag>) {
            self.allTags = allTags.sorted(by: { $0.name < $1.name })

            if selectedTags.isEmpty {
                selectedTags = allTags
            }

            super.init(nibName: nil, bundle: nil)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func viewDidLoad() {
            super.viewDidLoad()

            setupViews()
        }

        private func setupViews() {
            var height: CGFloat = tableView.rowHeight * CGFloat(Level.allCases.count) +
                tableView.sectionHeaderHeight + tableView.sectionFooterHeight

            if !allTags.isEmpty {
                height += tableView.rowHeight * CGFloat(allTags.count) +
                    tableView.sectionHeaderHeight + tableView.sectionFooterHeight
            }

            preferredContentSize = CGSize(
                 width: UIView.noIntrinsicMetric,
                 height: height
            )

            view.addSubview(tableView)

            tableView.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                tableView.topAnchor.constraint(equalTo: view.topAnchor),
                tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
                tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
                tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        }

        func numberOfSections(in tableView: UITableView) -> Int {
            allTags.isEmpty ? 1 : 2
        }

        func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
            switch section {
            case 0:
                return "LEVELS"
            case 1:
                return "TAGS"
            default:
                return ""
            }
        }

        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            switch section {
            case 0:
                return Level.allCases.count
            case 1:
                return allTags.count
            default:
                fatalError()
            }
        }

        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(UITableViewCell.self), for: indexPath)
            cell.textLabel?.font = UIFont.systemFont(ofSize: 13)

            switch indexPath.section {
            case 0:
                let level = Level.allCases[indexPath.row]
                cell.textLabel?.text = level.description
                cell.accessoryType = selectedLevels.contains(level) ? .checkmark : .none
            case 1:
                let tag = allTags[indexPath.row]
                cell.textLabel?.text = tag.name
                cell.accessoryType = selectedTags.contains(tag) ? .checkmark : .none
            default:
                fatalError()
            }

            return cell
        }

        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            defer { tableView.deselectRow(at: indexPath, animated: true) }
            guard let cell = tableView.cellForRow(at: indexPath) else { return }

            switch indexPath.section {
            case 0:
                let level = Level.allCases[indexPath.row]

                if selectedLevels.contains(level) {
                    selectedLevels.remove(level)
                    cell.accessoryType = .none
                } else {
                    selectedLevels.insert(level)
                    cell.accessoryType = .checkmark
                }
            case 1:
                let tag = allTags[indexPath.row]

                if selectedTags.contains(tag) {
                    selectedTags.remove(tag)
                    cell.accessoryType = .none
                } else {
                    selectedTags.insert(tag)
                    cell.accessoryType = .checkmark
                }
            default:
                fatalError()
            }

            onSelectionChanged?()
        }

    }

}

#endif
