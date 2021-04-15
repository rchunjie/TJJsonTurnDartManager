//
//  ViewController.m
//  TJJsonTurnDartManager
//
//  Created by 任春节 on 2021/4/15.
//

#import "ViewController.h"
#import "TJJSONConversionDart.h"
@interface ViewController()
@property (weak) IBOutlet NSTextFieldCell *inputJsonField;

@property (weak) IBOutlet NSTextField *classHeaderField;
@property (weak) IBOutlet NSTextField *classEndFiled;

@property (weak) IBOutlet NSTextField *fileName;
@property (weak) IBOutlet NSButton *outFieldBtn;
@property (weak) IBOutlet NSTextField *outPathField;

@property (weak) IBOutlet NSTextField *tipLabel;

/// 转换模型
@property(nonatomic,strong)TJJSONConversionDart *conversionDart;
@end
@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tipLabel.enabled = YES;
    [self bindingData];
}

- (void)bindingData{
    __weak typeof(self) wself = self;
    [NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskLeftMouseDown|NSEventMaskLeftMouseDragged|NSEventMaskRightMouseDown handler:^NSEvent * _Nullable(NSEvent * _Nonnull event) {
       NSPoint p = [event locationInWindow];
       if (p.x >= wself.tipLabel.frame.origin.x && p.y >= wself.tipLabel.frame.origin.y && p.x <= CGRectGetMaxX(wself.tipLabel.frame) && p.y <= CGRectGetMaxY(wself.tipLabel.frame)) {
           [wself copyTipLabel:wself.tipLabel];
       }
       return event;
   }];
}

- (IBAction)jsonChoiceBtn:(id)sender {
    printf("请选择json文件路径");
    __weak typeof(self) weakSelf = self;
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.canCreateDirectories = NO;
    panel.canChooseDirectories = NO;
    panel.canChooseFiles = YES;
    [panel setAllowsMultipleSelection:NO];
    [panel beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse result) {
        if (result == NSModalResponseOK) {
            weakSelf.inputJsonField.stringValue = [panel.URLs.firstObject path];
        }
    }];
    
}
- (IBAction)outPathButton:(id)sender {
    __weak typeof(self) weakSelf = self;
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.canCreateDirectories = NO;
    panel.canChooseDirectories = YES;
    panel.canChooseFiles = NO;
    [panel setAllowsMultipleSelection:NO];
    [panel beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse result) {
        if (result == NSModalResponseOK) {
            weakSelf.outPathField.stringValue = [panel.URLs.firstObject path];
        }
    }];
}
- (IBAction)jsonOutPathBtn:(id)sender {
    printf("请选择json输出文件路径");
   
}

- (void)_copyTipLabelGestureRecognizer:(id)tap{
    
}

- (IBAction)copyTipLabel:(id)sender {
    NSString *text = @"文件输出路径为:";
    if ([self.tipLabel.stringValue hasPrefix:text]) {
        NSString *path = self.tipLabel.stringValue;
        path = [path substringWithRange:NSMakeRange(text.length, path.length - text.length)];
        NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
        if (![[pasteboard types] containsObject:NSPasteboardTypeString]) {
            [pasteboard addTypes:@[NSPasteboardTypeString] owner:self];
        }
        [pasteboard clearContents];
        BOOL isWrith = [pasteboard writeObjects:@[path]];
        if (isWrith) {
            self.tipLabel.stringValue = @"路径已存入剪切板";
        }
    }
}
- (IBAction)jsonTurnDartBtn:(id)sender {
    printf("开始转换");
    if (!_conversionDart) {
        _conversionDart = [TJJSONConversionDart configOutPath:self.outPathField.stringValue fileName:self.fileName.stringValue block:^(NSString * _Nonnull path, NSString * _Nonnull joiningJson, NSError * _Nonnull error) {
            if (error) {
                NSMutableString *tip = [[NSMutableString alloc] init];
                [error.userInfo enumerateKeysAndObjectsUsingBlock:^(NSErrorUserInfoKey  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                    [tip appendString:key];
                    [tip appendString:[NSString stringWithFormat:@"%@",obj]];
                }];
                self.tipLabel.stringValue = tip;
            }else{
                self.tipLabel.stringValue = [NSString stringWithFormat:@"文件输出路径为:%@",path];
            }
        }];
    }
    [self.conversionDart updateClassEnd:self.classEndFiled.stringValue];
    [self.conversionDart updateOutPath:self.outPathField.stringValue];
    [self.conversionDart updateClassHeader:self.classHeaderField.stringValue];
    [self.conversionDart updateFileName:self.fileName.stringValue];
    
    NSError *error =nil;
    NSData *jsonData = [NSData dataWithContentsOfFile:self.inputJsonField.stringValue options:NSDataReadingMappedIfSafe error:&error];
    if (error) {
        [self.tipLabel setStringValue:@"json解析出错"];
        return;
    }
    
    NSString *json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    [self.conversionDart jsonDataToDealWith:json className:self.fileName.stringValue];
    
}



- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}


@end
