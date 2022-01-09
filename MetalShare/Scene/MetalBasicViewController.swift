//
//  MetalBasicViewController.swift
//  MetalShare
//
//  Created by shaoqianming on 2021/6/18.
//

import UIKit

class MetalBasicViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    public var enterFrom: String?
    
    // common
    var renderView: RenderView!
    var pictureInput: PictureInput!
    
    // color adjust
    var sliderBrightness: UISlider!
    var sliderSaturation: UISlider!
    var sliderGaussianBlur: UISlider!
    
    var saturationFilter: SaturationFilter!
    var brightnessFilter: BrightnessFilter!
    var gaussianBlurFilter: GaussianBlurFilter!
    
    // lookup
    var lookupFilter: LookupFilter!

    // blend mode
    var pickerView: UIPickerView!
    var label: UILabel!
    let factorNames: [String]! = ["zero","one","sourceColor","oneMinusSourceColor","sourceAlpha","oneMinusSourceAlpha","destinationColor","oneMinusDestinationColor","destinationAlpha","oneMinusDestinationAlpha","sourceAlphaSaturated","blendColor","oneMinusBlendColor","blendAlpha","oneMinusBlendAlpha","source1Color","oneMinusSource1Color","source1Alpha","oneMinusSource1Alpha"]
    
    let operationNames: [String]! = ["add","subtract","reverseSubtract","min","max"]
    var currentSourceFactor: MTLBlendFactor = .one
    var currentOperation: MTLBlendOperation = .add
    var currentDesFactor: MTLBlendFactor = .zero
    private var sourcePictureInput: PictureInput!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        switch enterFrom {
        case "Triangle":
            let metalView = KiraMetalView(frame: self.view.frame)
            metalView.setup(verticesCount: 3, image: nil)
            view.addSubview(metalView)
        case "Texture":
            let metalView = KiraMetalView(frame: self.view.frame)
            metalView.setup(verticesCount: 4, image:UIImage.init(named: "jienijieni.png"))
            view.addSubview(metalView)
        case "LookupFilter":
            setupLookupScene()
        case "BlendMode":
            setupBlendModeScene()
        case "Adjust":
            setupAdjustScene()
        case "GaussianBlur":
            setupGaussianBlurScene()
        case "Matting":
            setupMattingScene()
        default:
            return
        }
    }
    
    
    //MARK:- Matting
    func setupMattingScene() {
        let mattingView = MattingView(frame: self.view.bounds)
        self.view.addSubview(mattingView)
        
        let matService = MattingSerive()
        let origin = UIImage(named:"person5.jpg")!
        let maskImg = matService.handleImageV2(image: origin)
        var maskImg2:UIImage = UIImage(ciImage: maskImg!)
        
        maskImg2 = maskImg2.reSizeImage(reSize: CGSize(width: (origin.size.width/2), height: (origin.size.height/2)))
        
//        let imageView = UIImageView(image: maskImg2)
//        imageView.contentMode = .scaleAspectFit
//        imageView.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: self.view.bounds.size.width, height: self.view.bounds.size.height))
//        mattingView.addSubview(imageView)
        
        
        renderView = RenderView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: self.view.bounds.size.width, height: self.view.bounds.size.height)))
        mattingView.addSubview(renderView)

        pictureInput = PictureInput(image: UIImage(named: "person5.jpg")!)
        let filter = SegmentFilter()
        filter.alpha = 1.0
        filter.maskImage = PictureInput(image: maskImg2)
        filter.materialImage = PictureInput(image: UIImage(named: "bg1.jpeg")!)

        pictureInput --> filter --> renderView
        pictureInput.processImage()
    }
    
    //MARK:- GaussionBlur Filter
    func setupGaussianBlurScene() {
        let frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 400)
        renderView = RenderView(frame: frame)
        view.addSubview(renderView)
        
        let slider = createSlider(name: "offset", originY: 400, min: 0, max: 1, defaultValue: 0.01)
        slider.addTarget(self, action: #selector(adjustGaussianBlur), for: UIControl.Event.valueChanged)
        self.sliderGaussianBlur = slider
        pictureInput = PictureInput(image: UIImage(named:"iu.jpeg")!)
        
        self.gaussianBlurFilter = GaussianBlurFilter.init()
        self.gaussianBlurFilter.blur = 0.01
        
        pictureInput --> self.gaussianBlurFilter --> renderView
        pictureInput.processImage()
    }
    
    @objc func adjustGaussianBlur() {
        self.gaussianBlurFilter.blur = sliderGaussianBlur.value
        pictureInput.processImage()
        print("gaussian blur offset value:%f",sliderGaussianBlur.value)
    }
    
    // MARK:- Adjust Filter
    
    func setupAdjustScene() {
        let frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 400)
        renderView = RenderView(frame: frame)
        view.addSubview(renderView)
        
        let slider1 = createSlider(name: "饱和度", originY: 400, min: 0, max: 2, defaultValue: 1.0)
        let slider2 = createSlider(name: "亮度", originY: slider1.frame.origin.y + 60, min: -1, max: 1, defaultValue: 0.0)
        slider1.addTarget(self, action: #selector(adjustSaturation), for: UIControl.Event.valueChanged)
        slider2.addTarget(self, action: #selector(adjustBrightness), for: UIControl.Event.valueChanged)
        
        self.sliderSaturation = slider1
        self.sliderBrightness = slider2

        pictureInput = PictureInput(image:UIImage(named:"test.jpeg")!)
        
        self.saturationFilter = SaturationFilter.init()
        self.saturationFilter.saturation = 1.0
        
        self.brightnessFilter = BrightnessFilter.init()
        self.brightnessFilter.brightness = 0;
        
        pictureInput  --> self.saturationFilter --> renderView
        pictureInput.processImage()
    }
    
    
    func createSlider(name: String, originY: CGFloat, min: Float, max: Float, defaultValue: Float) -> UISlider {
        let label = UILabel(frame: CGRect(origin: CGPoint(x: 0, y: originY), size: CGSize(width: 100, height: 50)))
        label.text = name
        label.textColor = UIColor.darkGray
        label.textAlignment = NSTextAlignment.center
        label.font = UIFont.systemFont(ofSize: 18)
        
        let slider = UISlider(frame: CGRect(x: label.frame.size.width + 10, y: originY, width: UIScreen.main.bounds.size.width - label.frame.size.width - 10, height: 50));
        
        slider.minimumValue = min
        slider.maximumValue = max
        slider.value = defaultValue
        
        self.view.addSubview(label)
        self.view.addSubview(slider)
        
        return slider
    }
    
    @objc func adjustBrightness() {
        self.brightnessFilter.brightness = sliderBrightness.value
        pictureInput.processImage()
        print("bright value:%f",sliderBrightness.value)
    }
    
    @objc func adjustSaturation() {
        self.saturationFilter.saturation = sliderSaturation.value
        pictureInput.processImage()
        print("saturation value:%f",sliderSaturation.value)
    }
    
    // MARK:- Lookup Filter
    func setupLookupScene() {
        renderView = RenderView(frame: self.view.frame)
        view.addSubview(renderView)
        
        pictureInput = PictureInput(image:UIImage(named:"test.jpeg")!)
        lookupFilter = LookupFilter.init()
        lookupFilter.lookupImage = PictureInput(image:UIImage(named:"sunset.png")!)
        lookupFilter.intensity = 1
        
        pictureInput --> lookupFilter --> renderView
        pictureInput.processImage()
    }
    
    // MARK:- Blend Mode
    func setupBlendModeScene() {
        renderView = RenderView(frame: self.view.frame)
        renderView.fillMode = .preserveAspectRatioAndFill
        view.addSubview(renderView)
        
        setupPickerView()
        
        pictureInput = PictureInput(image: UIImage(named: "blend1.png")!)
        pictureInput.fillMode = .preserveAspectRatioAndFill
        pictureInput --> renderView
        
        guard let image = changeImageByApplyingAlpha(alpha: 0.5, image: UIImage(named: "blend2.png")!) else {
            fatalError("image cant be nil")
        }
        
        sourcePictureInput = PictureInput(image:image)
        regenerateBackupPipelineState()
        sourcePictureInput.fillMode = .preserveAspectRatio
        sourcePictureInput --> renderView
        renderView.processPictureSources()
    }
    
    func regenerateBackupPipelineState(){
        sourcePictureInput.generateBackupPipelineState { (pipelineDescriptor) in
            pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true;
            pipelineDescriptor.colorAttachments[0].rgbBlendOperation = self.currentOperation;
            pipelineDescriptor.colorAttachments[0].alphaBlendOperation = self.currentOperation;
            pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = self.currentSourceFactor;
            pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = self.currentSourceFactor;
            pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = self.currentDesFactor;
            pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = self.currentDesFactor;
        }
    }
    func setupPickerView() {
        pickerView = UIPickerView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 300))
        pickerView.dataSource = self
        pickerView.delegate = self
        pickerView.isHidden = true
        self.view.addSubview(pickerView)
        
        pickerView.selectRow(Int(currentSourceFactor.rawValue), inComponent: 0, animated: true)
        pickerView.selectRow(Int(currentOperation.rawValue), inComponent: 1, animated: true)
        pickerView.selectRow(Int(currentDesFactor.rawValue), inComponent: 2, animated: true)

        let button = UIButton(frame:CGRect(x:8, y:8, width:200, height:50))
        button.setTitle("切换 blendMode",for:.normal)
        button.setTitle("关闭选择", for: .selected)
        button.setTitleColor(.black, for:.normal)
        button.titleLabel?.textAlignment = .left
        button.addTarget(self, action:#selector(getPickerViewValue(button:)),
                         for: .touchUpInside)
        self.view.addSubview(button)
        
        label = UILabel(frame: CGRect(x: 0, y: UIScreen.main.bounds.height - 280, width: UIScreen.main.bounds.width, height: 100))
        label.textColor = .red
        label.numberOfLines = 4
        label.font = .systemFont(ofSize: 20)
        label.text = refreshLabel()
        self.view.addSubview(label)
    }
    
    func refreshLabel() -> String! {
        return "当前选择\n Source: \(factorNames[Int(currentSourceFactor.rawValue)])\n \(operationNames[Int(currentOperation.rawValue)])\n Destination:  \(factorNames[Int(currentDesFactor.rawValue)])"
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 3
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if component == 0 || component == 2 {
            return factorNames.count
        }
        if component == 1 {
            return operationNames.count
        }
        return 0
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int,
                    forComponent component: Int) -> String? {
        if component == 0 || component == 2 {
            let name = factorNames[row]
            return name
        }
        if component == 1 {
            let name = operationNames[row]
            return name
        }
        return "overflow"
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int,
                    inComponent component: Int) {
        if component == 0 {
            if row >= 15 {
                //后面的几种感觉有问题，crash
                return
            }
            currentSourceFactor = MTLBlendFactor.init(rawValue: UInt(row))!
        }
        if component == 1 {
            currentOperation = MTLBlendOperation.init(rawValue: UInt(row))!
        }
        if component == 2 {
            if row >= 15 {
                //后面的几种感觉有问题，crash
                return
            }
            currentDesFactor = MTLBlendFactor.init(rawValue: UInt(row))!
        }
        label.text = refreshLabel()
        regenerateBackupPipelineState()
        renderView.processPictureSources()
    }
    
    @objc func getPickerViewValue(button: UIButton) {
        button.isSelected = !button.isSelected
        pickerView.isHidden = !button.isSelected
    }
    
    func changeImageByApplyingAlpha(alpha: CGFloat, image: UIImage) -> UIImage? {
        UIGraphicsBeginImageContext(image.size)
        let ctx = UIGraphicsGetCurrentContext()
        let area = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
        ctx?.scaleBy(x: 1, y: -1)
        ctx?.translateBy(x: 0, y: -area.size.height)
        ctx?.setBlendMode(.multiply)
        ctx?.setAlpha(alpha)
        ctx?.draw(image.cgImage!, in: area)
        let res = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return res
    }
}
