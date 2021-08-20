
#if canImport(UIKit)

import UIKit

@available(iOS 11.0, *)
public protocol CountryCodePickerDelegate: AnyObject {
    func countryCodePickerViewControllerDidPickCountry(_ country: CountryCodePickerViewController.Country)
}

@available(iOS 11.0, *)
public class CountryCodePickerViewController: UITableViewController {

    lazy var searchController = UISearchController(searchResultsController: nil)

    public let phoneNumberKit: PhoneNumberKit

    let commonCountryCodes: [String]

    var shouldRestoreNavigationBarToHidden = false

    var hasCurrent = true
    var hasCommon = true

    lazy var allCountries = phoneNumberKit
        .allCountries()
        .compactMap({ Country(for: $0, with: self.phoneNumberKit) })
        .sorted(by: { $0.name.caseInsensitiveCompare($1.name) == .orderedAscending })
    
    lazy var commonCountries: [Country] = {
       return self.commonCountryCodes.compactMap({ Country(for: $0, with: phoneNumberKit) })
    }()

    var filteredCountries: [Country] = []

    public weak var delegate: CountryCodePickerDelegate?

    lazy var cancelButton = UIBarButtonItem(title: NSLocalizedString("cancel", comment: "back of country code"), style: .done, target: self, action: #selector(dismissAnimated))
    /**
     Init with a phone number kit instance. Because a PhoneNumberKit initialization is expensive you can must pass a pre-initialized instance to avoid incurring perf penalties.

     - parameter phoneNumberKit: A PhoneNumberKit instance to be used by the text field.
     - parameter commonCountryCodes: An array of country codes to display in the section below the current region section. defaults to `PhoneNumberKit.CountryCodePicker.commonCountryCodes`
     */
    public init(
        phoneNumberKit: PhoneNumberKit,
        commonCountryCodes: [String] = PhoneNumberKit.CountryCodePicker.commonCountryCodes)
    {
        self.phoneNumberKit = phoneNumberKit
        self.commonCountryCodes = commonCountryCodes
        super.init(style: .grouped)
        self.commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        self.phoneNumberKit = PhoneNumberKit()
        self.commonCountryCodes = PhoneNumberKit.CountryCodePicker.commonCountryCodes
        super.init(coder: aDecoder)
        self.commonInit()
    }

    func commonInit() {
        self.title = NSLocalizedString("Choose your country", comment: "Title of CountryCodePicker ViewController")
        tableView.register(Cell.self, forCellReuseIdentifier: Cell.reuseIdentifier)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.backgroundColor = .white
        navigationItem.searchController = searchController
        definesPresentationContext = true
        tableView.backgroundColor = .white
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black,
        NSAttributedString.Key.font: UIFont.systemFont(ofSize: 18, weight: UIFont.Weight.medium)]
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.hidesSearchBarWhenScrolling = false
        if let nav = navigationController, nav.isBeingPresented && nav.viewControllers.count == 1 {
            navigationItem.setRightBarButton(cancelButton, animated: true)
        }
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(shouldRestoreNavigationBarToHidden, animated: true)
    }

    @objc func dismissAnimated() {
        dismiss(animated: true)
    }

    func country(for indexPath: IndexPath) -> Country {
        if !isFiltering {
            if indexPath.section == 0 {
                return commonCountries[indexPath.row]
            } else {
                return allCountries[indexPath.row]
            }
        }
        return filteredCountries[indexPath.row]
    }

    public override func numberOfSections(in tableView: UITableView) -> Int {
        isFiltering ? 1 : 2
    }

    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if !isFiltering {
            if section == 0 {
                return commonCountries.count
            } else {
                return allCountries.count
            }
        }
        return filteredCountries.count
    }

    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Cell.reuseIdentifier, for: indexPath)
        let country = self.country(for: indexPath)

        cell.textLabel?.text = country.prefix + " " + country.flag
        cell.detailTextLabel?.text = country.name

        cell.textLabel?.textColor = .black
        cell.detailTextLabel?.textColor = .darkGray
        cell.textLabel?.font = .boldSystemFont(ofSize: 14.0)
        cell.detailTextLabel?.font = .systemFont(ofSize: 14.0)

        return cell
    }
    
    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let country = self.country(for: indexPath)
        delegate?.countryCodePickerViewControllerDidPickCountry(country)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    public override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if !isFiltering {
            let headerView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: tableView.frame.width, height: 50))
            let label = UILabel()
            label.frame = CGRect.init(x: 16, y: 10, width: headerView.frame.width-32, height: headerView.frame.height-10)
            label.textColor = UIColor.red
            label.font = UIFont.boldSystemFont(ofSize: 15.0)
            if section == 0 {
                label.text = NSLocalizedString("common_countries", value: "Common Countries", comment: "common_countries")
            } else {
                label.text = NSLocalizedString("all_countries", value: "All Countries", comment: "all_countries")
            }
            headerView.addSubview(label)
            return headerView
        } else {
            return nil
        }
    }

    public override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 48
    }
}

@available(iOS 11.0, *)
extension CountryCodePickerViewController: UISearchResultsUpdating {

    var isFiltering: Bool {
        searchController.isActive && !isSearchBarEmpty
    }

    var isSearchBarEmpty: Bool {
        searchController.searchBar.text?.isEmpty ?? true
    }

    public func updateSearchResults(for searchController: UISearchController) {
        let searchText = searchController.searchBar.text ?? ""
        filteredCountries = allCountries.filter { country in
            country.name.lowercased().contains(searchText.lowercased()) ||
                country.code.lowercased().contains(searchText.lowercased()) ||
                country.prefix.lowercased().contains(searchText.lowercased())
        }
        tableView.reloadData()
    }
}


// MARK: Types

@available(iOS 11.0, *)
public extension CountryCodePickerViewController {

    struct Country {
        var code: String
        var flag: String
        var name: String
        var prefix: String

        init?(for countryCode: String, with phoneNumberKit: PhoneNumberKit) {
            let flagBase = UnicodeScalar("🇦").value - UnicodeScalar("A").value
            guard
                let name = (Locale.current as NSLocale).localizedString(forCountryCode: countryCode),
                let prefix = phoneNumberKit.countryCode(for: countryCode)?.description
            else {
                return nil
            }

            self.code = countryCode
            self.name = name
            self.prefix = "+" + prefix
            self.flag = ""
            countryCode.uppercased().unicodeScalars.forEach {
                if let scaler = UnicodeScalar(flagBase + $0.value) {
                    flag.append(String(describing: scaler))
                }
            }
            if flag.count != 1 { // Failed to initialize a flag ... use an empty string
                return nil
            }
        }
    }

    class Cell: UITableViewCell {

        static let reuseIdentifier = "Cell"

        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: .value2, reuseIdentifier: Self.reuseIdentifier)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}

#endif
