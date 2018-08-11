//
//  UIViewController+ActionSheet.m
//  NAT-iOS
//
//  Created by simpzan on 24/03/2018.
//  Copyright © 2018 simpzan. All rights reserved.
//

#import "UIViewController+ActionSheet.h"

@implementation UIViewController (ActionSheet)

- (void)select:(NSArray *)actions title:(NSString *)title :(ActionSheetCallback)callback {
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    int index = 0;
    for (NSString *action in actions) {
        UIAlertAction *button = [UIAlertAction actionWithTitle:action style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            callback(index);
        }];
        [alert addAction:button];
        ++index;
    }
    UIAlertAction *cancelButton = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        callback(-1);
    }];
    [alert addAction:cancelButton];
    if (alert.popoverPresentationController) alert.popoverPresentationController.sourceView = self.view;
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)getTextInputWithTitle:(NSString *)title :(TextInputDialogCallback)callback {
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
    }];
    UIAlertAction *button = [UIAlertAction actionWithTitle:@"OK"
            style:UIAlertActionStyleDefault
            handler:^(UIAlertAction * _Nonnull action) {
        NSString *text = alert.textFields.firstObject.text;
        text = text ? text : @"";
        callback(text);
    }];
    [alert addAction:button];
    UIAlertAction *cancelButton = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        callback(NULL);
    }];
    [alert addAction:cancelButton];
    if (alert.popoverPresentationController) alert.popoverPresentationController.sourceView = self.view;
    [self presentViewController:alert animated:YES completion:nil];
}

@end
