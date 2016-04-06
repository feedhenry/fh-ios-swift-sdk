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

public class OAuthViewController: UIViewController, UIWebViewDelegate {
    var url: NSURL?
    var completionHandler: (Response, NSError?) -> Void = { (respo:Response, err:NSError?) -> Void in
    }
    private var authInfo: [String: AnyObject]?
    private var isFinished = false
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        let webView:UIWebView = UIWebView(frame: CGRectMake(0, 0, UIScreen.mainScreen().bounds.width, UIScreen.mainScreen().bounds.height))
        guard let url = url else {return}
        webView.loadRequest(NSURLRequest(URL: url))
        webView.delegate = self;
        self.view.addSubview(webView)
    }
    
    public func webView(webView: UIWebView, didFailLoadWithError error: NSError?) {
        print("Webview fail with error \(error)");
    }
    
    public func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        print("Start to load url: \(request.URL)")
        authInfo = [:]
        do {
            authInfo = try processQuery(request.URL?.query)
        } catch {
            print("OAuthViewController: an error occurs reading authResponse from cloud app.")
            return false
        }
        return true;
    }
    
    func processQuery(query: String?) throws -> [String: AnyObject]? {
        var authInfo: [String: AnyObject]? = [:]
        if let query = query where query.containsString("status=complete") {
            let pairs = query.componentsSeparatedByString("&")
            for (index, element) in pairs.enumerate() {
                print("Item \(index): \(element)")
                let keyValue = element.componentsSeparatedByString("=")
                if keyValue[0] == "authResponse" {
                    if let value = keyValue[1].stringByRemovingPercentEncoding,
                        let data = value.dataUsingEncoding(NSUTF8StringEncoding) {
                            let json = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
                            authInfo!["authResponse"] = json
                    }
                } else {
                    authInfo![keyValue[0]] = keyValue[1]
                }
            }
            isFinished = true
        }
        return authInfo
    }
    
    public func webViewDidStartLoad(webView: UIWebView) {
        print("Webview started Loading")
    }
    
    public func webViewDidFinishLoad(webView: UIWebView) {
        print("Webview did finish load")
        if isFinished {
            isFinished = false
            closeView()
        }
    }
    
    public func closeView() {
        presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
        let response = Response()
        response.parsedResponse = authInfo
        completionHandler(response, nil)
    }
}
