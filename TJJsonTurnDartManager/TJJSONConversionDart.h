//
//  TJJsonConversionDart.h
//  TJJsonTranConversionDart
//
//  Created by 任春节 on 2021/4/12.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol TJJSONConversionDeleage <NSObject>

@optional
// 是否开启空安全验证
- (BOOL)whetherToEnableAirAecurityAuthentication;

@end
@interface TJJSONConversionDart : NSObject


+ (instancetype)configOutPath:(NSString *)outPath fileName:(NSString *)fileName block:(void(^)(NSString *path,NSString *joiningJson,NSError *error))block;

+ (instancetype)configBlock:(void(^)(NSString *path,NSString *joiningJson,NSError *error))block;

/// json解析
/// @param json 需要解析的数据
/// @param className 类名
- (void)jsonDataToDealWith:(id)json className:(NSString *)className;

/// 更新文件输出路径
/// @param outPath 输出路径
- (void)updateOutPath:(NSString *)outPath;

/// 更新文件名
/// @param fileName 文件名
- (void)updateFileName:(NSString *)fileName;

/// class头更新
/// @param classHeader class头
- (void)updateClassHeader:(NSString *)classHeader;
/// class尾部拼接更新
/// @param end class尾部名字
- (void)updateClassEnd:(NSString *)end;

///
@property (nonatomic,weak) id <TJJSONConversionDeleage> deleage;

@end

NS_ASSUME_NONNULL_END
