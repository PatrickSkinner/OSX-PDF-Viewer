//
//  AppDelegate.swift
//  OSX-PDF-Viewer
//
//  Created by Patrick Skinner 💯 on 9/27/16.
//  Copyright © 2016 Patrick Skinner. All rights reserved.
//

import Cocoa
import Quartz

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    @IBOutlet weak var startWindow: NSWindow!
    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var ourPDF: PDFView!
    @IBOutlet weak var thumbs: PDFThumbnailView!
    @IBOutlet weak var pageNum: NSTextField!
    @IBOutlet weak var pdfSelector: NSPopUpButton!
    @IBOutlet weak var textField: NSTextField!
    @IBOutlet weak var bookmarkSelector: NSPopUpButton!
    @IBOutlet weak var saveBookmark: NSButton!
    @IBOutlet weak var bookmarkTitle: NSTextField!
    
    @IBOutlet weak var startOpenDocument: NSButton!
    @IBOutlet weak var startPopUp: NSPopUpButton!
    
    
    var pdf: PDFDocument!
    
    var searchValue: Int = 0
    
    var selection: [AnyObject] = [AnyObject]()
    
    var urls: [NSURL] = [NSURL]()
    
    var notes = [String: String]()
    var bookmarks = [String: [String]]()
    var recentDocuments = [String]()
    
    
    //////////////////////////////////
    //          StartWindow         //
    //////////////////////////////////
    @IBAction func openRecent(sender: AnyObject) {
        let list: NSPopUpButton = sender as! NSPopUpButton
        
        if (list.titleOfSelectedItem != "Recent Documents"){
            openByIndex(list.indexOfSelectedItem + 1, recentflag: true)
        
            self.window.setIsVisible(true)
            self.startWindow.setIsVisible(false)
        
            self.ourPDF.setDocument(self.pdf)
            self.ourPDF.setAutoScales(true)
        
            var thumbSize: NSSize = NSSize()
            thumbSize.width = 120
            thumbSize.height = 200
            self.thumbs.setThumbnailSize(thumbSize)
            self.thumbs.setPDFView(self.ourPDF)

        
            self.bookmarkSelector.removeAllItems()
            self.bookmarkSelector.addItemWithTitle("Select Bookmark")
        
            for (key, array) in self.bookmarks {
                if(array[1] == pdf.documentURL().absoluteString){
                    self.bookmarkSelector.addItemWithTitle(key)
                }
            }
        
            self.ourPDF.layoutDocumentView()
            self.pdfSelector.selectItemAtIndex(0)
            self.notePageUpdated()
            
        }

    }
    
    
    @IBAction func Open(sender: AnyObject) {
        
        let defaults = NSUserDefaults.standardUserDefaults()
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = true
        openPanel.canChooseDirectories = false
        openPanel.canCreateDirectories = false
        openPanel.canChooseFiles = true
        openPanel.allowedFileTypes = ["pdf"]
        openPanel.beginWithCompletionHandler { (result) -> Void in
            if result == NSFileHandlingPanelOKButton {
                for url in openPanel.URLs{
                    self.urls.append(url)
                    if (self.recentDocuments.count < 6){
                        self.recentDocuments.append(url.absoluteString)
                        
                        defaults.setObject(self.recentDocuments, forKey: "recentDictionaryKey")
                    } else {
                        for item in self.recentDocuments{
                            if (self.recentDocuments.indexOf(item) > 0){
                                self.recentDocuments[self.recentDocuments.indexOf(item)! - 1] = item
                            }
                        }
                        self.recentDocuments.insert(url.absoluteString, atIndex: self.recentDocuments.count)
                        defaults.setObject(self.recentDocuments, forKey: "recentDictionaryKey")
                    }
                    
                }
                
                
                self.pdf = PDFDocument(URL: self.urls[self.urls.endIndex-1])
                self.ourPDF.setDocument(self.pdf)
                self.ourPDF.setAutoScales(true)
                
                var thumbSize: NSSize = NSSize()
                thumbSize.width = 120
                thumbSize.height = 200
                self.thumbs.setThumbnailSize(thumbSize)
                self.thumbs.setPDFView(self.ourPDF)
                
                let dict: NSDictionary = self.pdf.documentAttributes()
                if(dict["PDFDocumentTitleAttribute"] != nil){
                    self.window.title = dict["PDFDocumentTitleAttribute"] as! String
                } else if(self.urls[self.urls.endIndex-1].lastPathComponent != nil){
                    self.window.title = self.urls[self.urls.endIndex-1].lastPathComponent!
                }
                
                for document in self.urls{
                    self.pdfSelector.addItemWithTitle(document.lastPathComponent!)
                }
                self.pdfSelector.selectItemAtIndex(self.urls.endIndex-1)
                
                self.bookmarkSelector.removeAllItems()
                self.bookmarkSelector.addItemWithTitle("Select Bookmark")
                
                for (key, array) in self.bookmarks {
                    if(array[1] == self.pdf.documentURL().absoluteString){
                        self.bookmarkSelector.addItemWithTitle(array[2])
                    }
                }
                
                self.ourPDF.layoutDocumentView()
                
                self.notePageUpdated()
                
                self.window.setIsVisible(true)
                self.startWindow.setIsVisible(false)
                
            }
            
        }
        
    }

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        
        window.contentMinSize = NSSize(width: 700, height: 700)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(updatePageNum), name: PDFViewPageChangedNotification, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(noteUpdated), name: NSTextDidChangeNotification, object: nil)
        
        let defaults = NSUserDefaults.standardUserDefaults()
        if let noteDictionary = defaults.dictionaryForKey("noteDictionaryKey"){
            notes = noteDictionary as! [String: String]
        }
        
        if let bookmarkDictionary = defaults.dictionaryForKey("bookmarkDictionaryKey"){
            bookmarks = bookmarkDictionary as! [String: [String]]
        }
        
        if let recentDictionary = defaults.arrayForKey("recentDictionaryKey"){
            recentDocuments = recentDictionary as! [String]
        }
        
        self.startPopUp.removeAllItems()
        self.bookmarkSelector.removeAllItems()
        self.pdfSelector.removeAllItems()
        
        self.bookmarkSelector.addItemWithTitle("Select Bookmark")
        self.startPopUp.addItemWithTitle("Recent Documents")
        
        for item in self.recentDocuments{
            self.startPopUp.addItemWithTitle((NSURL(fileURLWithPath: item).URLByDeletingPathExtension?.lastPathComponent)!)
        }
        
        // DEBUG LINE CLEAR RECENT 
        
        //defaults.setObject([String](), forKey: "recentDictionaryKey")
        
        
    }

    func applicationWillTerminate(aNotification: NSNotification) {
    }
    
    
    //////////////////////////////////
    //        Zoom Functions        //
    //////////////////////////////////

    @IBAction func zoomIn(sender: AnyObject) {
        ourPDF.setAutoScales(false)
        ourPDF.zoomIn(sender)
    }
    
    @IBAction func zoomOut(sender: AnyObject) {
        ourPDF.setAutoScales(false)
        ourPDF.zoomOut(sender)
    }
    
    @IBAction func scale(sender: AnyObject) {
        ourPDF.setAutoScales(true)
    }
    
    //////////////////////////////////
    //        Page Navigation       //
    //////////////////////////////////
    
    @IBAction func previousPage(sender: AnyObject){
        if (ourPDF.canGoToPreviousPage()){
            ourPDF.goToPreviousPage(sender)
        }
    }
    
    @IBAction func nextPage(sender: AnyObject){
        if (ourPDF.canGoToNextPage()){
            ourPDF.goToNextPage(sender)
        }
    }
    
    @IBAction func jumpToPage(sender: AnyObject){
        if(Int(pageNum.stringValue) != nil && ourPDF != nil){
            ourPDF.goToPage(pdf.pageAtIndex(Int(pageNum.stringValue)!-1))
        }
    }
    
    func updatePageNum(){
        pageNum.stringValue = ourPDF.currentPage().label()
        notePageUpdated()
    }
    
    //////////////////////////////////
    //      Searching Functions     //
    //////////////////////////////////
    
    @IBAction func search(sender: AnyObject){
        if(ourPDF != nil && pdf != nil){
            let searchString = sender.stringValue()
            if(!searchString.isEmpty){
                selection = pdf.findString(searchString!, withOptions: 1)
        
                if (!selection.isEmpty) {
                    ourPDF.goToSelection(selection[searchValue] as! PDFSelection )
        
                    for item in selection {
                        item.setColor(NSColor(red: 0, green: 0, blue: 0.6, alpha: 0.6))
                    }
                    selection[searchValue].setColor(NSColor(red: 0.6, green: 0, blue: 0, alpha: 0.6))
                    ourPDF.setHighlightedSelections(selection)
                }
            } else {
                selection.removeAll()
                ourPDF.setHighlightedSelections(nil)
            }
        }
    }
    
    @IBAction func searchBack(sender: AnyObject){
        if(searchValue != 0){
            if (!selection.isEmpty){
                selection[searchValue].setColor(NSColor(red: 0, green: 0, blue: 0.6, alpha: 0.6))
            
                searchValue -= 1
            
                goToSelection()
            }
        } else {
            if (!selection.isEmpty){
                selection[searchValue].setColor(NSColor(red: 0, green: 0, blue: 0.6, alpha: 0.6))
            
                searchValue = selection.count - 1
            
                goToSelection()
            }
        }
    }
    
    @IBAction func searchforward(sender: AnyObject){
        if(searchValue == (selection.count - 1)){
            if (!selection.isEmpty){
                selection[searchValue].setColor(NSColor(red: 0, green: 0, blue: 0.6, alpha: 0.6))
            
                searchValue = 0
            
                goToSelection()
            }
        } else {
            if (!selection.isEmpty){
                selection[searchValue].setColor(NSColor(red: 0, green: 0, blue: 0.6, alpha: 0.6))
            
                searchValue += 1
            
                goToSelection()
            }
        }
    }
    
    func goToSelection(){
        ourPDF.goToSelection(selection[searchValue] as! PDFSelection )
        
        selection[searchValue].setColor(NSColor(red: 0.6, green: 0, blue: 0, alpha: 0.6))
        ourPDF.setHighlightedSelections(selection)
    }
    
    //////////////////////////////////
    // Document Selection Functions //
    //////////////////////////////////
    
    @IBAction func selectPDF(sender: AnyObject) {
        let list: NSPopUpButton = sender as! NSPopUpButton
        
        openByIndex(list.indexOfSelectedItem, recentflag: false)
        
        self.bookmarkSelector.removeAllItems()
        self.bookmarkSelector.addItemWithTitle("Select Bookmark")
        
        for (key, array) in self.bookmarks {
            if(array[1] == pdf.documentURL().absoluteString){
                self.bookmarkSelector.addItemWithTitle(key)
            }
        }
        
    }
    
    @IBAction func goBackDocument(sender: AnyObject){
        if(ourPDF != nil && urls.count > 1){
            var index = urls.indexOf(pdf.documentURL())
            
            if(index == 0){
                index = urls.count - 1
            } else {
                index = index! - 1
            }
            
            openByIndex(index!, recentflag: false)
        }
    }
    
    @IBAction func goForwardDocument(sender: AnyObject){
        if(ourPDF != nil && urls.count > 1){
            var index = urls.indexOf(pdf.documentURL())
            
            if(index == urls.count - 1){
                index = 0
            } else {
                index = index! + 1
            }
            
            openByIndex(index!, recentflag: false)

        }
    }
    
    func openByIndex(index: Int, recentflag: Bool){
        if(recentflag){
            urls.append(NSURL(string: recentDocuments[index-2])!)
            self.pdf = PDFDocument(URL: NSURL(string: recentDocuments[index-2]))
            
            self.ourPDF.setDocument(self.pdf)
            
            let dict: NSDictionary = self.pdf.documentAttributes()
            if(dict["PDFDocumentTitleAttribute"] != nil){
                self.window.title = dict["PDFDocumentTitleAttribute"] as! String
            } else if(NSURL(fileURLWithPath: recentDocuments[index-2]).lastPathComponent != nil){
                self.window.title = NSURL(fileURLWithPath: recentDocuments[index-2]).lastPathComponent!
            }
            
            self.pdfSelector.addItemWithTitle(self.pdf.documentURL().lastPathComponent!)
            self.pdfSelector.selectItemAtIndex(0)
        } else {
            self.pdf = PDFDocument(URL: urls[index])
            
            self.ourPDF.setDocument(self.pdf)
            
            let dict: NSDictionary = self.pdf.documentAttributes()
            if(dict["PDFDocumentTitleAttribute"] != nil){
                self.window.title = dict["PDFDocumentTitleAttribute"] as! String
            } else if(self.urls[index].lastPathComponent != nil){
                self.window.title = self.urls[index].lastPathComponent!
            }
            
            pdfSelector.selectItemAtIndex(index)
        }
        
        updatePageNum()
        notePageUpdated()
        
        self.bookmarkSelector.removeAllItems()
        self.bookmarkSelector.addItemWithTitle("Select Bookmark")
        
        for (key, array) in self.bookmarks {
            if(array[1] == pdf.documentURL().absoluteString){
                self.bookmarkSelector.addItemWithTitle(key)
            }
        }
    }
    

    
    //////////////////////////////////
    //     Note Taking Functions    //
    //////////////////////////////////
    
    func noteUpdated(){
        if(pdf != nil){
            let noteKey = ourPDF.currentPage().label() + (pdf!.documentURL().URLByDeletingPathExtension?.lastPathComponent)!
            notes[noteKey] = textField.stringValue
        }
        
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject(notes, forKey: "noteDictionaryKey")
    }
    
    func notePageUpdated(){
        let noteKey = ourPDF.currentPage().label() + (pdf!.documentURL().URLByDeletingPathExtension?.lastPathComponent)!
        if(notes[noteKey] == nil){
            textField.stringValue = ""
        } else {
            textField.stringValue = notes[noteKey]!
        }
    }
    
    //////////////////////////////////
    //      Bookmark Functions      //
    //////////////////////////////////

    @IBAction func bookmarkSave(sender: AnyObject) {
        if(pdf != nil){
            let docUrl = (pdf!.documentURL().absoluteString)
            if (bookmarkTitle.stringValue != ""){
                bookmarks[bookmarkTitle.stringValue] = [ourPDF.currentPage().label(), docUrl, bookmarkTitle.stringValue]
                bookmarkSelector.addItemWithTitle(bookmarkTitle.stringValue)
                bookmarkTitle.stringValue = ""
                let defaults = NSUserDefaults.standardUserDefaults()
                defaults.setObject(bookmarks, forKey: "bookmarkDictionaryKey")
            }
            
        }
    }
    

    @IBAction func bookmarkSelect(sender: AnyObject) {
        let list: NSPopUpButton = sender as! NSPopUpButton
        
        if (list.titleOfSelectedItem != "Select Bookmark"){
            let bookmarkname = list.titleOfSelectedItem
            var pageString = bookmarks[bookmarkname!]
        
            let pageNum = Int(pageString![0])
        
        
            ourPDF.goToPage(pdf.pageAtIndex(pageNum! - 1))
        }

    }
    
    

}

