//
//  ImageViewController.swift
//  BCD
//
//  Created by Liuliet.Lee on 17/6/2017.
//  Copyright © 2017 Liuliet.Lee. All rights reserved.
//

import UIKit
import GoogleMobileAds

class ImageViewController: UIViewController, VideoCoverDelegate, GADBannerViewDelegate {
    
    @IBOutlet weak var adButton: UIBarButtonItem!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var urlLabel: UILabel!
    @IBOutlet weak var downloadButton: UIBarButtonItem!
    @IBOutlet weak var pushButton: UIButton!
    
    var cover: BilibiliCover?
    var itemFromHistory: History?
    fileprivate let netModel = NetworkingModel()
    fileprivate let dataModel = CoreDataModel()
    fileprivate var loadingView: LoadingView!
    fileprivate var image = UIImage() {
        willSet {
            imageView.image = newValue
        }
    }
    
    lazy var adBannerView: GADBannerView = {
        let adBannerView = GADBannerView(adSize: kGADAdSizeSmartBannerPortrait)
        adBannerView.adUnitID = "ca-app-pub-9289196786381154/6636960629"
        adBannerView.delegate = self
        adBannerView.rootViewController = self
        
        return adBannerView
    }()
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        isShowingImage = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        isShowingImage = true
        netModel.delegateForVideo = self
        if let cover = cover {
            title = cover.shortDescription
            if itemFromHistory == nil {
                switch cover.type {
                case .video: netModel.getInfoFromAvNumber(avNum: cover.number)
                case .live:  netModel.getLiveInfo(lvNum: cover.number)
                }
            }
        } else {
            title = "No av number"
            print("No av number")
        }
        
        if itemFromHistory == nil {
            titleLabel.text = ""
            authorLabel.text = ""
            urlLabel.text = ""
            
            disableButtons()
            
            loadingView = LoadingView(frame: view.bounds)
            view.addSubview(loadingView)
            view.bringSubview(toFront: loadingView)
        } else {
            titleLabel.text = itemFromHistory!.title!
            authorLabel.text = itemFromHistory!.up!
            urlLabel.text = itemFromHistory!.url!
            imageView.image = UIImage(data: itemFromHistory!.image! as Data)
            
            titleLabel.textColor = .tianyiBlue
            authorLabel.textColor = .tianyiBlue
            urlLabel.textColor = .tianyiBlue
            getAd()
        }
    }
    
    @IBAction func downloadButtonTapped(_ sender: UIBarButtonItem) {
        saveImage()
    }
    
    @IBAction func adButtonTapped() {
        let dialog = LLDialog()
        dialog.title = "广告显示设置"
        dialog.message = "屏幕下方的广告是我们维持服务的主要收入来源，但为了方便强迫症，您可以在这里自由选择是否显示广告，不需要额外付费。"
        dialog.setNegativeButton(withTitle: "关闭广告", target: self, action: #selector(disableToShowAd))
        dialog.setPositiveButton(withTitle: "显示广告", target: self, action: #selector(enableToShowAd))
        dialog.show()
    }
    
    @objc fileprivate func disableToShowAd() {
        if dataModel.adPermission {
            view.viewWithTag(10086)?.removeFromSuperview()
            dataModel.adPermission = false
        }
    }
    
    @objc fileprivate func enableToShowAd() {
        if !dataModel.adPermission {
            dataModel.adPermission = true
            getAd()
        }
    }
    
    fileprivate func getAd() {
        let request = GADRequest()
        
        request.testDevices = [ kGADSimulatorID, "d9496780e274c9b1407bdef5d8d5b3d9", "0d27b1f9900926d4c67b23fa32c54bdb", "97da998932e4df7e181e0683b1bd555c" ]
        
        if dataModel.adPermission == nil {
            dataModel.adPermission = true
            adButtonTapped()
        }
        if dataModel.adPermission {
            adBannerView.load(request)
        }
    }
    
    @objc fileprivate func saveImage() {
        UIImageWriteToSavedPhotosAlbum(imageView.image!, self, #selector(imageSavingFinished(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    @objc func imageSavingFinished(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        let dialog = LLDialog()
        if let error = error {
            dialog.title = "啊叻？！"
            dialog.message = "下载出错了Σ( ￣□￣||)"
            dialog.setNegativeButton(withTitle: "好吧")
            dialog.setPositiveButton(withTitle: "再试一次", target: self, action: #selector(saveImage))
            dialog.show()
            print(error)
        } else {
            dialog.title = "保存成功！"
            dialog.message = "封面被成功保存(〜￣△￣)〜"
            dialog.setPositiveButton(withTitle: "OK")
            dialog.show()
        }
    }
    
    fileprivate func enableButtons() {
        downloadButton.isEnabled = true
        pushButton.isEnabled = true
        adButton.isEnabled = true
    }
    
    fileprivate func disableButtons() {
        downloadButton.isEnabled = false
        pushButton.isEnabled = false
        adButton.isEnabled = false
    }
    
    func gotVideoInfo(_ info: Info) {
        titleLabel.text = info.title
        authorLabel.text = "UP主：\(info.author)"
        urlLabel.text = "URL：\(info.imageURL)"
        urlLabel.sizeToFit()
        titleLabel.sizeToFit()
        authorLabel.sizeToFit()
    }
    
    func gotImage(_ image: UIImage) {
        imageView.image = image
        enableButtons()
        loadingView.dismiss()
        getAd()
        addItemToDB()
    }
    
    fileprivate func addItemToDB() {
        dataModel.addNewHistory(av: cover!.shortDescription,
            date: NSDate(),
            image: UIImagePNGRepresentation(imageView.image!)! as NSData,
            title: titleLabel.text!,
            up: authorLabel.text!,
            url: urlLabel.text!)
    }
    
    func connectError() {
        print("Cannot connect\n")
        titleLabel.text = "啊叻？"
        authorLabel.text = "连不上服务器了？"
        urlLabel.text = "提示：如果一直提示这个可能是我们的服(V)务(P)器(S)炸了，你可以去「关于我们」页面找我们反映情况哦~"
        loadingView.dismiss()
        imageView.image = #imageLiteral(resourceName: "error_image")
    }
    
    func cannotFindVideo() {
        titleLabel.text = "啊叻？"
        authorLabel.text = "视频不见了？"
        urlLabel.text = "提示：目前暂时还抓不到「会员的世界」的封面哦(\"▔□▔)/"
        loadingView.dismiss()
        imageView.image = #imageLiteral(resourceName: "novideo_image")
    }
    
    func adViewDidReceiveAd(_ bannerView: GADBannerView) {
        let height = view.bounds.size.height
        let y = height - bannerView.bounds.size.height
        bannerView.frame = CGRect(origin: CGPoint(x: 0, y: y), size: bannerView.bounds.size)
        view.addSubview(bannerView)
        bannerView.tag = 10086
    }
    
    func adView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: GADRequestError) {
        getAd()
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let backItem = UIBarButtonItem()
        backItem.title = ""
        navigationItem.backBarButtonItem = backItem
        
        let vc = segue.destination as! DetailViewController
        vc.image = imageView.image!
    }
    
}
