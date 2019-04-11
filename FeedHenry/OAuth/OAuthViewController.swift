/*
* Copyright Red Hat, Inc., and individual contributors
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
*     http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/

/**
 Present a customized UIWebView to perform OAuth authentication.
 */
open class OAuthViewController: UIViewController, UIWebViewDelegate {
    var url: URL?
    var completionHandler: (Response, NSError?) -> Void = { (respo:Response, err:NSError?) -> Void in
    }
    fileprivate var authInfo: [String: AnyObject]?
    fileprivate var isFinished = false
    
    /// Override standard method to make the view full screen.
    override open func viewDidLoad() {
        super.viewDidLoad()
        let webView:UIWebView = UIWebView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height))
        guard let url = url else {return}
        webView.loadRequest(URLRequest(url: url))
        webView.delegate = self;
        self.view.addSubview(webView)
    }
    
    /// Override to deal with error.
    open func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        print("Webview fail with error \(error)");
    }
    
    /// Override to retrieve auth token and store it.
    open func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebView.NavigationType) -> Bool {
        print("Start to load url: \(String(describing: request.url))")
        authInfo = [:]
        do {
            authInfo = try processQuery(request.url?.query)
        } catch {
            print("OAuthViewController: an error occurs reading authResponse from cloud app.")
            return false
        }
        return true;
    }
    
    func processQuery(_ query: String?) throws -> [String: AnyObject]? {
        var authInfo: [String: AnyObject]? = [:]
        if let query = query, query.contains("status=complete") {
            let pairs = query.components(separatedBy: "&")
            for (index, element) in pairs.enumerated() {
                print("Item \(index): \(element)")
                let keyValue = element.components(separatedBy: "=")
                if keyValue[0] == "authResponse" {
                    if let value = keyValue[1].removingPercentEncoding,
                        let data = value.data(using: String.Encoding.utf8) {
                            let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
                            authInfo!["authResponse"] = json as AnyObject?
                    }
                } else {
                    authInfo![keyValue[0]] = keyValue[1] as AnyObject?
                }
            }
            isFinished = true
        }
        return authInfo
    }
    
    /// Override for logging purpose.
    open func webViewDidStartLoad(_ webView: UIWebView) {
        print("Webview started Loading")
    }
    
    /// Override to close the view on success.
    open func webViewDidFinishLoad(_ webView: UIWebView) {
        print("Webview did finish load")
        if isFinished {
            isFinished = false
            closeView()
        }
    }
    
    /// Dismiss controller on success.
    open func closeView() {
        presentingViewController?.dismiss(animated: true, completion: nil)
        let response = Response()
        response.parsedResponse = authInfo as NSDictionary?
        completionHandler(response, nil)
    }
}
