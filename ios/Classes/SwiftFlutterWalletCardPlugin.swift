import Flutter
import PassKit
import UIKit

public class SwiftFlutterWalletCardPlugin: NSObject, FlutterPlugin {
  let viewController: UIViewController
  var addPassesFlutterResult: FlutterResult?
  var initialPassCount: Int?
    
  init(controller: UIViewController) {
    self.viewController = controller
  }
    
  public static func register(with registrar: FlutterPluginRegistrar) {
    let controller : UIViewController = (UIApplication.shared.delegate?.window??.rootViewController)!
    let channel = FlutterMethodChannel(name: "flutter_wallet_card", binaryMessenger: registrar.messenger())
    let instance = SwiftFlutterWalletCardPlugin(controller: controller)

    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {

    switch(call.method) {
        case "getPlatformVersion":
            result("iOS " + UIDevice.current.systemVersion)
        break;
        case "addWalletCard":
            guard let arguments = call.arguments as? [String : Any] else {return}
                let filePath = arguments["path"] as! String;
                let pkFile : NSData = NSData(contentsOfFile: filePath)!

                do {
                    let pass = try PKPass.init(data: pkFile as Data)
                    let vc = PKAddPassesViewController(pass: pass)
                    vc?.delegate = self
                    addPassesFlutterResult = result
                    initialPassCount = PKPassLibrary().passes().count
                    self.viewController.show(vc.unsafelyUnwrapped, sender: self)
                    print("addPassesFlutterResult", result)


                }
                catch {
                    result(false)
                }
        break;

        case "addMultipleWalletCards":
            guard let arguments = call.arguments as? [String : Any] else {return}
                let filePaths = arguments["paths"] as! [String];
                var passes = [PKPass]();
                for filePath in filePaths {
                    let pkFile : NSData = NSData(contentsOfFile: filePath)!
                    do {
                        let pass = try PKPass.init(data: pkFile as Data)
                        passes.append(pass)
                    }
                    catch {
                        result(false)
                    }
                }
                let vc = PKAddPassesViewController(passes: passes)
                self.viewController.show(vc.unsafelyUnwrapped, sender: self)

                result(true)
        break;
        case "isWalletAvailable":
            result(PKAddPassesViewController.canAddPasses())
        break;

        case "isWalletCardAdded":
            /// get the serial number of the pass from the arguments and the
            guard let arguments = call.arguments as? [String : Any] else {return}
            let serialNumber = arguments["serialNumber"] as! String
            print("serialNumber", serialNumber)
            /// get the first index of the pass from the wallet by serialNumber, first where serialNumber == pass.serialNumber
            let passSerialNumber = PKPassLibrary().passes().first(where: { $0.serialNumber == serialNumber })?.serialNumber
            let passes1 = PKPassLibrary().pass(withPassTypeIdentifier: "pass.com.demirbank.kg", serialNumber:"RGVtaXJiYW5rIFFy")
            print("passesDemir", passes1)
            /// check if the pass is added to the wallet
             print("serialNumberSWallet", PKPassLibrary().passes())
            if passSerialNumber == serialNumber {
                result(true)
            } else {
                result(false)
            }
        case "viewWalletCardInWallet":
            /// get the serial number of the pass from the arguments and the
            guard let arguments = call.arguments as? [String : Any] else {return}
            let serialNumber = arguments["serialNumber"] as! String;
            /// get the first index of the pass from the wallet by serialNumber, first where serialNumber == pass.serialNumber
            let pass = PKPassLibrary().passes().first(where: { $0.serialNumber == serialNumber })

            /// check if the pass exists
            if let passURL = pass?.passURL {
                UIApplication.shared.open(passURL) { success in
                    result(success)
                }
            } else {
                result(false)
            }
        default:
            result(FlutterMethodNotImplemented);
        break;
    }
  }
}

extension SwiftFlutterWalletCardPlugin: PKAddPassesViewControllerDelegate {
    public func addPassesViewControllerDidFinish(_ controller: PKAddPassesViewController) {
        if  let initialPassCount = initialPassCount, let addPassesFlutterResult = addPassesFlutterResult {
            let newPassCount = PKPassLibrary().passes().count
            controller.dismiss(animated: true, completion: nil)
            addPassesFlutterResult(newPassCount > initialPassCount)
        }
    }
}
