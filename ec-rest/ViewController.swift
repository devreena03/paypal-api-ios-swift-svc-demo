//
//  ViewController.swift
//  ec-rest
//
//  Created by Kumari, Reena on 9/10/18.
//  Copyright © 2018 Kumari, Reena. All rights reserved.
//

import UIKit
import SafariServices

class ViewController: UIViewController, SFSafariViewControllerDelegate {
    
    let CURRENCY_INR: String = "INR";
    let CURRENCY_USD: String = "USD";
    
    let BASE_URL: String = "https://paypal-integration-sample.herokuapp.com";
    let CREATE_URL: String = "/api/paypal/ec/create-payment/";
    let RETURN_URL: String = "/api/paypal/ec/success";

    @IBOutlet weak var amount: UITextField!
    
    @IBOutlet weak var currency: UILabel!
    
    var svc: SFSafariViewController!
    var indicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad();
        amount.text = "1.00";
        currency.text = CURRENCY_INR;
        indicator = getActivityIndicator()
    }
    
    @IBAction func currencySwitch(_ sender: UISwitch) {
        if sender.isOn {
            currency.text = CURRENCY_INR;
        } else {
            currency.text = CURRENCY_USD;
        }
    }
    
    func payload() -> [String: Any] {
        
        var total_amount:Float = Float(self.amount.text!)!;
        print(total_amount);
        
        var body:[String: Any] = ["intent": "sale",
                    "payer": ["payment_method": "paypal"],
                    "application_context" : ["landing_page":"login",
                                     "user_action":"commit"],
                    "transactions": [
                             ["amount": [
                              "total": total_amount,
                              "currency": self.currency.text!
                                ]
                             ]
                     ],
                    "redirect_urls" : [
                        "return_url": BASE_URL + RETURN_URL,
                        "cancel_url": "com.reena.ec-rest://cancel"
                     ]
              ]
        return body;
    }
    
    @IBAction func pay(_ sender: Any) {
        
        let body = payload();
        let url = URL(string: BASE_URL+CREATE_URL);
        var request = URLRequest(url: url!);
        request.httpMethod = "POST";
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        request.httpBody = httpBody;
        self.startProgress();
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if error != nil {
                print(error!);
            } else {
                do {
                    let jsondata = try JSONSerialization.jsonObject(with: data!, options: []);
                    //print(jsondata);
                    if let values = jsondata as? [String: Any]{
                        if let links = values["links"] as? [Any] {
                            for link in links {
                                print(link);
                                if let link1 = link as? [String: String]{
                                    if link1["rel"] == "approval_url" {
                                        let approval_url:String = link1["href"]!;
                                        
                                        DispatchQueue.main.async {
                                           self.stopProgress();
                                           self.openUrlInSVC(url: approval_url);
                                        }
                                        break;
                                    }
                                }
                            }
                        }
                    }
                    
                    
                } catch {
                    print(error);
                }
            }
            
        }
        task.resume();
        
    }
    
    func openUrlInSVC(url: String) {
        print("enter safari view controller");
        print(url);
        svc = SFSafariViewController(url: URL(string: url)!);
        svc.delegate = self
        self.present(svc, animated: true, completion: nil);
        print("exit safari view controller");
    }

    func cancel(ecToken: String){
        print("cancel");
        DispatchQueue.main.async {
            self.displayAlertMessage(msg: "Payment cancelled, Ec-token: " + ecToken);
        }
    }
    
    func error(ecToken: String){
        print("error");
        DispatchQueue.main.async {
            self.displayAlertMessage(msg: "Some error occured, Ec-token: " + ecToken);
        }
    }
    
    func success(paymentId: String) {
        print("Success");
        DispatchQueue.main.async {
            self.displayAlertMessage(msg: "Payment completed, Payment Id: " + paymentId);
        }
    }
    
    func displayAlertMessage(msg: String){
        let alert = UIAlertController.init(title: "Alert", message: msg, preferredStyle: .alert)
        
        let userAction = UIAlertAction.init(title: "OK", style: .destructive, handler: nil)
        alert.addAction(userAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    func getActivityIndicator() -> UIActivityIndicatorView {
        let activityIndicator : UIActivityIndicatorView = UIActivityIndicatorView();
        activityIndicator.center = self.view.center;
        activityIndicator.hidesWhenStopped = true;
        activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray;
        
        return activityIndicator;
    }
    
    func startProgress() {
        view.addSubview(indicator);
        indicator.startAnimating();
    }
    
    func stopProgress() {
        indicator.stopAnimating();
    }
    
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        print("dismiss");
        controller.dismiss(animated: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

}

